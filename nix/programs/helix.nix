{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.my.programs.helix;
  myTheme = "catppuccin_mocha";
in {
  options = {
    my.programs.helix.enable = mkEnableOption "my helix configuration";
  };

  config = mkIf cfg.enable {
    programs.helix = {
      enable = true;
      defaultEditor = true;
      settings = {
        theme = myTheme;

        editor = {
          # Override because every terminal I use supports true color, but
          # sometimes helix fails to detect it over ssh, tmux, etc.
          true-color = true;
          color-modes = true;
          line-number = "relative";
          idle-timeout = 0;
          completion-trigger-len = 1;
          bufferline = "multiple";
          cursorline = true;
        };

        editor.statusline = {
          right = [
            "diagnostics"
            "selections"
            "position"
            "position-percentage"
            "file-encoding"
          ];
        };

        editor.cursor-shape = {
          insert = "block";
          select = "underline";
          normal = "block";
        };

        editor.indent-guides = {
          render = true;
          #character = "▏";
          skip-levels = 1;
        };

        editor.whitespace = {
          render.newline = "all";
          characters.newline = "↵";
        };

        editor.lsp = {
          display-messages = true;
          display-inlay-hints = true;
        };

        editor.inline-diagnostics = {
          cursor-line = "hint";
          other-lines = "error";
        };

        keys.normal = {
          G = "goto_last_line";

          # This goes against the Helix way of selection->action but it's a
          # common enough thing to warrant making it its own keybind.
          D = ["goto_first_nonwhitespace" "extend_to_line_end" "change_selection"];

          # Mode switching always happens at the end of the list of commands, so
          # the order that these are in doesn't matter because collapsing the selection
          # will always happen first.
          a = ["append_mode" "collapse_selection"];
          i = ["insert_mode" "collapse_selection"];

          # Mnemonic: control hints
          C-h = ":toggle-option lsp.display-inlay-hints";

          # By default, Helix tries to leave the cursor where it was when scrolling
          C-d = ["half_page_down" "goto_window_center"];
          C-u = ["half_page_up" "goto_window_center"];

          # Searching for a selection probably shouldn't have whitespace included.
          # Makes sense to keep the default keybind in select mode though?
          "*" = ["trim_selections" "search_selection"];
          "#" = ["toggle_comments"];
        };

        keys.normal.Z = let
          repeat = count: thing:
            if count < 2
            then [thing]
            else [thing] ++ repeat (count - 1) thing;
        in {
          C-d = ["half_page_down" "goto_window_center"];
          C-u = ["half_page_up" "goto_window_center"];

          d = "scroll_down";
          u = "scroll_up";
          e = "scroll_down";
          y = "scroll_up";

          # upper case should move more than one line but less than a half page
          J = repeat 5 "scroll_down";
          K = repeat 5 "scroll_up";
          D = repeat 5 "scroll_down";
          U = repeat 5 "scroll_up";
          E = repeat 5 "scroll_down";
          Y = repeat 5 "scroll_up";
        };

        keys.normal.space.w = {
          V = ["vsplit_new" "file_picker"];
          S = ["hsplit_new" "file_picker"];
        };

        # Minor mode, perform operations on selection.
        # When custom typable commands land, replace these with typables.
        keys.normal.V = {
          s = ":pipe sort";
          S = ":pipe sort -u";
        };

        keys.select = {
          # Mode switching always happens at the end of the list of commands, so
          # the order that these are in doesn't matter because collapsing the selection
          # will always happen first.
          a = ["append_mode" "collapse_selection"];
          i = ["insert_mode" "collapse_selection"];

          C-h = ":toggle-option lsp.display-inlay-hints";

          C-d = ["half_page_down" "goto_window_center"];
          C-u = ["half_page_up" "goto_window_center"];

          # When I collapse a selection in select mode, the next thing I do
          # is *always* enter normal mode.
          ";" = ["collapse_selection" "normal_mode"];
        };

        keys.insert = {
          C-h = ":toggle-option lsp.display-inlay-hints";

          # This is a pretty standard shortcut in most editors
          C-space = "completion";
        };
      };

      languages.language-server = {
        deno = {
          command = "deno";
          args = ["lsp"];
          config = {
            enable = true;
            unstable = true;
            lint = true;
          };
        };

        svelteserver.command = "svelteserver";

        tailwindcss = {
          command = "tailwindcss-language-server";
          language-id = "tailwindcss";
          args = ["--stdio"];
          config = {};
        };

        nil.command = "nil";
        nixd.command = "nixd";

        rust-analyzer.command = "rust-analyzer";

        ltex-ls.command = "ltex-ls";

        htmlls = {
          command = "vscode-html-language-server";
          args = ["--stdio"];
        };

        jsonls = {
          command = "vscode-json-language-server";
          args = ["--stdio"];
          # json.validate/format enabled by default
        };

        yamlls = {
          command = "yaml-language-server";
          args = ["--stdio"];
          config = {
            yaml = {
              completion = true;
              validate = true;
              hover = true;
              format.enable = true;
              schemaStore.enable = true;
              # Helpful explicit schemas
              schemas = {
                "https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json" = ["docker-compose*.yml" "docker-compose*.yaml" "compose*.yml" "compose*.yaml"];
                "https://json.schemastore.org/github-workflow.json" = ".github/workflows/*.{yml,yaml}";
              };
            };
          };
        };

        dockerls = {
          command = "docker-langserver";
          args = ["--stdio"];
        };

        docker-compose-langserver = {
          command = "docker-compose-langserver";
          args = ["--stdio"];
        };

        "fish-lsp".command = "fish-lsp";

        lemminx.command = "lemminx";

        # "systemd-lsp".command = "systemd-lsp"; # unavailable in nixos < 25.10

        marksman = {
          command = "marksman";
          args = ["server"];
        };

        pyright = {
          command = "pyright-langserver";
          args = ["--stdio"];
        };

        ruff = {
          command = "ruff";
          args = ["server"];
        };

        superhtml.command = "superhtml";
      };

      languages.language = [
        {
          name = "nix";
          language-servers = ["nixd"];
          auto-format = true;
          formatter = {
            command = "${pkgs.alejandra}/bin/alejandra";
            args = ["-"];
          };
          file-types = ["nix" "flake.nix" "default.nix" "shell.nix"];
        }
        {
          name = "fish";
          auto-format = true;
          formatter.command = "${pkgs.fish}/bin/fish_indent";
        }
        {
          name = "markdown";
          language-servers = ["ltex-ls"];
          auto-format = false;
          formatter = {
            command = "deno";
            args = ["--ext" "md" "-"];
          };
        }
        {
          name = "git-commit";
          language-servers = ["ltex-ls"];
        }
        {
          name = "dockerfile";
          language-servers = ["dockerls"];
          auto-format = true;
        }

        {
          name = "docker-compose";
          language-servers = ["docker-compose-langserver" "yamlls"];
        }

        {
          name = "yaml";
          language-servers = ["yamlls"];
        }

        {
          name = "html";
          language-servers = [
            "htmlls"
            "superhtml"
          ];
        }

        {
          name = "json";
          language-servers = ["jsonls"];
          file-types = ["json" "flake.lock"];
        }

        {
          name = "xml";
          language-servers = ["lemminx"];
        }

        {
          name = "systemd";
          language-servers = ["systemd-lsp"];
        }

        {
          name = "fish";
          language-servers = ["fish-lsp"];
        }

        {
          name = "markdown";
          language-servers = ["marksman" "ltex-ls"];
        }

        {
          name = "python";
          language-servers = ["pyright" "ruff"];
          auto-format = true;
        }
      ];
    };
  };
}
