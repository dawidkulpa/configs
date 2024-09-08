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
    };

    networking.firewall.allowedTCPPorts = [9443 8000 9000 9001 2377 7946];
    networking.firewall.allowedUDPPorts = [7946 4789];
  };
}
