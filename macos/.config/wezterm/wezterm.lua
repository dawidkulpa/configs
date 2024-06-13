local wezterm = require 'wezterm'

local config = wezterm.config_builder()

config.color_scheme = 'Catppuccin Mocha'
config.window_background_opacity = 0.9
config.macos_window_background_blur = 5
config.window_decorations = 'RESIZE'

config.default_prog = { '/opt/homebrew/bin/fish', '-l' }
config.default_cwd = wezterm.home_dir .. '/projects'

return config