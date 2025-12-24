{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.my.programs.dockerServer;
in {
  options.my.programs.dockerServer = {
    enable = mkEnableOption "my docker server configuration";
  };

  config = mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      enableOnBoot = true;
      liveRestore = false;
      package = pkgs.docker_28;
      daemon.settings = {
        "log-driver" = "journald";
        "log-opts" = {
          "tag" = "{{.Name}}";
          "labels" = "com.docker.stack.namespace,com.docker.swarm.service.name";
        };
      };
    };

    systemd.services.docker-system-prune = {
      description = "Docker system prune -a";
      requires = ["docker.service"];
      after = ["docker.service"];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.docker}/bin/docker system prune -a -f";
      };
    };

    systemd.timers.docker-system-prune = {
      description = "Run Docker system prune daily";
      wantedBy = ["timers.target"];

      timerConfig = {
        OnCalendar = "daily"; # or e.g. "03:00"
        Persistent = true; # run on boot if missed while powered off
        RandomizedDelaySec = "30m"; # optional, avoids always running at exact same second
        Unit = "docker-system-prune.service";
      };
    };

    networking.firewall.allowedTCPPorts = [445 9443 8000 9000 9001 2377 7946 9100];
    networking.firewall.allowedUDPPorts = [7946 4789];
  };
}
