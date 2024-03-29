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

  time.timeZone = "Etc/UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim
    wget
    github-cli
  ];

  services.openssh = {
    enable = true;
    hostKeys = [];
  };
  networking.firewall.allowedTCPPorts = [
    22
  ];

  environment.etc =  {
    gh_runner_token.text = "{{ gh_runner_token }}";
  };
  services.github-runner = {
    enable = true;
    url = "https://github.com/cdg-nixfra";
    tokenFile = "/etc/gh_runner_token";
  };
  # Github Runner needs this :(
  nixpkgs.config.permittedInsecurePackages = [ "nodejs-16.20.2" ];

  nix.sshServe.enable = true;
  nix.sshServe.keys = [ "{{ builder_client_key }}" ];
  nix.settings.secret-key-files = [ "/etc/nix/signing_key"];

  virtualisation.amazon-init.enable = false; # Make sure we only run on first boot

  system.stateVersion = "23.05"; # Did you read the comment?
}
