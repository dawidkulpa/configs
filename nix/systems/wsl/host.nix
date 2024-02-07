{pkgs, ...}: {
  imports = [
    ../../shared/host.nix
  ];

  wsl = {
    enable = true;
    wslConf.automount.root = "/mnt";
    defaultUser = "buggy";
    startMenuLaunchers = true;
    nativeSystemd = true;
  };

  users.users.buggy = {
    description = "Buggy";
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = ["wheel"];
    # hashedPassword = "";
  };


  # users.mutableUsers = false;

  # security.sudo.wheelNeedsPassword = true;
  # users.users.root.hashedPassword = "";

  networking.hostName = "nixosWSL";

  system.stateVersion = "23.11";
}
