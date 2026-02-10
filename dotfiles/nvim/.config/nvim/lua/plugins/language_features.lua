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
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
    },
  },

  -- Treesitter: syntax highlighting and code understanding
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
  },
}
