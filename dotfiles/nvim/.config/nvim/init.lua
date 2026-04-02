vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

if vim.fn.has("win32") == 1 then
  local py = vim.fn.exepath("py")
  if py == "" then
    py = vim.fn.exepath("python")
  end
  if py ~= "" then
    local real_python = vim.fn.system('py -c "import sys; print(sys.executable)"'):gsub("%s+$", "")
    if real_python ~= "" then
      local real_dir = vim.fn.fnamemodify(real_python, ":h")
      vim.env.PATH = real_dir .. ";" .. vim.env.PATH
    end
  end
end

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

vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    local current = vim.api.nvim_get_current_buf()
    local buftype = vim.api.nvim_get_option_value("buftype", { buf = current })

    if buftype ~= "" then
      return
    end

    local jumplist = vim.fn.getjumplist()[1]
    for i = #jumplist, 1, -1 do
      local entry = jumplist[i]
      local entry_buftype = vim.api.nvim_get_option_value("buftype", { buf = entry.bufnr })
      if entry_buftype ~= "" then
        vim.cmd(i .. "clearjumps")
      end
    end

    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if
          buf ~= current
          and vim.api.nvim_buf_is_valid(buf)
          and vim.api.nvim_get_option_value("buflisted", { buf = buf })
      then
        local entry_buftype = vim.api.nvim_get_option_value("buftype", { buf = buf })
        local modified = vim.api.nvim_get_option_value("modified", { buf = buf })

        if entry_buftype == "" and not modified and vim.fn.getbufinfo(buf)[1].hidden == 1 then
          vim.cmd.bdelete(buf)
        end
      end
    end
  end,
})

vim.keymap.set("n", "<leader>ce", "<cmd>Copilot enable<CR>", { desc = "Toggle Copilot on" })
vim.keymap.set("n", "<leader>cd", "<cmd>Copilot disable<CR>", { desc = "Toggle Copilot off" })
vim.keymap.set("n", "<leader>uv", "<cmd>ASToggle<CR>", { desc = "Toggle autosave" })
vim.keymap.set("n", "<leader><leader>", function()
  require("fff").find_files()
end, { desc = "Find files" })
vim.keymap.set({ "n", "x", "o" }, "f", function()
  require("flash").jump()
end, { desc = "Flash" })
vim.keymap.set("n", "<leader>e", function()
  local api = require("nvim-tree.api")
  local view = require("nvim-tree.view")

  if view.is_visible() then
    api.tree.close()
    return
  end

  local current = vim.api.nvim_get_current_buf()
  api.tree.open()

  local is_normal = vim.bo[current].buftype == ""
  local is_valid = vim.api.nvim_buf_is_valid(current)
  local is_modified = vim.bo[current].modified

  if is_normal and is_valid and not is_modified then
    vim.cmd("bdelete " .. current)
  end
end, { desc = "Open file tree and kill buffer" })

local function gh(repo, branch)
  return {
    src = "https://github.com/" .. repo,
    version = branch,
  }
end

vim.api.nvim_create_augroup("NativePackHooks", { clear = true })
vim.api.nvim_create_autocmd("PackChanged", {
  group = "NativePackHooks",
  callback = function(ev)
    local data = ev.data
    if not data or not data.spec or (data.kind ~= "install" and data.kind ~= "update") then
      return
    end

    if data.spec.name == "fff.nvim" then
      vim.cmd.packadd({ data.spec.name, magic = { file = false } })
      local ok, downloader = pcall(require, "fff.download")
      if ok then
        downloader.download_or_build_binary()
      end
      return
    end

    if data.spec.name == "nvim-treesitter" then
      vim.cmd.packadd({ data.spec.name, magic = { file = false } })
      pcall(vim.cmd.TSUpdate)
    end
  end,
})

vim.api.nvim_create_user_command("Update", function()
  vim.pack.update(nil, { force = true })
end, {})

