{
  pkgs,
  config,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../../shared/host.nix
    ../../local/local.nix
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

  services.logrotate = {
    settings = {
      "/mnt/nfs/traefik-edge/etc/acces*.log" = {
        compress = true;
        su = "docker-nfs docker-nfs";
        size = "5M";
        frequency = "hourly";
        rotate = 20;
        postrotate = ''
          $(which docker) service update --force $(docker service ls --filter name=traefik_edge --format "{{.ID}}")
        '';
        sharedscripts = true;
      };

      "/mnt/nfs/traefik/etc/acces*.log" = {
        compress = true;
        su = "docker-nfs docker-nfs";
        size = "5M";
        frequency = "hourly";
        rotate = 20;
        postrotate = ''
          $(which docker) service update --force $(docker service ls --filter name=traefik_github --format "{{.ID}}")
        '';
        sharedscripts = true;
      };
    };
  };

  system.stateVersion = "24.05";
}
