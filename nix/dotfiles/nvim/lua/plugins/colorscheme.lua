-- Monokai Classic (placeholder) colorscheme for Neovim
-- Location: setup-config/nix/dotfiles/nvim/lua/plugins/colorscheme.lua
--
-- This is a lightweight, portable Lua colorscheme module intended to be stowed
-- as part of the repository's dotfiles. It applies a small set of highlight
-- groups and terminal colors to approximate the Monokai Classic palette
-- described in SPECS.md.
--
-- Usage:
--   -- from init.lua or plugin loader:
--   require("plugins.colorscheme").setup({
--     bg = "dark" -- or "light" (currently only 'dark' is meaningful)
--   })
--   -- or simply:
--   require("plugins.colorscheme").apply()
--
-- Notes:
-- - This is intentionally minimal and not a full-featured colorscheme. Treat it
--   as a placeholder that follows the repository's visual theme and can be
--   extended later (treesitter groups, LSP semantic tokens, plugin-specific
--   highlights, etc).
-- - Highlights are applied via vim.api.nvim_set_hl so this works with both
--   Neovim init.lua setups and lazy plugin managers.

local M = {}

-- Monokai Classic palette (hex)
local palette = {
    bg         = "#272822", -- background
    fg         = "#f8f8f2", -- foreground
    pink       = "#f92672",
    orange     = "#fd971f",
    yellow     = "#e6db74",
    green      = "#a6e22e",
    cyan       = "#66d9ef",
    purple     = "#ae81ff",
    comment    = "#75715e",
    cursorline = "#3e3d32",
    visual     = "#49483e",
    -- error/warn
    red        = "#f92672",
}

-- Default options
local defaults = {
    bg = "dark", -- 'dark' or 'light'
}

local function hl(group, opts)
    -- opts: table with keys: fg, bg, bold, italic, underline, reverse, nocombine
    vim.api.nvim_set_hl(0, group, opts)
end

local function set_terminal_colors(p)
    -- standard 16 terminal colors (approximate mapping)
    vim.g.terminal_color_0  = p.bg
    vim.g.terminal_color_1  = p.red
    vim.g.terminal_color_2  = p.green
    vim.g.terminal_color_3  = p.yellow
    vim.g.terminal_color_4  = p.pink
    vim.g.terminal_color_5  = p.purple
    vim.g.terminal_color_6  = p.cyan
    vim.g.terminal_color_7  = p.fg
    vim.g.terminal_color_8  = p.comment
    vim.g.terminal_color_9  = p.red
    vim.g.terminal_color_10 = p.green
    vim.g.terminal_color_11 = p.yellow
    vim.g.terminal_color_12 = p.pink
    vim.g.terminal_color_13 = p.purple
    vim.g.terminal_color_14 = p.cyan
    vim.g.terminal_color_15 = p.fg
end

local function apply_highlights(p)
    -- Core UI
    hl("Normal", { fg = p.fg, bg = p.bg })
    hl("CursorLine", { bg = p.cursorline })
    hl("Visual", { bg = p.visual })
    hl("LineNr", { fg = p.comment })
    hl("Comment", { fg = p.comment, italic = true })
    hl("NonText", { fg = p.comment })
    hl("Whitespace", { fg = p.comment })

    -- Syntax groups
    hl("Constant", { fg = p.yellow })
    hl("String", { fg = p.yellow })
    hl("Character", { fg = p.yellow })
    hl("Number", { fg = p.purple })
    hl("Boolean", { fg = p.purple })

    hl("Identifier", { fg = p.green })
    hl("Function", { fg = p.green })
    hl("Statement", { fg = p.pink })
    hl("Conditional", { fg = p.pink })
    hl("Repeat", { fg = p.pink })
    hl("Label", { fg = p.pink })
    hl("Operator", { fg = p.fg })
    hl("Keyword", { fg = p.pink, bold = true })

    hl("PreProc", { fg = p.orange })
    hl("Include", { fg = p.orange })
    hl("Define", { fg = p.orange })
    hl("Macro", { fg = p.orange })

    hl("Type", { fg = p.cyan })
    hl("StorageClass", { fg = p.cyan })
    hl("Structure", { fg = p.cyan })
    hl("Typedef", { fg = p.cyan })

    hl("Special", { fg = p.pink })
    hl("Underlined", { fg = p.cyan, underline = true })

    hl("Error", { fg = p.bg, bg = p.red, bold = true })
    hl("Todo", { fg = p.bg, bg = p.orange, bold = true })

    -- LSP / diagnostic
    hl("DiagnosticError", { fg = p.red })
    hl("DiagnosticWarn", { fg = p.orange })
    hl("DiagnosticInfo", { fg = p.cyan })
    hl("DiagnosticHint", { fg = p.green })

    -- Telescope / plugins (minimal safe defaults)
    hl("TelescopePromptPrefix", { fg = p.pink, bg = p.cursorline })
    hl("TelescopeNormal", { fg = p.fg, bg = p.bg })
    hl("TelescopeSelection", { fg = p.fg, bg = p.visual })

    -- Statusline placeholders
    hl("StatusLine", { fg = p.fg, bg = p.cursorline })
    hl("StatusLineNC", { fg = p.comment, bg = p.bg })
end

-- Public API

-- apply(): immediately apply the colorscheme using the built-in palette.
function M.apply()
    -- set colors_name so plugins can detect active colorscheme
    vim.g.colors_name = "monokai_classic"
    set_terminal_colors(palette)
    apply_highlights(palette)
end

-- setup(opts): optional configuration, future-proofed for overrides
function M.setup(opts)
    opts = opts or {}
    local merged = {}
    for k, v in pairs(defaults) do merged[k] = v end
    for k, v in pairs(opts) do merged[k] = v end

    -- For now we only support 'dark' background; this is a placeholder.
    if merged.bg ~= "dark" then
        -- Could implement a light variant in the future.
        vim.notify("monokai_classic: only 'dark' bg is supported in placeholder; falling back to dark",
            vim.log.levels.WARN)
    end

    -- Apply immediately
    M.apply()
end

-- Convenience: automatically apply when required as a colorscheme (vim.cmd("colorscheme monokai_classic"))
-- Neovim looks for 'colors_name'; the user can call require(...).setup() in their init.lua instead.
return M
