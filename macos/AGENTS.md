# MACOS CONFIGURATION

## OVERVIEW

Shell scripts for macOS setup + static dotfiles symlinked to `~/.config/`. No Nix involved — standalone Homebrew-based workflow.

## STRUCTURE

```
macos/
├── apps.sh          # Main setup: Homebrew install, app installs, symlink creation
├── tweaks.sh        # macOS system defaults (Finder, Spotlight, keyboard, etc.)
├── .gitignore       # Ignores .vscode/
└── .config/
    ├── fish/        # Fish shell config + functions (plugins: fzf, starship, thefuck, zoxide, fnm)
    ├── helix/       # config.toml (catppuccin_mocha, keybindings) + languages.toml (LSPs, formatters)
    ├── wezterm/     # Terminal emulator config
    ├── starship.toml
    ├── btop/        # System monitor config
    ├── tmux/        # Tmux config
    └── omf/         # Oh-My-Fish theme/plugin/channel config
```

## DEPLOY

1. `./apps.sh` — installs Homebrew (if missing), installs apps, creates `~/.config/` symlinks
2. **Must re-open terminal in Fish** after first run — script detects parent shell and exits if not Fish
3. `./apps.sh` again — installs remaining tools + LSPs (runs in Fish context)
4. `./tweaks.sh` — applies system defaults (keyboard repeat, Finder, Spotlight, screenshots)

## WHAT APPS.SH INSTALLS

**Via Homebrew cask**: wezterm, marta (Finder replacement)
**Via Homebrew**: fish, starship, fd, ripgrep, fzf, eza, jq, curl, btop, bun, wget, helix, zoxide, tealdeer, bat, thefuck, fnm, go
**Via npm**: typescript-language-server, vscode-langservers-extracted, compose-language-service, bash-language-server
**Via pip**: python-lsp-server
**Via go install**: gopls
**Via brew**: yaml-language-server, markdown-oxide, kotlin-lsp

## WHAT TWEAKS.SH CONFIGURES

Keyboard (fast repeat, no smart quotes/dashes/autocorrect), Finder (hidden files, extensions, list view, path bar, Marta as default), screenshots (PNG, no shadow, Desktop), Spotlight (apps/prefs/folders only), Mission Control (fast animations), Terminal (UTF-8 only)

## SYMLINK MAPPING

`apps.sh` creates symlinks from `macos/.config/<dir>` → `~/.config/<dir>` for: `fish`, `btop`, `wezterm`, `starship.toml`. Also links `.gitignore` → `~/.gitignore` and sets `core.excludesFile`.

Helix, tmux, and omf configs exist in `.config/` but are NOT symlinked by `apps.sh` — manual setup needed.

## CONVENTIONS

- Static config files — no templating, no generation
- Fish config references macOS-specific paths (`/opt/homebrew/bin`, etc.)
- LSP setup mirrors what Nix does in `shared/home.nix` but via npm/pip/brew
- `apps.sh` is idempotent for symlinks (skips if target dir exists)
