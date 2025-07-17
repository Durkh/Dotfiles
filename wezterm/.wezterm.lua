-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
config.color_scheme = 'Afterglow'
config.font = wezterm.font("Lilex Nerd Font Mono", {weight=450, stretch="Normal", style="Normal"}) -- /home/ekank/.local/share/fonts/LilexNerdFontMono-ExtraThick.ttf, FontConfig
config.font_size = 9

config.use_fancy_tab_bar  = false
config.hide_tab_bar_if_only_one_tab = true

config.window_background_opacity = .7

-- and finally, return the configuration to wezterm
return config