vim.pack.add({
  gh("github/copilot.vim", "release"),
  gh("Pocco81/auto-save.nvim", "main"),
  gh("rachartier/tiny-inline-diagnostic.nvim", "main"),
  gh("folke/flash.nvim", "main"),
  gh("dmtrKovalenko/fff.nvim", "main"),
  gh("nvim-tree/nvim-web-devicons", "master"),
  gh("nvim-tree/nvim-tree.lua", "master"),
  gh("mason-org/mason.nvim", "main"),
  gh("mason-org/mason-lspconfig.nvim", "main"),
  gh("folke/lazydev.nvim", "main"),
  gh("neovim/nvim-lspconfig", "master"),
  gh("rafamadriz/friendly-snippets", "main"),
  gh("Saghen/blink.cmp", "main"),
  gh("nvim-treesitter/nvim-treesitter", "main"),
  gh("stevearc/conform.nvim", "master"),
}, { confirm = false })

local function load_black_pink()
  local p = {
    black_deep = "#000000",
    black_surface = "#0a0a0a",
    black_raised = "#111111",
    black_border = "#1a1a1a",
    black_highlight = "#222222",
    text_heading = "#f0f2f7",
    text_body = "#d0d6e0",
    text_muted = "#a0aabe",
    text_disabled = "#4a4f5e",
    text_invisible = "#2a2d36",
    accent = "#ff4ead",
    accent_hover = "#c02679",
    accent_dim = "#a0205f",
    accent_soft = "#1a0810",
    accent_glow = "#330f22",
    accent_mid = "#661e45",
    success = "#4ade80",
    success_bright = "#86efac",
    warning = "#facc15",
    warning_bright = "#fde047",
    error = "#f87171",
    error_bright = "#fca5a5",
    info = "#60a5fa",
    info_bright = "#93c5fd",
    hint = "#a78bfa",
    cyan = "#22d3ee",
    cyan_bright = "#67e8f9",
    magenta_bright = "#ff85c8",
    none = "NONE",
  }

  local function hi(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
  end
  vim.o.background = "dark"
  vim.g.colors_name = "black-pink"

  hi("Normal", { fg = p.text_body, bg = p.black_deep })
  hi("NormalFloat", { fg = p.text_body, bg = p.black_surface })
  hi("NormalNC", { fg = p.text_body, bg = p.black_deep })
  hi("ColorColumn", { bg = p.black_raised })
  hi("Conceal", { fg = p.text_disabled })
  hi("Cursor", { fg = p.black_deep, bg = p.accent })
  hi("lCursor", { fg = p.black_deep, bg = p.accent })
  hi("CursorIM", { fg = p.black_deep, bg = p.accent })
  hi("CursorLine", { bg = p.black_raised })
  hi("CursorColumn", { bg = p.black_raised })
  hi("CursorLineNr", { fg = p.accent, bold = true })
  hi("LineNr", { fg = p.text_disabled })
  hi("LineNrAbove", { fg = p.text_disabled })
  hi("LineNrBelow", { fg = p.text_disabled })
  hi("SignColumn", { fg = p.text_muted, bg = p.black_deep })
  hi("FoldColumn", { fg = p.text_disabled, bg = p.black_deep })
  hi("Folded", { fg = p.text_muted, bg = p.black_raised })
  hi("VertSplit", { fg = p.black_border, bg = p.black_deep })
  hi("WinSeparator", { fg = p.black_border, bg = p.black_deep })
  hi("StatusLine", { fg = p.text_muted, bg = p.black_deep })
  hi("StatusLineNC", { fg = p.text_disabled, bg = p.black_deep })
  hi("TabLine", { fg = p.text_muted, bg = p.black_surface })
  hi("TabLineFill", { bg = p.black_deep })
  hi("TabLineSel", { fg = p.text_heading, bg = p.black_deep, bold = true })
  hi("Pmenu", { fg = p.text_body, bg = p.black_surface })
  hi("PmenuSel", { fg = p.text_heading, bg = p.black_highlight })
  hi("PmenuSbar", { bg = p.black_raised })
  hi("PmenuThumb", { bg = p.text_disabled })
  hi("PmenuExtra", { fg = p.text_muted, bg = p.black_surface })
  hi("PmenuExtraSel", { fg = p.text_muted, bg = p.black_highlight })
  hi("Visual", { bg = p.black_highlight })
  hi("VisualNOS", { bg = p.black_highlight })
  hi("Search", { fg = p.black_deep, bg = p.accent_glow })
  hi("IncSearch", { fg = p.black_deep, bg = p.accent_mid })
  hi("CurSearch", { fg = p.black_deep, bg = p.accent })
  hi("Substitute", { fg = p.black_deep, bg = p.accent })
  hi("MatchParen", { fg = p.accent, bold = true, underline = true })
  hi("NonText", { fg = p.text_invisible })
  hi("SpecialKey", { fg = p.text_invisible })
  hi("Whitespace", { fg = p.text_invisible })
  hi("EndOfBuffer", { fg = p.black_border })
  hi("Directory", { fg = p.accent })
  hi("Title", { fg = p.text_heading, bold = true })
  hi("WildMenu", { fg = p.text_heading, bg = p.black_highlight })
  hi("Question", { fg = p.info })
  hi("MoreMsg", { fg = p.success })
  hi("ModeMsg", { fg = p.accent, bold = true })
  hi("MsgArea", { fg = p.text_body })
  hi("MsgSeparator", { fg = p.black_border, bg = p.black_deep })
  hi("ErrorMsg", { fg = p.error, bold = true })
  hi("WarningMsg", { fg = p.warning })
  hi("SpellBad", { undercurl = true, sp = p.error })
  hi("SpellCap", { undercurl = true, sp = p.warning })
  hi("SpellRare", { undercurl = true, sp = p.hint })
  hi("SpellLocal", { undercurl = true, sp = p.info })
  hi("DiffAdd", { fg = p.success, bg = p.black_surface })
  hi("DiffChange", { fg = p.warning, bg = p.black_surface })
  hi("DiffDelete", { fg = p.error, bg = p.black_surface })
  hi("DiffText", { fg = p.text_heading, bg = p.black_raised, bold = true })
  hi("Added", { fg = p.success })
  hi("Changed", { fg = p.warning })
  hi("Removed", { fg = p.error })
  hi("QuickFixLine", { fg = p.text_heading, bg = p.black_highlight })
  hi("IblIndent", { fg = p.black_border })
  hi("IblScope", { fg = p.accent_glow })
  hi("Comment", { fg = p.text_disabled, italic = true })
  hi("SpecialComment", { fg = p.text_disabled, italic = true })
  hi("Constant", { fg = p.cyan })
  hi("String", { fg = p.success })
  hi("Character", { fg = p.success })
  hi("Number", { fg = p.warning })
  hi("Boolean", { fg = p.warning })
  hi("Float", { fg = p.warning })
  hi("Identifier", { fg = p.text_body })
  hi("Function", { fg = p.magenta_bright })
  hi("Statement", { fg = p.accent })
  hi("Conditional", { fg = p.accent })
  hi("Repeat", { fg = p.accent })
  hi("Label", { fg = p.accent })
  hi("Operator", { fg = p.text_muted })
  hi("Keyword", { fg = p.accent })
  hi("Exception", { fg = p.accent })
  hi("PreProc", { fg = p.hint })
  hi("Include", { fg = p.hint })
  hi("Define", { fg = p.hint })
  hi("Macro", { fg = p.hint })
  hi("PreCondit", { fg = p.hint })
  hi("Type", { fg = p.text_heading })
  hi("StorageClass", { fg = p.accent })
  hi("Structure", { fg = p.text_heading })
  hi("Typedef", { fg = p.text_heading })
  hi("Special", { fg = p.cyan })
  hi("SpecialChar", { fg = p.cyan })
  hi("Tag", { fg = p.accent })
  hi("Delimiter", { fg = p.text_invisible })
  hi("Debug", { fg = p.warning })
  hi("Underlined", { underline = true })
  hi("Bold", { bold = true })
  hi("Italic", { italic = true })
  hi("Ignore", { fg = p.text_invisible })
  hi("Error", { fg = p.error, bold = true })
  hi("Todo", { fg = p.hint, bold = true })

  hi("@variable", { fg = p.text_body })
  hi("@variable.builtin", { fg = p.accent, italic = true })
  hi("@variable.parameter", { fg = p.text_muted })
  hi("@variable.member", { fg = p.text_body })
  hi("@constant", { fg = p.cyan })
  hi("@constant.builtin", { fg = p.cyan })
  hi("@constant.macro", { fg = p.hint })
  hi("@string", { fg = p.success })
  hi("@string.regex", { fg = p.cyan })
  hi("@string.escape", { fg = p.accent })
  hi("@string.special", { fg = p.cyan })
  hi("@number", { fg = p.warning })
  hi("@number.float", { fg = p.warning })
  hi("@boolean", { fg = p.warning })
  hi("@function", { fg = p.magenta_bright })
  hi("@function.builtin", { fg = p.magenta_bright })
  hi("@function.call", { fg = p.magenta_bright })
  hi("@function.macro", { fg = p.hint })
  hi("@function.method", { fg = p.magenta_bright })
  hi("@function.method.call", { fg = p.magenta_bright })
  hi("@constructor", { fg = p.text_heading })
  hi("@keyword", { fg = p.accent })
  hi("@keyword.function", { fg = p.accent })
  hi("@keyword.operator", { fg = p.accent })
  hi("@keyword.return", { fg = p.accent })
  hi("@keyword.import", { fg = p.hint })
  hi("@keyword.modifier", { fg = p.accent })
  hi("@keyword.type", { fg = p.accent })
  hi("@keyword.conditional", { fg = p.accent })
  hi("@keyword.conditional.ternary", { fg = p.accent })
  hi("@keyword.repeat", { fg = p.accent })
  hi("@keyword.exception", { fg = p.accent })
  hi("@keyword.coroutine", { fg = p.accent })
  hi("@keyword.debug", { fg = p.warning })
  hi("@keyword.directive", { fg = p.hint })
  hi("@keyword.directive.define", { fg = p.hint })
  hi("@type", { fg = p.text_heading })
  hi("@type.builtin", { fg = p.text_heading })
  hi("@type.definition", { fg = p.text_heading })
  hi("@type.qualifier", { fg = p.accent })
  hi("@attribute", { fg = p.hint })
  hi("@attribute.builtin", { fg = p.hint })
  hi("@property", { fg = p.text_body })
  hi("@operator", { fg = p.text_muted })
  hi("@punctuation.delimiter", { fg = p.text_invisible })
  hi("@punctuation.bracket", { fg = p.text_invisible })
  hi("@punctuation.special", { fg = p.text_muted })
  hi("@comment", { fg = p.text_disabled, italic = true })
  hi("@comment.documentation", { fg = p.text_disabled, italic = true })
  hi("@comment.error", { fg = p.error, bold = true })
  hi("@comment.warning", { fg = p.warning, bold = true })
  hi("@comment.note", { fg = p.info, bold = true })
  hi("@comment.todo", { fg = p.hint, bold = true })
  hi("@markup.heading", { fg = p.text_heading, bold = true })
  hi("@markup.heading.1", { fg = p.accent, bold = true })
  hi("@markup.heading.2", { fg = p.accent, bold = true })
  hi("@markup.heading.3", { fg = p.magenta_bright, bold = true })
  hi("@markup.heading.4", { fg = p.magenta_bright })
  hi("@markup.heading.5", { fg = p.text_heading })
  hi("@markup.heading.6", { fg = p.text_muted })
  hi("@markup.raw", { fg = p.text_heading, bg = p.black_surface })
  hi("@markup.raw.block", { fg = p.text_heading, bg = p.black_surface })
  hi("@markup.link", { fg = p.accent, underline = true })
  hi("@markup.link.label", { fg = p.info })
  hi("@markup.link.url", { fg = p.accent_dim, underline = true })
  hi("@markup.italic", { italic = true })
  hi("@markup.strong", { bold = true })
  hi("@markup.strikethrough", { strikethrough = true })
  hi("@markup.quote", { fg = p.text_muted, italic = true })
  hi("@markup.list", { fg = p.accent })
  hi("@markup.list.checked", { fg = p.success })
  hi("@markup.list.unchecked", { fg = p.text_disabled })
  hi("@tag", { fg = p.accent })
  hi("@tag.builtin", { fg = p.accent })
  hi("@tag.attribute", { fg = p.text_muted })
  hi("@tag.delimiter", { fg = p.text_invisible })
  hi("@module", { fg = p.text_heading })
  hi("@module.builtin", { fg = p.text_heading })
  hi("@label", { fg = p.accent })

  hi("@lsp.type.class", { fg = p.text_heading })
  hi("@lsp.type.decorator", { fg = p.hint })
  hi("@lsp.type.enum", { fg = p.cyan })
  hi("@lsp.type.enumMember", { fg = p.cyan })
  hi("@lsp.type.function", { fg = p.magenta_bright })
  hi("@lsp.type.interface", { fg = p.text_heading })
  hi("@lsp.type.macro", { fg = p.hint })
  hi("@lsp.type.method", { fg = p.magenta_bright })
  hi("@lsp.type.namespace", { fg = p.text_heading })
  hi("@lsp.type.parameter", { fg = p.text_muted })
  hi("@lsp.type.property", { fg = p.text_body })
  hi("@lsp.type.struct", { fg = p.text_heading })
  hi("@lsp.type.type", { fg = p.text_heading })
  hi("@lsp.type.typeParameter", { fg = p.text_heading })
  hi("@lsp.type.variable", { fg = p.text_body })
  hi("@lsp.type.keyword", { fg = p.accent })
  hi("@lsp.type.number", { fg = p.warning })
  hi("@lsp.type.string", { fg = p.success })
  hi("@lsp.type.operator", { fg = p.text_muted })
  hi("@lsp.type.comment", { fg = p.text_disabled, italic = true })
  hi("@lsp.type.regexp", { fg = p.cyan })
  hi("@lsp.mod.deprecated", { strikethrough = true })
  hi("@lsp.mod.readonly", { fg = p.cyan })
  hi("@lsp.mod.static", { italic = true })
  hi("@lsp.mod.defaultLibrary", { fg = p.text_heading })
  hi("@lsp.mod.global", { fg = p.cyan })

  hi("DiagnosticError", { fg = p.error })
  hi("DiagnosticWarn", { fg = p.warning })
  hi("DiagnosticInfo", { fg = p.info })
  hi("DiagnosticHint", { fg = p.hint })
  hi("DiagnosticOk", { fg = p.success })
  hi("DiagnosticVirtualTextError", { fg = p.error, bg = p.black_surface, italic = true })
  hi("DiagnosticVirtualTextWarn", { fg = p.warning, bg = p.black_surface, italic = true })
  hi("DiagnosticVirtualTextInfo", { fg = p.info, bg = p.black_surface, italic = true })
  hi("DiagnosticVirtualTextHint", { fg = p.hint, bg = p.black_surface, italic = true })
  hi("DiagnosticUnderlineError", { underline = true, sp = p.error })
  hi("DiagnosticUnderlineWarn", { underline = true, sp = p.warning })
  hi("DiagnosticUnderlineInfo", { underline = true, sp = p.info })
  hi("DiagnosticUnderlineHint", { underline = true, sp = p.hint })
  hi("DiagnosticFloatingError", { fg = p.error })
  hi("DiagnosticFloatingWarn", { fg = p.warning })
  hi("DiagnosticFloatingInfo", { fg = p.info })
  hi("DiagnosticFloatingHint", { fg = p.hint })
  hi("DiagnosticSignError", { fg = p.error })
  hi("DiagnosticSignWarn", { fg = p.warning })
  hi("DiagnosticSignInfo", { fg = p.info })
  hi("DiagnosticSignHint", { fg = p.hint })
  hi("LspReferenceText", { bg = p.black_highlight })
  hi("LspReferenceRead", { bg = p.black_highlight })
  hi("LspReferenceWrite", { bg = p.black_highlight, bold = true })
  hi("LspInlayHint", { fg = p.text_invisible, bg = p.black_surface, italic = true })
  hi("LspCodeLens", { fg = p.text_disabled, italic = true })
  hi("LspCodeLensSeparator", { fg = p.black_border })
  hi("LspSignatureActiveParameter", { fg = p.accent, bold = true })

  hi("FFFNormal", { fg = p.text_body, bg = p.black_surface })
  hi("FFFCursor", { fg = p.text_heading, bg = p.black_highlight })
  hi("FFFMatched", { fg = p.accent, bold = true })
  hi("FFFTitle", { fg = p.black_deep, bg = p.accent, bold = true })
  hi("FFFPrompt", { fg = p.accent })
  hi("FFFDirectoryPath", { fg = p.text_disabled })
  hi("FFFScrollbar", { fg = p.black_border })
  hi("FFFDebug", { fg = p.text_disabled })
  hi("FFFSelected", { fg = p.text_heading, bg = p.black_highlight })
  hi("FFFSelectedActive", { fg = p.black_deep, bg = p.accent, bold = true })
  hi("FFFGitStaged", { fg = p.accent })
  hi("FFFGitModified", { fg = p.text_heading })
  hi("FFFGitDeleted", { fg = p.text_disabled })
  hi("FFFGitRenamed", { fg = p.accent })
  hi("FFFGitUntracked", { fg = p.text_body })
  hi("FFFGitIgnored", { fg = p.text_invisible })
  hi("FFFGitSignStaged", { fg = p.accent })
  hi("FFFGitSignModified", { fg = p.text_heading })
  hi("FFFGitSignDeleted", { fg = p.text_disabled })
  hi("FFFGitSignRenamed", { fg = p.accent })
  hi("FFFGitSignUntracked", { fg = p.text_body })
  hi("FFFGitSignIgnored", { fg = p.text_invisible })
  hi("FFFGitSignStagedSelected", { fg = p.black_deep, bg = p.accent, bold = true })
  hi("FFFGitSignModifiedSelected", { fg = p.black_deep, bg = p.accent, bold = true })
  hi("FFFGitSignDeletedSelected", { fg = p.black_deep, bg = p.accent, bold = true })
  hi("FFFGitSignRenamedSelected", { fg = p.black_deep, bg = p.accent, bold = true })
  hi("FFFGitSignUntrackedSelected", { fg = p.black_deep, bg = p.accent, bold = true })
  hi("FFFGitSignIgnoredSelected", { fg = p.black_deep, bg = p.accent, bold = true })
  hi("FFFGrepMatch", { fg = p.accent, bold = true })
  hi("FFFGrepLineNumber", { fg = p.text_disabled })
  hi("FFFGrepRegexActive", { fg = p.accent })
  hi("FFFGrepPlainActive", { fg = p.text_disabled })
  hi("FFFGrepFuzzyActive", { fg = p.text_heading })
  hi("FFFSuggestionHeader", { fg = p.accent, bold = true })

  hi("NvimTreeNormal", { fg = p.text_body, bg = p.black_surface })
  hi("NvimTreeNormalFloat", { fg = p.text_body, bg = p.black_surface })
  hi("NvimTreeEndOfBuffer", { fg = p.black_surface })
  hi("NvimTreeRootFolder", { fg = p.accent, bold = true })
  hi("NvimTreeFolderIcon", { fg = p.accent })
  hi("NvimTreeFolderName", { fg = p.text_body })
  hi("NvimTreeOpenedFolderName", { fg = p.text_heading, bold = true })
  hi("NvimTreeEmptyFolderName", { fg = p.text_disabled })
  hi("NvimTreeFileName", { fg = p.text_body })
  hi("NvimTreeOpenedFile", { fg = p.accent })
  hi("NvimTreeModifiedFile", { fg = p.warning })
  hi("NvimTreeExecFile", { fg = p.success, bold = true })
  hi("NvimTreeSpecialFile", { fg = p.hint, underline = true })
  hi("NvimTreeSymlink", { fg = p.cyan })
  hi("NvimTreeSymlinkArrow", { fg = p.text_muted })
  hi("NvimTreeGitDirty", { fg = p.warning })
  hi("NvimTreeGitStaged", { fg = p.success })
  hi("NvimTreeGitMerge", { fg = p.info })
  hi("NvimTreeGitRenamed", { fg = p.hint })
  hi("NvimTreeGitNew", { fg = p.success })
  hi("NvimTreeGitDeleted", { fg = p.error })
  hi("NvimTreeGitIgnored", { fg = p.text_disabled })
  hi("NvimTreeCursorLine", { bg = p.black_highlight })
  hi("NvimTreeVertSplit", { fg = p.black_border, bg = p.black_surface })
  hi("NvimTreeWindowPicker", { fg = p.accent, bg = p.black_raised, bold = true })
  hi("NvimTreeBookmark", { fg = p.accent })
  hi("NvimTreeWinSeparator", { fg = p.black_border, bg = p.black_surface })
  hi("NvimTreeIndentMarker", { fg = p.black_border })

  hi("BlinkCmpMenu", { fg = p.text_body, bg = p.black_surface })
  hi("BlinkCmpMenuBorder", { fg = p.black_border, bg = p.black_surface })
  hi("BlinkCmpMenuSelection", { fg = p.text_heading, bg = p.black_highlight })
  hi("BlinkCmpScrollBarThumb", { bg = p.text_disabled })
  hi("BlinkCmpScrollBarGutter", { bg = p.black_raised })
  hi("BlinkCmpLabel", { fg = p.text_body })
  hi("BlinkCmpLabelDeprecated", { fg = p.text_disabled, strikethrough = true })
  hi("BlinkCmpLabelMatch", { fg = p.accent, bold = true })
  hi("BlinkCmpLabelDetail", { fg = p.text_muted })
  hi("BlinkCmpLabelDescription", { fg = p.text_disabled })
  hi("BlinkCmpKindText", { fg = p.text_muted })
  hi("BlinkCmpKindMethod", { fg = p.magenta_bright })
  hi("BlinkCmpKindFunction", { fg = p.magenta_bright })
  hi("BlinkCmpKindConstructor", { fg = p.text_heading })
  hi("BlinkCmpKindField", { fg = p.text_body })
  hi("BlinkCmpKindVariable", { fg = p.text_body })
  hi("BlinkCmpKindClass", { fg = p.text_heading })
  hi("BlinkCmpKindInterface", { fg = p.text_heading })
  hi("BlinkCmpKindModule", { fg = p.text_heading })
  hi("BlinkCmpKindProperty", { fg = p.text_body })
  hi("BlinkCmpKindUnit", { fg = p.warning })
  hi("BlinkCmpKindValue", { fg = p.cyan })
  hi("BlinkCmpKindEnum", { fg = p.cyan })
  hi("BlinkCmpKindKeyword", { fg = p.accent })
  hi("BlinkCmpKindSnippet", { fg = p.hint })
  hi("BlinkCmpKindColor", { fg = p.accent })
  hi("BlinkCmpKindFile", { fg = p.text_muted })
  hi("BlinkCmpKindReference", { fg = p.info })
  hi("BlinkCmpKindFolder", { fg = p.text_muted })
  hi("BlinkCmpKindEnumMember", { fg = p.cyan })
  hi("BlinkCmpKindConstant", { fg = p.cyan })
  hi("BlinkCmpKindStruct", { fg = p.text_heading })
  hi("BlinkCmpKindEvent", { fg = p.warning })
  hi("BlinkCmpKindOperator", { fg = p.text_muted })
  hi("BlinkCmpKindTypeParameter", { fg = p.text_heading })
  hi("BlinkCmpDoc", { fg = p.text_body, bg = p.black_surface })
  hi("BlinkCmpDocBorder", { fg = p.black_border, bg = p.black_surface })
  hi("BlinkCmpDocSeparator", { fg = p.black_border })
  hi("BlinkCmpDocCursorLine", { bg = p.black_highlight })
  hi("BlinkCmpSignatureHelp", { fg = p.text_body, bg = p.black_surface })
  hi("BlinkCmpSignatureHelpBorder", { fg = p.black_border, bg = p.black_surface })
  hi("BlinkCmpSignatureHelpActiveParameter", { fg = p.accent, bold = true })
  hi("BlinkCmpGhostText", { fg = p.text_invisible })

  hi("FlashBackdrop", { fg = p.text_disabled })
  hi("FlashMatch", { fg = p.black_deep, bg = p.accent_glow })
  hi("FlashCurrent", { fg = p.black_deep, bg = p.accent, bold = true })
  hi("FlashLabel", { fg = p.black_deep, bg = p.accent, bold = true })
  hi("FlashPrompt", { fg = p.accent, bg = p.black_deep })
  hi("FlashPromptIcon", { fg = p.accent })
  hi("FlashCursor", { fg = p.black_deep, bg = p.accent })

  hi("TinyInlineDiagnosticVirtualTextError", { fg = p.error, bg = p.black_surface })
  hi("TinyInlineDiagnosticVirtualTextWarn", { fg = p.warning, bg = p.black_surface })
  hi("TinyInlineDiagnosticVirtualTextInfo", { fg = p.info, bg = p.black_surface })
  hi("TinyInlineDiagnosticVirtualTextHint", { fg = p.hint, bg = p.black_surface })
  hi("TinyInlineDiagnosticVirtualTextOk", { fg = p.success, bg = p.black_surface })

  hi("GitSignsAdd", { fg = p.success })
  hi("GitSignsChange", { fg = p.warning })
  hi("GitSignsDelete", { fg = p.error })
  hi("GitSignsAddNr", { fg = p.success })
  hi("GitSignsChangeNr", { fg = p.warning })
  hi("GitSignsDeleteNr", { fg = p.error })
  hi("GitSignsAddLn", { bg = p.black_surface })
  hi("GitSignsChangeLn", { bg = p.black_surface })
  hi("GitSignsDeleteLn", { bg = p.black_surface })
  hi("GitSignsCurrentLineBlame", { fg = p.text_invisible, italic = true })

  hi("CopilotSuggestion", { fg = p.text_invisible, italic = true })
  hi("CopilotAnnotation", { fg = p.text_invisible, italic = true })
  hi("FloatBorder", { fg = p.black_border, bg = p.black_surface })
  hi("FloatTitle", { fg = p.accent, bg = p.black_surface, bold = true })
  hi("FloatFooter", { fg = p.text_disabled, bg = p.black_surface })
  hi("healthError", { fg = p.error })
  hi("healthSuccess", { fg = p.success })
  hi("healthWarning", { fg = p.warning })
end

load_black_pink()

require("auto-save").setup({
  debounce_delay = 500,
  execution_message = {
    message = function()
      return ""
    end,
  },
})

require("tiny-inline-diagnostic").setup()
vim.diagnostic.config({ virtual_text = false })

require("flash").setup({})

require("nvim-tree").setup({
  on_attach = function(bufnr)
    local api = require("nvim-tree.api")
    api.config.mappings.default_on_attach(bufnr)

    vim.keymap.set("n", "<LeftRelease>", function()
      local node = api.tree.get_node_under_cursor()
      if node then
        api.node.open.edit()
      end
    end, { buffer = bufnr, noremap = true, silent = true, nowait = true })
  end,
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

require("blink.cmp").setup({
  keymap = { preset = "enter" },
  appearance = {
    use_nvim_cmp_as_default = true,
    nerd_font_variant = "mono",
  },
  completion = {
    documentation = { auto_show = true },
  },
  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
  },
  fuzzy = { implementation = "prefer_rust_with_warning" },
})

require("conform").setup({
  format_on_save = {
    timeout_ms = 500,
    lsp_format = "fallback",
  },
})

require("mason").setup({})
require("lazydev").setup({
  library = {
    { path = "${3rd}/luv/library", words = { "vim%.uv" } },
  },
})
require("mason-lspconfig").setup({
  automatic_enable = false,
})

require("lazydev").setup({
  library = {
    { path = "${3rd}/luv/library", words = { "vim%.uv" } },
  },
})

vim.lsp.config("*", {
  capabilities = require("blink.cmp").get_lsp_capabilities(),
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
  callback = function(ev)
    local opts = { buffer = ev.buf }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
  end,
})

for _, server_name in ipairs(require("mason-lspconfig").get_installed_servers()) do
  local ok, err = pcall(vim.lsp.enable, server_name)
  if not ok then
    vim.notify(("Failed to enable LSP server %s: %s"):format(server_name, err), vim.log.levels.WARN)
  end
end
