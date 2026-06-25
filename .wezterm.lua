local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.font_size = 16

config.enable_tab_bar = false
config.window_decorations = "TITLE | RESIZE"

config.font = wezterm.font("JetBrainsMono Nerd Font")
config.font_size = 16

config.color_scheme = "Solarized Dark (Gogh)"

-- tmux key bindings
-- config.leader = { key = "x", mods = 'CTRL', timeout_milliseconds = 1000 }
-- config.keys = {
--   -- splitting
--   {
--     mods   = "LEADER",
--     key    = "_",
--     action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' }
--   },
--   {
--     mods   = "LEADER",
--     key    = "|",
--     action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' }
--   },
--   -- maximize current pane
--   {
--     mods = 'LEADER',
--     key = 'z',
--     action = wezterm.action.TogglePaneZoomState
--   },
--   -- activate copy mode or vim mode
--   {
--     key = '[',
--     mods = 'LEADER',
--     action = wezterm.action.ActivateCopyMode
--   }
-- }

config.window_padding = {
  top = 0,
  bottom = 0,
}

return config