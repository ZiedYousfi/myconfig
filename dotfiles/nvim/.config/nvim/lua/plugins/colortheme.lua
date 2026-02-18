return {
  -- Local black-pink theme — no remote dependency
  dir = vim.fn.stdpath("config") .. "/lua/plugins/black-pink",
  name = "black-pink",
  lazy = false,
  priority = 1000,
  config = function()
    vim.cmd.colorscheme("black-pink")
  end,
}