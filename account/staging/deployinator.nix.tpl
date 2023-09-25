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

  services.openssh.enable = true;
  programs.ssh = {
    knownHostsFiles = [
      (writeText "builder.keys" ''
        builder.infra.nixfra.ca {{ builder_rsa_host_key }}
        builder.infra.nixfra.ca {{ builder_ed25519_host_key }}
      '')
    ];
  };
  networking.firewall.allowedTCPPorts = [
    22
  ];

  virtualisation.amazon-init.enable = false; # Make sure we only run on first boot

  system.stateVersion = "23.05"; # Did you read the comment?
}
