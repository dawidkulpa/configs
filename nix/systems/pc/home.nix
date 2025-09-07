{pkgs, ...}: {
  imports = [
    ../../shared/home.nix
  ];

  home.username = "buggy";
  home.homeDirectory = "/home/buggy";

  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    libsForQt5.dolphin

    opera
    discord
    lutris
    git-open
  ];
}
