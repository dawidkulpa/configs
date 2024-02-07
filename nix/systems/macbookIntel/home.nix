{osConfig, ...}: let
  language = name: text: text;
in {
  imports = [
    ../../shared/home.nix
  ];

  home.userName = "dawid.kulpa";
  home.homeDirectory = "/Users/dawid.kulpa";
  home.stateVersion = "23.11";
}
