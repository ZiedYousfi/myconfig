local wezterm = require("wezterm")
local config = wezterm.config_builder()
local is_windows = wezterm.target_triple:find("windows") ~= nil

if is_windows then
	config.default_prog = { "pwsh.exe" }
end

config.window_decorations = "RESIZE"
config.window_close_confirmation = "NeverPrompt"
config.enable_wayland = false
config.use_resize_increments = false

config.font = wezterm.font_with_fallback({
	"Iosevka Nerd Font Mono",
	"Iosevka NFM",
})
config.font_size = 16.0

config.color_scheme = "blacknpink"

config.color_schemes = {
	["blacknpink"] = {
		foreground = "#d0d6e0",
		background = "#000000",
		cursor_bg = "#ff4ead",
		cursor_border = "#ff4ead",
		cursor_fg = "#000000",
		selection_bg = "#331728",
		selection_fg = "#f0f2f7",
		scrollbar_thumb = "#1a1a1a",
		split = "#1a1a1a",

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

		tab_bar = {
			background = "#000000",
			active_tab = {
				bg_color = "#0a0a0a",
				fg_color = "#f0f2f7",
			},
			inactive_tab = {
				bg_color = "#000000",
				fg_color = "#a0aabe",
			},
			inactive_tab_hover = {
				bg_color = "#111111",
				fg_color = "#d0d6e0",
			},
			new_tab = {
				bg_color = "#000000",
				fg_color = "#4a4f5e",
			},
			new_tab_hover = {
				bg_color = "#111111",
				fg_color = "#ff4ead",
			},
		},
	},
}

config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.show_new_tab_button_in_tab_bar = false
config.tab_max_width = 32

config.window_background_opacity = 0.85
config.line_height = 1
config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}

config.keys = {
	{
		key = "x",
		mods = "CTRL|SHIFT",
		action = wezterm.action.CloseCurrentPane({ confirm = false }),
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
