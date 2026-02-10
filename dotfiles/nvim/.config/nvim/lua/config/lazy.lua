-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out,                            "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.clipboard = "unnamedplus"
-- remove any timeout
vim.opt.ttimeout = false
vim.opt.timeout = false

vim.opt.hidden = false

-- Auto-close unused buffers when entering a new one
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    local current = vim.api.nvim_get_current_buf()
    local buftype = vim.api.nvim_get_option_value("buftype", { buf = current })

    -- Don't run logic if we are in a special buffer (like Telescope, NvimTree, etc.)
    if buftype ~= "" then
      return
    end

    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if buf ~= current and vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_get_option_value("buflisted", { buf = buf }) then
        local b_buftype = vim.api.nvim_get_option_value("buftype", { buf = buf })
        local modified = vim.api.nvim_get_option_value("modified", { buf = buf })

        -- Only delete normal, un-modified buffers that aren't visible in any window
        if b_buftype == "" and not modified and vim.fn.getbufinfo(buf)[1].hidden == 1 then
          vim.api.nvim_buf_delete(buf, { force = false })
        end
      end
    end
  end,
})

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  -- Configure any other settings here. See the documentation for more details.
  -- automatically check for plugin updates
  checker = { enabled = true },
  rocks = { enabled = false }
})
