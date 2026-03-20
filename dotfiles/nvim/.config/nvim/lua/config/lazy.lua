-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.wrap = false

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

vim.opt.clipboard = "unnamedplus"

vim.opt.ttimeout = false
vim.opt.timeout = false

vim.opt.hidden = false

vim.opt.signcolumn = "yes"

if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
  vim.opt.shell = "pwsh"
  vim.opt.shellcmdflag = "-NoLogo -Command"
  vim.opt.shellquote = ""
  vim.opt.shellxquote = ""
else
  vim.opt.shell = "zsh"
  vim.opt.shellcmdflag = "-ic"
end

-- Auto-close unused buffers when entering a new one
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    local current = vim.api.nvim_get_current_buf()
    local buftype = vim.api.nvim_get_option_value("buftype", { buf = current })

    if buftype ~= "" then
      return
    end

    -- Collect all bufnrs referenced in the jumplist
    local jumplist_bufs = {}
    local jumplist, _ = unpack(vim.fn.getjumplist())
    for _, jump in ipairs(jumplist) do
      if jump.bufnr then
        jumplist_bufs[jump.bufnr] = true
      end
    end

    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if
        buf ~= current
        and vim.api.nvim_buf_is_valid(buf)
        and vim.api.nvim_get_option_value("buflisted", { buf = buf })
        and not jumplist_bufs[buf]
      then
        local b_buftype = vim.api.nvim_get_option_value("buftype", { buf = buf })
        local modified = vim.api.nvim_get_option_value("modified", { buf = buf })

        if b_buftype == "" and not modified and vim.fn.getbufinfo(buf)[1].hidden == 1 then
          vim.api.nvim_buf_delete(buf, { force = false })
        end
      end
    end
  end,
})

require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  checker = { enabled = false },
  rocks = { enabled = false },
})
