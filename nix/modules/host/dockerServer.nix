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
    };

    networking.firewall.allowedTCPPorts = [];
    networking.firewall.allowedUDPPorts = [];
  };
}
