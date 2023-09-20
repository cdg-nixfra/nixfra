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

  users.users.cees = {
    isNormalUser = true;
    description = "Cees de Groot";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC3ezI+JP1lrdI6FYd1ynnCPv/IZS4wrxZXnXGpMBvJIZ5fvtHC/8pnHkZiFR64IZvd0Irrh+aJ79ahLa2EToqq9pLVmWx8vIGPZzpE6d/buBg1qjlzKn8iWjlJc938WlvqiqCkcMjLKKkfBmMDg2pUFxPE5QPxAHcaszxxEO59/l9C7tOpqDeX7CozlYoUtIVCvOLLgMPIbRTjPbJ6Qax8bmqoB5/F5Arm7GGckgJ9kQblBncy1sCsykQtvos7MbBbsPmjGEBvGEbvyxORlMBLFMyhEnUt+fVipOyFqiMv6LgVA7l73cOmGMOeWX5/PwxmNxUNAjhAy/1t1koxnZ3GT+IvKQSq3v3B14ZJTHCpsiQMRoz/fpj8BBY4tv8eTfzGljlJGEOV2Q/ju1ewBtFsSDugXylqfj2DQjt7PrFDH1t4l/sxt5IhicQr6Ljg/e9egcXTEcI8DRETnIf1963e8HyLccNGO1ZSMD5CRUa3R2ih74yjyGDCRpmwAJJ9IvE= cees@system76-pc"
    ];
    packages = with pkgs; [
    ];
  };

  # TODO we need to look at this.
  security.sudo.wheelNeedsPassword = false;

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    # super bare essentials, don't touch!
    vim
    wget
  ];

  services.openssh.enable = true;
  networking.firewall.allowedTCPPorts = [
    22
  ];

  nixpkgs.config.amazon-init.enable = false; # Make sure we only run on first boot

  system.stateVersion = "23.05"; # Did you read the comment?
}
