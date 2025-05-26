-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
config.color_scheme = "Tokyo Night (Gogh)"

config.font = wezterm.font("FiraCode Nerd Font Mono", { weight = "Regular" })
config.font_size = 13.0
config.freetype_load_target = "Light"

-- and finally, return the configuration to wezterm
return config
