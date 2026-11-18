{
  config,
  lib,
  pkgs,
  ...
}:

let
  repoPath = "${config.xdg.configHome}/dotfiles";
  repoFile = path: config.lib.file.mkOutOfStoreSymlink "${repoPath}/${path}";
in
{
  options.my.noctalia.wallpaper = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = ''
      Absolute path to the default Noctalia wallpaper. A wallpaper chosen
      in the Settings UI is stored in the machine-local state file and
      overrides this value.
    '';
  };

  config = {
    home.username = "robots";
    home.homeDirectory = "/home/robots";
    home.stateVersion = "25.11";

    programs.home-manager.enable = true;

    # Stop before changing anything if the checkout is missing. Noctalia's
    # live config links would otherwise point nowhere.
    home.activation.checkRepoPath = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
      if [[ ! -e ${lib.escapeShellArg "${repoPath}/flake.nix"} ]]; then
        errorEcho ${lib.escapeShellArg "${repoPath} does not lead to this repo's checkout. Clone the repo there, or link it: ln -sfn <checkout> ${repoPath}. Nothing was changed."}
        exit 1
      fi
    '';

    ## ----- applications --------------------------------------------------------
    home.packages = with pkgs; [
      brave
      nerd-fonts.jetbrains-mono
    ];

    # Standalone home-manager needs this for home.packages fonts to be
    # picked up by fontconfig.
    fonts.fontconfig.enable = true;

    home.sessionVariables = {
      BROWSER = "brave";
      TERMINAL = "alacritty";
    };

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = "brave-browser.desktop";
        "x-scheme-handler/http" = "brave-browser.desktop";
        "x-scheme-handler/https" = "brave-browser.desktop";
        "x-scheme-handler/about" = "brave-browser.desktop";
        "x-scheme-handler/unknown" = "brave-browser.desktop";
      };
    };

    ## ----- git -----------------------------------------------------------------
    programs.git = {
      enable = true;
      settings = {
        init.defaultBranch = "main";
      };

      # Identity and signing settings stay machine-local.
      includes = [ { path = "${config.xdg.configHome}/git/local"; } ];
    };

    ## ----- alacritty -----------------------------------------------------------
    programs.alacritty = {
      enable = true;
      settings = {
        font.normal.family = "JetBrainsMono Nerd Font";
        window.decorations = "None";
        window.opacity = 0.9;
      };
    };

    ## ----- noctalia ------------------------------------------------------------
    # Shared settings are live links into this checkout. The Settings UI writes
    # machine-local overrides to ~/.local/state/noctalia/settings.toml.
    home.file.".config/noctalia/config.toml".source = repoFile "config/noctalia/config.toml";
    home.file.".config/noctalia/palettes".source = repoFile "app-state/noctalia/palettes";
    home.file.".config/noctalia/wallpaper.toml" = lib.mkIf (config.my.noctalia.wallpaper != null) {
      text = ''
        [wallpaper.default]
        path = ${builtins.toJSON config.my.noctalia.wallpaper}
      '';
    };
  };
}
