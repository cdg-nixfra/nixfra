### https://nixos.org/channels/nixos-23.05 nixos

{ config, pkgs, ... }:

with pkgs;

{
  imports = [
    <nixpkgs/nixos/modules/virtualisation/amazon-image.nix>
  ];
  ec2.hvm = true;

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  swapDevices = [{
    device = "/swapfile";
    size = (1024 * 2);
  }];


  networking.domain = "ca-central-1.the-infra.net";
  time.timeZone = "Etc/UTC";
  i18n.defaultLocale = "en_CA.UTF-8";

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    # super bare essentials, don't touch!
    vim
    jq
    wget
    terraform
    github-cli
    awscli2
  ];

  services.openssh = {
    enable = true;
    # hostKeys = [];
  };
  networking.firewall.allowedTCPPorts = [
    22
  ];
  nix.sshServe.enable = true;
  nix.sshServe.keys = [ "{{ ssh_serve_key }}" ];


  environment.etc =  {
    gh_runner_token.text = "{{ gh_runner_token }}";
    "ssh/ssh_host_rsa_key".text = ''
{{ host_rsa_key }}
'';
  };
  services.github-runner = {
    enable = true;
    url = "https://github.com/cdg-nixfra";
    tokenFile = "/etc/gh_runner_token";
  };
  # Github Runner needs this :(
  nixpkgs.config.permittedInsecurePackages = [ "nodejs-16.20.2" ];

  virtualisation.amazon-init.enable = false; # Make sure we only run on first boot

  system.stateVersion = "23.05"; # Did you read the comment?
}
