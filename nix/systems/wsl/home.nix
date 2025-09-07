{pkgs, ...}: {
  imports = [
    ../../shared/home.nix
  ];

  home.username = "buggy";
  home.homeDirectory = "/home/buggy";

  home.stateVersion = "25.05";

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
    pipenv
    nvidia-docker
  ];

  my.programs.fish.enableWslFunctions = true;
}
