{
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../../shared/host.nix
    ../../local/local.nix
    ../../programs/bitdefender.nix
  ];

  # Bootloader.
  boot.loader.grub.enable = true;

  networking = {
    # hostName = "nixos";
    networkmanager.enable = true;
    wireless.enable = false;
  };

  services.openssh.enable = true;

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

  console.keyMap = "pl2";

  users.users.buggy = {
    description = "Buggy";
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager" "docker"];
    shell = pkgs.fish;
  };

  users.groups.docker-nfs = {
    gid = 3004;
  };

  users.users.docker-nfs = {
    createHome = false;
    group = "docker-nfs";
    uid = 3004;
    isSystemUser = true;
  };

  powerManagement.enable = true;
  powerManagement.cpuFreqGovernor = "powersave";
  powerManagement.powertop.enable = true;

  my.programs.dockerServer.enable = true;
  my.programs.bitdefender.enable = true;

  # users.mutableUsers = false;

  fileSystems."/mnt/nfs/traefik-edge" = {
    device = "nas.home:/mnt/nvme/docker-volumes/traefik-edge";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/traefik" = {
    device = "nas.home:/mnt/nvme/docker-volumes/traefik";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/pterodactyl-panel" = {
    device = "nas.home:/mnt/nvme/docker-volumes/pterodactyl-panel";
    fsType = "nfs4";
    options = ["rw"];
  };

  users.groups.systemd-journal-upload = {};
  users.users.systemd-journal-upload = {
    isSystemUser = true;
    group = "systemd-journal-upload";
  };

  services.journald = {
    upload = {
      enable = true;
      settings = {
        Upload = {
          URL = "http://victorialogs.home.dkulpa.eu:80/insert/journald";
        };
      };
    };
  };

  systemd.services."systemd-journal-upload" = {
    serviceConfig = {
      Restart = lib.mkForce "always";
      RestartSec = lib.mkForce "5s";
    };

    unitConfig = {
      StartLimitBurst = lib.mkForce 0;
      StartLimitIntervalSec = lib.mkForce 0;
    };
  };

  system.stateVersion = "24.11";
}
