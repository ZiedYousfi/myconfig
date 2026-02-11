return {
	-- Telescope: fuzzy finder
	{
		"nvim-telescope/telescope.nvim",
		version = "*",
		cmd = "Telescope",
		dependencies = {
			{ "nvim-lua/plenary.nvim", lazy = true },
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make", lazy = true },
		},
		keys = {
			{ "<leader><leader>", "<cmd>Telescope find_files<CR>", desc = "Find files" },
		},
		config = function()
			local telescope = require("telescope")
			telescope.setup({})
			pcall(telescope.load_extension, "fzf")
		end,
	},

	-- Nvim-tree: file explorer
	{
		"nvim-tree/nvim-tree.lua",
		lazy = false,
		dependencies = {
			{ "nvim-tree/nvim-web-devicons", lazy = false },
		},
		keys = {
			{
				"<leader>e",
				function()
					local api = require("nvim-tree.api")
					local view = require("nvim-tree.view")

					if view.is_visible() then
						api.tree.close()
					else
						local cur_buf = vim.api.nvim_get_current_buf()
						api.tree.open()
						-- Kill the buffer if it's a normal file and the tree successfully opened
						if vim.bo[cur_buf].buftype == "" and vim.api.nvim_buf_is_valid(cur_buf) then
							vim.cmd("bdelete " .. cur_buf)
						end
					end
				end,
				desc = "Open file tree and kill buffer",
			},
		},
		config = function()
			local function on_attach(bufnr)
				local api = require("nvim-tree.api")

				-- default mappings
				api.config.mappings.default_on_attach(bufnr)

				-- custom mappings
				vim.keymap.set("n", "<LeftRelease>", function()
					local node = api.tree.get_node_under_cursor()
					if node then
						api.node.open.edit()
					end
				end, { buffer = bufnr, noremap = true, silent = true, nowait = true })
			end

			require("nvim-tree").setup({
				on_attach = on_attach,
				view = {
					side = "right",
					width = "100%",
				},
				actions = {
					open_file = {
						quit_on_open = true,
					},
				},
				update_focused_file = {
					enable = true,
					update_root = true,
				},
			})
		end,
	},
}
