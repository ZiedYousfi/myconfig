return {
	{
		"rachartier/tiny-inline-diagnostic.nvim",
		event = "VeryLazy",
		priority = 1000,
		config = function()
			require("tiny-inline-diagnostic").setup()
			vim.diagnostic.config({ virtual_text = false }) -- Disable Neovim's default virtual text diagnostics
		end,
	},
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		opts = {},
		keys = {
			{
				"f",
				mode = { "n", "x", "o" },
				function()
					require("flash").jump()
				end,
				desc = "Flash",
			},
		},
	},
}
