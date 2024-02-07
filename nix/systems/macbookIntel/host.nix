{pkgs, ...}: let
  language = _: t: t;
in {
  imports = [
    ../../shared/host.nix
    ../../shared/brew.nix
  ];

  # This has to be set on macOS to make fish a usable shell
  environment.shells = [pkgs.fish];

  programs.fish.fixPathOrder = true;

  system.defaults.NSGlobalDomain = {
    AppleInterfaceStyle = "Dark";
    ApplePressAndHoldEnabled = false;
    AppleShowAllExtensions = true;
    NSAutomaticCapitalizationEnabled = false;
    NSAutomaticSpellingCorrectionEnabled = false;
    NSAutomaticPeriodSubstitutionEnabled = false;
    NSAutomaticQuoteSubstitutionEnabled = false;
    InitialKeyRepeat = 15;
    KeyRepeat = 2;
    WebKitDeveloperExtras = true;
    com.apple.swipescrolldirection = false;
  };

  system.defaults.dock.autohide = true;
  system.defaults.LaunchServices.LSQuarantine = false;

  system.defaults.finder = {
    ShowPathbar = true;
    AppleShowAllFiles = true;
    FXEnableExtensionChangeWarning = false;

    # Set default path for new windows to $HOME
    NewWindowTarget = "PfHm";

    # Hides desktop icons
    CreateDesktop = false;

    # This magic string makes it search the current folder by default
    FXDefaultSearchScope = "SCcf";

    # Use the column view by default-- the obviously correct and best view
    FXPreferredViewStyle = "clmv";
  };

  "com.apple.Safari" = {
    IncludeDevelopMenu = true;
    IncludeInternalDebugMenu = true;
    WebKitDeveloperExtrasEnabledPreferenceKey = true;
  };
}
