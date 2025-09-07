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
      "192.168.10.2"
      "192.168.10.3"
    ];
  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
  };

  environment.systemPackages = with pkgs; [
    lima
    #cudatoolkit
    #cudaPackages.cudnn
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

  fileSystems."/mnt/nfs/pterodactyl-wings" = {
    device = "nas.home:/mnt/nvme/docker-volumes/pterodactyl-wings";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/crowdsec" = {
    device = "nas.home:/mnt/nvme/docker-volumes/crowdsec";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/grafana" = {
    device = "nas.home:/mnt/nvme/docker-volumes/grafana";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/pmm" = {
    device = "nas.home:/mnt/nvme/docker-volumes/pmm";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/rsync-server" = {
    device = "nas.home:/mnt/backup/rsync-server";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/prometheus" = {
    device = "nas.home:/mnt/nvme/docker-volumes/prometheus";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/victoriametrics" = {
    device = "nas.home:/mnt/nvme/docker-volumes/victoriametrics";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/portainer" = {
    device = "nas.home:/mnt/nvme/docker-volumes/portainer";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/paperless" = {
    device = "nas.home:/mnt/nvme/docker-volumes/paperless";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/printer" = {
    device = "nas.home:/mnt/nvme/docker-volumes/printer";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/organizr" = {
    device = "nas.home:/mnt/nvme/docker-volumes/organizr";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/tdarr" = {
    device = "nas.home:/mnt/nvme/docker-volumes/tdarr";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/rpi" = {
    device = "nas.home:/mnt/backup/rpi";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/vencloud" = {
    device = "nas.home:/mnt/nvme/docker-volumes/vencloud";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/unifi" = {
    device = "nas.home:/mnt/nvme/docker-volumes/unifi";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/mongodb" = {
    device = "nas.home:/mnt/nvme/docker-volumes/mongodb";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/victorialogs" = {
    device = "nas.home:/mnt/nvme/docker-volumes/victorialogs";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/ansible" = {
    device = "nas.home:/mnt/nvme/docker-volumes/ansible";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/hyperion" = {
    device = "nas.home:/mnt/nvme/docker-volumes/hyperion";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/hoppscotch" = {
    device = "nas.home:/mnt/nvme/docker-volumes/hoppscotch";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/iot" = {
    device = "nas.home:/mnt/nvme/docker-volumes/iot";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/authentik" = {
    device = "nas.home:/mnt/nvme/docker-volumes/authentik";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/tools" = {
    device = "nas.home:/mnt/nvme/docker-volumes/tools";
    fsType = "nfs4";
    options = ["rw"];
  };

  system.stateVersion = "25.05";
}
