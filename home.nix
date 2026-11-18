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
      COLORTERM = "truecolor";
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

    ## ----- zsh -----------------------------------------------------------------
    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
      defaultKeymap = "viins";
      history = {
        path = "${config.home.homeDirectory}/.zsh_history";
        size = 100000;
        save = 100000;
        share = true;
        extended = true;
        ignoreDups = true;
        ignoreSpace = true;
      };
      historySubstringSearch = {
        enable = true;
        searchUpKey = [
          "^[[A"
          "^[OA"
        ];
        searchDownKey = [
          "^[[B"
          "^[OB"
        ];
      };
    };

    programs.starship = {
      enable = true;
      presets = [ "pure-preset" ];

      settings = {
        format = "$username$hostname\${custom.worktree}$directory$git_branch$git_state$git_status$cmd_duration$line_break$python$character";

        custom.worktree = {
          description = "parent of the repo root, when in a linked worktree";
          require_repo = true;
          when = true;
          shell = [ "sh" ];
          command = ''
            git rev-parse --path-format=absolute \
                --git-dir --git-common-dir --show-toplevel 2>/dev/null | {
              read -r gitdir
              read -r common
              read -r top
              [ "$gitdir" = "$common" ] && exit 0
              parent=''${top%/*}
              printf '%s/' "''${parent##*/}"
            }
          '';
          format = "[$output]($style)";
          style = "blue";
        };
      };
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
