{
  pkgs,
  config,
  lib,
  ...
}: {
  imports = [
    ../../shared/host.nix
  ];

  wsl = {
    enable = true;
    wslConf = {
      automount.root = "/mnt";
      network.generateResolvConf = false;
    };
    defaultUser = "buggy";
    startMenuLaunchers = true;
    nativeSystemd = true;
    docker-desktop.enable = false;
    extraBin = with pkgs; [
      {src = "${coreutils}/bin/mkdir";}
      {src = "${coreutils}/bin/cat";}
      {src = "${coreutils}/bin/whoami";}
      {src = "${coreutils}/bin/ls";}
      {src = "${busybox}/bin/addgroup";}
      {src = "${su}/bin/groupadd";}
      {src = "${su}/bin/usermod";}
    ];
  };
  systemd.services.docker-desktop-proxy.script = lib.mkForce ''${config.wsl.wslConf.automount.root}/wsl/docker-desktop/docker-desktop-user-distro proxy --docker-desktop-root ${config.wsl.wslConf.automount.root}/wsl/docker-desktop "C:\Program Files\Docker\Docker\resources"'';

  users.users.buggy = {
    description = "Buggy";
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = ["wheel" "docker"];
    # hashedPassword = "";
  };

  # users.mutableUsers = false;

  # security.sudo.wheelNeedsPassword = true;
  # users.users.root.hashedPassword = "";
  networking = {
    hostName = "nixosWSL";
    nameservers = [
      "192.168.50.2"
      "192.168.50.3"
    ];
  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
  };

  environment.systemPackages = with pkgs; [
    lima
  ];

  fileSystems."/mnt/nfs/traefik" = {
    device = "nas.home:/mnt/nvme/docker-volumes/traefik";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/traefik-edge" = {
    device = "nas.home:/mnt/nvme/docker-volumes/traefik-edge";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/pve-shared" = {
    device = "nas.home:/mnt/nvme/pve-shared";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/dev" = {
    device = "nas.home:/mnt/nvme/dev";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/file-server" = {
    device = "nas.home:/mnt/nvme/docker-volumes/file-server";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/n8n" = {
    device = "nas.home:/mnt/nvme/docker-volumes/n8n";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/frigate" = {
    device = "nas.home:/mnt/nvme/docker-volumes/frigate";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/duplicati" = {
    device = "nas.home:/mnt/nvme/docker-volumes/duplicati";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/replicas" = {
    device = "nas.home:/mnt/nvme/replicas";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/speedtest" = {
    device = "nas.home:/mnt/nvme/docker-volumes/speedtest";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/speedtest-influxdb" = {
    device = "nas.home:/mnt/nvme/docker-volumes/speedtest-influxdb";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/pterodactyl-panel" = {
    device = "nas.home:/mnt/nvme/docker-volumes/pterodactyl-panel";
    fsType = "nfs4";
    options = ["rw"];
  };

  system.stateVersion = "24.05";
}
