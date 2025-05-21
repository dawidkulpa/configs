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
      package = pkgs.docker_27;
      daemon.settings = {
        "log-driver" = "journald";
        "log-opts" = {
          "tag" = "{{.Name}}";
          "labels" = "com.docker.stack.namespace,com.docker.swarm.service.name";
        };
      };
    };

    networking.firewall.allowedTCPPorts = [9443 8000 9000 9001 2377 7946 9100];
    networking.firewall.allowedUDPPorts = [7946 4789];
  };
}
