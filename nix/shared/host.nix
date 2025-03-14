{
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    ../modules/host
  ];

  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  environment.systemPackages = with pkgs; [
    inputs.agenix.packages.${pkgs.stdenv.system}.default
    nfs-utils
    libgcc
    google-chrome
    chromedriver
    logrotate
    polkit
    fwupd
  ];

  age = {
    secrets = {
    };

    identityPaths = [
      "/etc/ssh/ssh_host_ed25519_key"
    ];
  };

  nix.nixPath = lib.mkForce [
    "nixpkgs=${inputs.nixpkgs}"
    "home-manager=${inputs.home-manager}"
  ];

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    # This seems to cause issues:
    # https://github.com/NixOS/nix/issues/7273
    #auto-optimise-store = true;
    substituters = [
      "https://helix.cachix.org"
    ];
    trusted-public-keys = [
      "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
    ];
  };

  nix.optimise = {
    automatic = true;
    dates = ["01:00"];
  };

  # removing old generations
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nix.registry = {
    # Makes `nix run nixpkgs#...` run using the nixpkgs from this flake
    nixpkgs.flake = inputs.nixpkgs;

    # inputs.self is a reference to this flake, which allows self-references.
    # In this case, adding this flake to the registry under the name `my`,
    # which is the name I use any time I'm customising stuff.
    # (at time of writing, this is only used for `nix flake init -t my#...`)
    my.flake = inputs.self;
  };

  nixpkgs.config = {
    allowUnfree = true;
  };

  #nixpkgsUnstable.system = "x86_64-linux";
  #nixpkgsUnstable.config = {
  #  allowUnfree = true;
  #};

  # This needs to be set to get the default system-level fish configuration, such
  # as completions for Nix and related tools. This is also required because on macOS
  # the $PATH doesn't include all the entries it should by default.
  programs.fish.enable = true;
  programs.fish.useBabelfish = true;

  networking = {
    search = ["home"];
    resolvconf.extraOptions = ["timeout:1" "attempts:1" "rotate"];
  };
}
