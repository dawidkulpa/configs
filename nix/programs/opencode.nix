{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.my.programs.opencode;
in {
  options.my.programs.opencode = {
    enable = mkEnableOption "my opencode configuration";
  };

  config = mkIf cfg.enable {
    programs.opencode = {
      enable = true;
      package = pkgs.unstable.opencode;
    };
  };
}
