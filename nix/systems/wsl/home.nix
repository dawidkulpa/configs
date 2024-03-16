{pkgs, ...}: {
  imports = [
    ../../shared/home.nix
  ];

  home.username = "buggy";
  home.homeDirectory = "/home/buggy";

  home.stateVersion = "23.11";

  home.packages = with pkgs; [
    dotnet-sdk_8
  ];

  my.programs.fish.enableWslFunctions = true;
}
