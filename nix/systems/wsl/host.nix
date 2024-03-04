{pkgs, ...}: {
  imports = [
    ../../shared/host.nix
  ];

  wsl = {
    enable = true;
    wslConf = {
      automount.root = "/mnt";
      network.generateResolvConf = false;
    };
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
  networking = {
    hostName = "nixosWSL";
    nameservers = [
      "192.168.50.2"
      "192.168.50.3"
    ];
  };

  system.stateVersion = "23.11";
}
