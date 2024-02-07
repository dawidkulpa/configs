{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.my.programs.git;
in {
  options.my.programs.git = {
    enable = mkEnableOption "my git configuration";
  };

  config = mkIf cfg.enable {
    programs.git = {
      enable = true;
      package = pkgs.gitFull;
      userName = "";
      userEmail = "";
      ignores = [
        "*~"
        "*.swp"
        "result"
        ".DS_Store"
        "/.helix"
        ".flake"
        ".idea"
      ];
      extraConfig = {
        init.defaultBranch = "master";
        push.autoSetupRemote = true;
      };
      delta.enable = true;
    };
  };
}
