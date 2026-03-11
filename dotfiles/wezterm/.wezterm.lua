local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.default_prog = { "pwsh.exe" }

config.initial_cols = 160
config.initial_rows = 40

config.window_decorations = "RESIZE"
config.window_close_confirmation = "NeverPrompt"
config.adjust_window_size_when_changing_font_size = false

config.font = wezterm.font("Iosevka NFM")
config.font_size = 16.0

config.color_scheme = "BlackPink"

config.color_schemes = {
	["BlackPink"] = {
		foreground = "#d0d6e0",
		background = "#000000",
		cursor_bg = "#ff4ead",
		cursor_border = "#ff4ead",
		cursor_fg = "#000000",
		selection_bg = "#2a0016",
		selection_fg = "#d0d6e0",

		ansi = {
			"#000000",
			"#f87171",
			"#4ade80",
			"#facc15",
			"#60a5fa",
			"#ff4ead",
			"#22d3ee",
			"#d0d6e0",
		},

		brights = {
			"#2a2d36",
			"#fca5a5",
			"#86efac",
			"#fde047",
			"#93c5fd",
			"#ff85c8",
			"#67e8f9",
			"#f0f2f7",
		},
	},
}

config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.show_new_tab_button_in_tab_bar = false
config.tab_max_width = 32

config.window_background_opacity = 1.0

config.keys = {
	{
		key = "x",
		mods = "CTRL|SHIFT",
		action = wezterm.action.CloseCurrentPane({ confirm = true }),
	},
	{
		key = "h",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivatePaneDirection("Left"),
	},
	{
		key = "l",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivatePaneDirection("Right"),
	},
	{
		key = "k",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivatePaneDirection("Up"),
	},
	{
		key = "j",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivatePaneDirection("Down"),
	},
	{
		key = "-",
		mods = "CTRL",
		action = wezterm.action.DecreaseFontSize,
	},
	{
		key = "=",
		mods = "CTRL|SHIFT",
		action = wezterm.action.IncreaseFontSize,
	},
	{
		key = "_",
		mods = "CTRL|SHIFT",
		action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "+",
		mods = "CTRL|SHIFT",
		action = wezterm.action.SplitHorizontal({
			domain = "CurrentPaneDomain",
		}),
	},
}

return config
