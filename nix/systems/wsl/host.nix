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
      "192.168.10.3"
      "192.168.10.4"
    ];
  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
  };

  environment.systemPackages = with pkgs; [
    lima
    jellyfin-ffmpeg
    #cudatoolkit
    #cudaPackages.cudnn
  ];

  fileSystems."/mnt/nfs/traefik" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/traefik";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/traefik-edge" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/traefik-edge";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/pve-shared" = {
    device = "nas.servers:/mnt/nvme/pve-shared";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/dev" = {
    device = "nas.servers:/mnt/nvme/dev";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/file-server" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/file-server";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/n8n" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/n8n";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/frigate" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/frigate";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/duplicati" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/duplicati";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/replicas" = {
    device = "nas.servers:/mnt/nvme/replicas";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/speedtest" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/speedtest";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/speedtest-influxdb" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/speedtest-influxdb";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/pterodactyl-panel" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/pterodactyl-panel";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/pterodactyl-wings" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/pterodactyl-wings";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/crowdsec" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/crowdsec";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/grafana" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/grafana";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/pmm" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/pmm";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/rsync-server" = {
    device = "nas.servers:/mnt/backup/rsync-server";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/prometheus" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/prometheus";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/victoriametrics" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/victoriametrics";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/portainer" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/portainer";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/paperless" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/paperless";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/printer" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/printer";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/organizr" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/organizr";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/tdarr" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/tdarr";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/rpi" = {
    device = "nas.servers:/mnt/backup/rpi";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/vencloud" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/vencloud";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/unifi" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/unifi";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/mongodb" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/mongodb";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/victorialogs" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/victorialogs";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/ansible" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/ansible";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/hyperion" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/hyperion";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/hoppscotch" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/hoppscotch";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/iot" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/iot";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/authentik" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/authentik";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/tools" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/tools";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/xpipe" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/xpipe-webtop";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/open-webui" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/open-webui";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/ai-chat" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/ai-chat";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/postgres" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/postgres";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/copyparty" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/copyparty";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/media" = {
    device = "nas.servers:/mnt/backup/media";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/mariadb" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/mariadb";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/jelly" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/jelly";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/kiwix" = {
    device = "nas.servers:/mnt/backup/kiwix";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/vikunja" = {
    device = "nas.servers:/mnt/nvme/docker-volumes/vikunja";
    fsType = "nfs4";
    options = ["rw"];
  };

  system.stateVersion = "25.11";
}
