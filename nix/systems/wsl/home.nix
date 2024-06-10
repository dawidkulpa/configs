{pkgs, ...}: {
  imports = [
    ../../shared/home.nix
  ];

  home.username = "buggy";
  home.homeDirectory = "/home/buggy";

  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    dotnet-sdk_8
    (
      python311.withPackages (p:
        with p; [
          virtualenv
          poetry-core
          pip
        ])
    )
  ];

  my.programs.fish.enableWslFunctions = true;
}
