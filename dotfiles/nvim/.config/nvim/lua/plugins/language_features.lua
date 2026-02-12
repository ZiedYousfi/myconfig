return {
  -- Mason: package manager for LSP servers, linters, formatters
  {
    "mason-org/mason.nvim",
    lazy = false,
    opts = {},
  },

  -- Mason-LSPConfig: auto-install and enable LSP servers
  {
    "mason-org/mason-lspconfig.nvim",
    lazy = false,
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    opts = {
      automatic_installation = true,
      automatic_enable = true,
    },
  },

  -- LSPConfig: configurations for LSP servers
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    dependencies = {
      "mason-org/mason-lspconfig.nvim",
      "Saghen/blink.cmp",
    },
    config = function()
      local capabilities = require("blink.cmp").get_lsp_capabilities()
      local lspconfig = require("lspconfig")
      lspconfig.util.default_config = vim.tbl_extend("force", lspconfig.util.default_config, {
        capabilities = capabilities,
      })
    end,
  },

  -- Autocompletion
  {
    "Saghen/blink.cmp",
    lazy = false,
    dependencies = "rafamadriz/friendly-snippets",
    version = "*",
    opts = {
      keymap = { preset = "default" },
      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = "mono",
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
    },
  },


  -- Treesitter: syntax highlighting and code understanding
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
  },
  {
    'stevearc/conform.nvim',
    opts = {
      format_on_save = {
        -- These options will be passed to conform.format()
        timeout_ms = 500,
        lsp_format = "fallback",
      },
    },
  }
}
