{pkgs, ...}: {
  imports = [
    ../programs
    ../modules/home
  ];

  home.stateVersion = "23.11";

  home.packages = with pkgs; [
    # Editors that I sometimes want to play with
    vim
    neovim

    # Find me stuff
    fd
    ripgrep
    fzf
    comma

    # File stuff
    eza
    jq
    glow

    # File transfer stuff
    curl
    croc
    wget

    btop

    # dev
    bun
  ];

  # Enables the programs and uses my configuration for them.
  # The options are defined in /programs/*
  my.programs = {
    fish.enable = true;
    git.enable = true;
    tmux.enable = true;
    helix.enable = true;
    tealdeer.enable = true;
    starship.enable = true;
  };

  # Enables programs that I don't have a more complicated config for.
  # Programs in this section should be limited to a few lines of config at most.
  programs = {
    # TODO: figure out why this is breaking in nushell
    zoxide = {
      enable = true;
      enableNushellIntegration = false;
    };

    home-manager.enable = true;

    zellij.enable = true;

    nushell = {
      enable = true;

      # nushellFull adds support for dataframes
      package = pkgs.nushellFull;
    };

    gh = {
      enable = true;

      # Required because of a settings migration
      # settings.version = 1;
    };

    bat = {
      enable = true;
      config.theme = "gruvbox-dark";
    };
  };
}
