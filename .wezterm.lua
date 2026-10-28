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

-- Windows-only settings (WSL default domain, local launch menu).
if wezterm.target_triple:find("windows") then
  config.default_domain = "WSL:Ubuntu-24.04"

  config.launch_menu = {
    {
      label = "PowerShell",
      args = { "powershell.exe", "-NoLogo" },
      domain = { DomainName = "local" },
    },
    {
      label = "CMD",
      args = { "cmd.exe" },
      domain = { DomainName = "local" },
    },
  }

  config.font_size = 11

  wezterm.on("mux-is-process-stateful", function(proc)
    return false
  end)
end

-- and finally, return the configuration to wezterm
return config
