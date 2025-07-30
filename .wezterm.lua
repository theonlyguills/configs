-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

config.default_domain = 'WSL:Ubuntu-CFIS'

config.color_scheme = 'gogh'

config.window_frame = {
  font = wezterm.font { family = 'Fira Code', weight = 'Bold' },
  font_size = 12.0,
  active_titlebar_bg = '#333333',
  inactive_titlebar_bg = '#777777',
}

config.colors = {
  tab_bar = {
    -- The color of the inactive tab bar edge/divider
    inactive_tab_edge = '#575757',
  },
}

config.font = wezterm.font 'Fira Code'

config.window_background_opacity = .85


-- and finally, return the configuration to wezterm
return config