return {
  "khoido2003/classic_monokai.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    -- Default configuration
    require("classic_monokai").setup()
    vim.cmd.colorscheme("classic-monokai")
  end
}