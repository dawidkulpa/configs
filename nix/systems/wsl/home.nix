{...}: {
  imports = [
    ../../shared/home.nix
  ];

  home.username = "buggy";
  home.homeDirectory = "/home/buggy";

  home.stateVersion = "23.11";

  my.programs.fish.enableWslFunctions = true;
}
