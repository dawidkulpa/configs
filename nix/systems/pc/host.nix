{pkgs, ...}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../../shared/host.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "nixosPC";
    networkmanager.enable = true;
    wireless.enable = false;
  };

  time.timeZone = "Europe/Warsaw";

  i18n.defaultLocale = "en_GB.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pl_PL.UTF-8";
    LC_IDENTIFICATION = "pl_PL.UTF-8";
    LC_MEASUREMENT = "pl_PL.UTF-8";
    LC_MONETARY = "pl_PL.UTF-8";
    LC_NAME = "pl_PL.UTF-8";
    LC_NUMERIC = "pl_PL.UTF-8";
    LC_PAPER = "pl_PL.UTF-8";
    LC_TELEPHONE = "pl_PL.UTF-8";
    LC_TIME = "pl_PL.UTF-8";
  };

  services = {
    xserver = {
      enable = true;
      layout = "pl";
      xkbVariant = "";
      displayManager = {
        gdm.enable = true;
        gnome.enable = true;
        autoLogin.enable = true;
        autoLogin.user = "buggy";
      };
    };

    printing.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };

  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  console.keyMap = "pl2";

  sound.enable = true;
  hardware.pulseaudio.enable = true;

  users.users.buggy = {
    description = "Buggy";
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager"];
    # hashedPassword = "";
    shell = pkgs.fish;
  };

  # users.mutableUsers = false;

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "23.11";
}
