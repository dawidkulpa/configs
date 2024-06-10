{pkgs, ...}: {
  imports = [
    ../../shared/home.nix
  ];

  home.username = "buggy";
  home.homeDirectory = "/home/buggy";

  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    libsForQt5.dolphin
  ];
}
