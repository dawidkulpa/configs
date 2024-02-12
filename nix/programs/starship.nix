{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.my.programs.starship;
in {
  options.my.programs.starship = {
    enable = mkEnableOption "my starship configuration";
  };

  config = mkIf cfg.enable {
    programs.starship = {
      enable = true;
    };
  };
}
