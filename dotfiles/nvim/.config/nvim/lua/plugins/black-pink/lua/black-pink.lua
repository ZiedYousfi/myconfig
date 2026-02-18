-- black-pink.nvim — local colorscheme
-- Derived from the Black & Pink style guide

local M = {}

-- ── Palette ──────────────────────────────────────────────────────────────────

local p = {
  -- Backgrounds
  black_deep      = "#000000",
  black_surface   = "#0a0a0a",
  black_raised    = "#111111",
  black_border    = "#1a1a1a",
  black_highlight = "#222222",

  -- Text
  text_heading    = "#f0f2f7",
  text_body       = "#d0d6e0",
  text_muted      = "#a0aabe",
  text_disabled   = "#4a4f5e",
  text_invisible  = "#2a2d36",

  -- Accent — Pink
  accent          = "#ff4ead",
  accent_hover    = "#c02679",
  accent_dim      = "#a0205f",
  accent_soft     = "#1a0810",  -- #ff4ead @ 10% on #000000
  accent_glow     = "#330f22",  -- #ff4ead @ 20% on #000000
  accent_mid      = "#661e45",  -- #ff4ead @ 40% on #000000

  -- Semantic
  success         = "#4ade80",
  success_bright  = "#86efac",
  warning         = "#facc15",
  warning_bright  = "#fde047",
  error           = "#f87171",
  error_bright    = "#fca5a5",
  info            = "#60a5fa",
  info_bright     = "#93c5fd",
  hint            = "#a78bfa",

  -- Extra (ANSI / syntax)
  cyan            = "#22d3ee",
  cyan_bright     = "#67e8f9",
  magenta_bright  = "#ff85c8",

  none            = "NONE",
}

-- ── Helpers ───────────────────────────────────────────────────────────────────

---@param group string
---@param opts table
local function hi(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- ── Setup ─────────────────────────────────────────────────────────────────────

function M.load()
  -- Reset everything
  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
  end
  vim.o.background = "dark"
  vim.g.colors_name = "black-pink"

  -- ── Editor chrome ──────────────────────────────────────────────────────────

  hi("Normal",          { fg = p.text_body,      bg = p.black_deep })
  hi("NormalFloat",     { fg = p.text_body,      bg = p.black_surface })
  hi("NormalNC",        { fg = p.text_body,      bg = p.black_deep })

  hi("ColorColumn",     { bg = p.black_raised })
  hi("Conceal",         { fg = p.text_disabled })
  hi("Cursor",          { fg = p.black_deep,     bg = p.accent })
  hi("lCursor",         { fg = p.black_deep,     bg = p.accent })
  hi("CursorIM",        { fg = p.black_deep,     bg = p.accent })
  hi("CursorLine",      { bg = p.black_raised })
  hi("CursorColumn",    { bg = p.black_raised })
  hi("CursorLineNr",    { fg = p.accent,         bold = true })
  hi("LineNr",          { fg = p.text_disabled })
  hi("LineNrAbove",     { fg = p.text_disabled })
  hi("LineNrBelow",     { fg = p.text_disabled })

  hi("SignColumn",      { fg = p.text_muted,     bg = p.black_deep })
  hi("FoldColumn",      { fg = p.text_disabled,  bg = p.black_deep })
  hi("Folded",          { fg = p.text_muted,     bg = p.black_raised })

  hi("VertSplit",       { fg = p.black_border,   bg = p.black_deep })
  hi("WinSeparator",    { fg = p.black_border,   bg = p.black_deep })

  hi("StatusLine",      { fg = p.text_muted,     bg = p.black_deep })
  hi("StatusLineNC",    { fg = p.text_disabled,  bg = p.black_deep })

  hi("TabLine",         { fg = p.text_muted,     bg = p.black_surface })
  hi("TabLineFill",     { bg = p.black_deep })
  hi("TabLineSel",      { fg = p.text_heading,   bg = p.black_deep,    bold = true })

  hi("Pmenu",           { fg = p.text_body,      bg = p.black_surface })
  hi("PmenuSel",        { fg = p.text_heading,   bg = p.black_highlight })
  hi("PmenuSbar",       { bg = p.black_raised })
  hi("PmenuThumb",      { bg = p.text_disabled })
  hi("PmenuExtra",      { fg = p.text_muted,     bg = p.black_surface })
  hi("PmenuExtraSel",   { fg = p.text_muted,     bg = p.black_highlight })

  hi("Visual",          { bg = p.black_highlight })
  hi("VisualNOS",       { bg = p.black_highlight })

  hi("Search",          { fg = p.black_deep,     bg = p.accent_glow })
  hi("IncSearch",       { fg = p.black_deep,     bg = p.accent_mid })
  hi("CurSearch",       { fg = p.black_deep,     bg = p.accent })
  hi("Substitute",      { fg = p.black_deep,     bg = p.accent })

  hi("MatchParen",      { fg = p.accent,         bold = true,          underline = true })

  hi("NonText",         { fg = p.text_invisible })
  hi("SpecialKey",      { fg = p.text_invisible })
  hi("Whitespace",      { fg = p.text_invisible })
  hi("EndOfBuffer",     { fg = p.black_border })

  hi("Directory",       { fg = p.accent })
  hi("Title",           { fg = p.text_heading,   bold = true })

  hi("WildMenu",        { fg = p.text_heading,   bg = p.black_highlight })

  hi("Question",        { fg = p.info })
  hi("MoreMsg",         { fg = p.success })
  hi("ModeMsg",         { fg = p.accent,         bold = true })
  hi("MsgArea",         { fg = p.text_body })
  hi("MsgSeparator",    { fg = p.black_border,   bg = p.black_deep })

  hi("ErrorMsg",        { fg = p.error,          bold = true })
  hi("WarningMsg",      { fg = p.warning })

  hi("SpellBad",        { undercurl = true,       sp = p.error })
  hi("SpellCap",        { undercurl = true,       sp = p.warning })
  hi("SpellRare",       { undercurl = true,       sp = p.hint })
  hi("SpellLocal",      { undercurl = true,       sp = p.info })

  hi("DiffAdd",         { fg = p.success,         bg = p.black_surface })
  hi("DiffChange",      { fg = p.warning,         bg = p.black_surface })
  hi("DiffDelete",      { fg = p.error,           bg = p.black_surface })
  hi("DiffText",        { fg = p.text_heading,    bg = p.black_raised,  bold = true })
  hi("Added",           { fg = p.success })
  hi("Changed",         { fg = p.warning })
  hi("Removed",         { fg = p.error })

  hi("QuickFixLine",    { fg = p.text_heading,    bg = p.black_highlight })

  -- ── Indent guides (ibl / indent-blankline) ─────────────────────────────────

  hi("IblIndent",       { fg = p.black_border })
  hi("IblScope",        { fg = p.accent_glow })

  -- ── Syntax (classic vim groups) ────────────────────────────────────────────

  hi("Comment",         { fg = p.text_disabled,   italic = true })
  hi("SpecialComment",  { fg = p.text_disabled,   italic = true })

  hi("Constant",        { fg = p.cyan })          -- constants / enums
  hi("String",          { fg = p.success })        -- strings → green
  hi("Character",       { fg = p.success })
  hi("Number",          { fg = p.warning })        -- numbers → yellow
  hi("Boolean",         { fg = p.warning })
  hi("Float",           { fg = p.warning })

  hi("Identifier",      { fg = p.text_body })      -- variables
  hi("Function",        { fg = p.magenta_bright })  -- functions → bright magenta

  hi("Statement",       { fg = p.accent })         -- keywords
  hi("Conditional",     { fg = p.accent })
  hi("Repeat",          { fg = p.accent })
  hi("Label",           { fg = p.accent })
  hi("Operator",        { fg = p.text_muted })
  hi("Keyword",         { fg = p.accent })
  hi("Exception",       { fg = p.accent })

  hi("PreProc",         { fg = p.hint })           -- macros / decorators → purple
  hi("Include",         { fg = p.hint })
  hi("Define",          { fg = p.hint })
  hi("Macro",           { fg = p.hint })
  hi("PreCondit",       { fg = p.hint })

  hi("Type",            { fg = p.text_heading })   -- types / classes → near-white
  hi("StorageClass",    { fg = p.accent })
  hi("Structure",       { fg = p.text_heading })
  hi("Typedef",         { fg = p.text_heading })

  hi("Special",         { fg = p.cyan })
  hi("SpecialChar",     { fg = p.cyan })
  hi("Tag",             { fg = p.accent })
  hi("Delimiter",       { fg = p.text_invisible }) -- punctuation → barely visible
  hi("Debug",           { fg = p.warning })

  hi("Underlined",      { underline = true })
  hi("Bold",            { bold = true })
  hi("Italic",          { italic = true })
  hi("Ignore",          { fg = p.text_invisible })
  hi("Error",           { fg = p.error,           bold = true })
  hi("Todo",            { fg = p.hint,            bold = true })

  -- ── Treesitter ─────────────────────────────────────────────────────────────

  -- Variables & identifiers
  hi("@variable",                   { fg = p.text_body })
  hi("@variable.builtin",           { fg = p.accent,          italic = true })
  hi("@variable.parameter",         { fg = p.text_muted })  -- slightly dimmer
  hi("@variable.member",            { fg = p.text_body })

  -- Constants
  hi("@constant",                   { fg = p.cyan })
  hi("@constant.builtin",           { fg = p.cyan })
  hi("@constant.macro",             { fg = p.hint })

  -- Strings
  hi("@string",                     { fg = p.success })
  hi("@string.regex",               { fg = p.cyan })
  hi("@string.escape",              { fg = p.accent })
  hi("@string.special",             { fg = p.cyan })

  -- Numbers / booleans
  hi("@number",                     { fg = p.warning })
  hi("@number.float",               { fg = p.warning })
  hi("@boolean",                    { fg = p.warning })

  -- Functions
  hi("@function",                   { fg = p.magenta_bright })
  hi("@function.builtin",           { fg = p.magenta_bright })
  hi("@function.call",              { fg = p.magenta_bright })
  hi("@function.macro",             { fg = p.hint })
  hi("@function.method",            { fg = p.magenta_bright })
  hi("@function.method.call",       { fg = p.magenta_bright })
  hi("@constructor",                { fg = p.text_heading })

  -- Keywords
  hi("@keyword",                    { fg = p.accent })
  hi("@keyword.function",           { fg = p.accent })
  hi("@keyword.operator",           { fg = p.accent })
  hi("@keyword.return",             { fg = p.accent })
  hi("@keyword.import",             { fg = p.hint })
  hi("@keyword.modifier",           { fg = p.accent })
  hi("@keyword.type",               { fg = p.accent })
  hi("@keyword.conditional",        { fg = p.accent })
  hi("@keyword.conditional.ternary",{ fg = p.accent })
  hi("@keyword.repeat",             { fg = p.accent })
  hi("@keyword.exception",          { fg = p.accent })
  hi("@keyword.coroutine",          { fg = p.accent })
  hi("@keyword.debug",              { fg = p.warning })
  hi("@keyword.directive",          { fg = p.hint })
  hi("@keyword.directive.define",   { fg = p.hint })

  -- Types
  hi("@type",                       { fg = p.text_heading })
  hi("@type.builtin",               { fg = p.text_heading })
  hi("@type.definition",            { fg = p.text_heading })
  hi("@type.qualifier",             { fg = p.accent })
  hi("@attribute",                  { fg = p.hint })
  hi("@attribute.builtin",          { fg = p.hint })
  hi("@property",                   { fg = p.text_body })

  -- Operators & punctuation
  hi("@operator",                   { fg = p.text_muted })
  hi("@punctuation.delimiter",      { fg = p.text_invisible })
  hi("@punctuation.bracket",        { fg = p.text_invisible })
  hi("@punctuation.special",        { fg = p.text_muted })

  -- Comments
  hi("@comment",                    { fg = p.text_disabled,    italic = true })
  hi("@comment.documentation",      { fg = p.text_disabled,    italic = true })
  hi("@comment.error",              { fg = p.error,            bold = true })
  hi("@comment.warning",            { fg = p.warning,          bold = true })
  hi("@comment.note",               { fg = p.info,             bold = true })
  hi("@comment.todo",               { fg = p.hint,             bold = true })

  -- Markup (markdown, rst…)
  hi("@markup.heading",             { fg = p.text_heading,     bold = true })
  hi("@markup.heading.1",           { fg = p.accent,           bold = true })
  hi("@markup.heading.2",           { fg = p.accent,           bold = true })
  hi("@markup.heading.3",           { fg = p.magenta_bright,   bold = true })
  hi("@markup.heading.4",           { fg = p.magenta_bright })
  hi("@markup.heading.5",           { fg = p.text_heading })
  hi("@markup.heading.6",           { fg = p.text_muted })
  hi("@markup.raw",                 { fg = p.text_heading,     bg = p.black_surface })
  hi("@markup.raw.block",           { fg = p.text_heading,     bg = p.black_surface })
  hi("@markup.link",                { fg = p.accent,           underline = true })
  hi("@markup.link.label",          { fg = p.info })
  hi("@markup.link.url",            { fg = p.accent_dim,       underline = true })
  hi("@markup.italic",              { italic = true })
  hi("@markup.strong",              { bold = true })
  hi("@markup.strikethrough",       { strikethrough = true })
  hi("@markup.quote",               { fg = p.text_muted,       italic = true })
  hi("@markup.list",                { fg = p.accent })
  hi("@markup.list.checked",        { fg = p.success })
  hi("@markup.list.unchecked",      { fg = p.text_disabled })

  hi("@tag",                        { fg = p.accent })
  hi("@tag.builtin",                { fg = p.accent })
  hi("@tag.attribute",              { fg = p.text_muted })
  hi("@tag.delimiter",              { fg = p.text_invisible })

  -- Module / namespace
  hi("@module",                     { fg = p.text_heading })
  hi("@module.builtin",             { fg = p.text_heading })
  hi("@label",                      { fg = p.accent })

  -- ── LSP semantic tokens ────────────────────────────────────────────────────

  hi("@lsp.type.class",             { fg = p.text_heading })
  hi("@lsp.type.decorator",         { fg = p.hint })
  hi("@lsp.type.enum",              { fg = p.cyan })
  hi("@lsp.type.enumMember",        { fg = p.cyan })
  hi("@lsp.type.function",          { fg = p.magenta_bright })
  hi("@lsp.type.interface",         { fg = p.text_heading })
  hi("@lsp.type.macro",             { fg = p.hint })
  hi("@lsp.type.method",            { fg = p.magenta_bright })
  hi("@lsp.type.namespace",         { fg = p.text_heading })
  hi("@lsp.type.parameter",         { fg = p.text_muted })
  hi("@lsp.type.property",          { fg = p.text_body })
  hi("@lsp.type.struct",            { fg = p.text_heading })
  hi("@lsp.type.type",              { fg = p.text_heading })
  hi("@lsp.type.typeParameter",     { fg = p.text_heading })
  hi("@lsp.type.variable",          { fg = p.text_body })
  hi("@lsp.type.keyword",           { fg = p.accent })
  hi("@lsp.type.number",            { fg = p.warning })
  hi("@lsp.type.string",            { fg = p.success })
  hi("@lsp.type.operator",          { fg = p.text_muted })
  hi("@lsp.type.comment",           { fg = p.text_disabled,    italic = true })
  hi("@lsp.type.regexp",            { fg = p.cyan })

  hi("@lsp.mod.deprecated",         { strikethrough = true })
  hi("@lsp.mod.readonly",           { fg = p.cyan })
  hi("@lsp.mod.static",             { italic = true })
  hi("@lsp.mod.defaultLibrary",     { fg = p.text_heading })
  hi("@lsp.mod.global",             { fg = p.cyan })

  -- ── LSP diagnostic ────────────────────────────────────────────────────────

  hi("DiagnosticError",             { fg = p.error })
  hi("DiagnosticWarn",              { fg = p.warning })
  hi("DiagnosticInfo",              { fg = p.info })
  hi("DiagnosticHint",              { fg = p.hint })
  hi("DiagnosticOk",                { fg = p.success })

  hi("DiagnosticVirtualTextError",  { fg = p.error,            bg = p.black_surface, italic = true })
  hi("DiagnosticVirtualTextWarn",   { fg = p.warning,          bg = p.black_surface, italic = true })
  hi("DiagnosticVirtualTextInfo",   { fg = p.info,             bg = p.black_surface, italic = true })
  hi("DiagnosticVirtualTextHint",   { fg = p.hint,             bg = p.black_surface, italic = true })

  hi("DiagnosticUnderlineError",    { underline = true,        sp = p.error })
  hi("DiagnosticUnderlineWarn",     { underline = true,        sp = p.warning })
  hi("DiagnosticUnderlineInfo",     { underline = true,        sp = p.info })
  hi("DiagnosticUnderlineHint",     { underline = true,        sp = p.hint })

  hi("DiagnosticFloatingError",     { fg = p.error })
  hi("DiagnosticFloatingWarn",      { fg = p.warning })
  hi("DiagnosticFloatingInfo",      { fg = p.info })
  hi("DiagnosticFloatingHint",      { fg = p.hint })

  hi("DiagnosticSignError",         { fg = p.error })
  hi("DiagnosticSignWarn",          { fg = p.warning })
  hi("DiagnosticSignInfo",          { fg = p.info })
  hi("DiagnosticSignHint",          { fg = p.hint })

  -- ── LSP reference & code action ───────────────────────────────────────────

  hi("LspReferenceText",            { bg = p.black_highlight })
  hi("LspReferenceRead",            { bg = p.black_highlight })
  hi("LspReferenceWrite",           { bg = p.black_highlight,  bold = true })
  hi("LspInlayHint",                { fg = p.text_invisible,   bg = p.black_surface, italic = true })
  hi("LspCodeLens",                 { fg = p.text_disabled,    italic = true })
  hi("LspCodeLensSeparator",        { fg = p.black_border })
  hi("LspSignatureActiveParameter", { fg = p.accent,           bold = true })

  -- ── Telescope ─────────────────────────────────────────────────────────────

  hi("TelescopeNormal",             { fg = p.text_body,        bg = p.black_surface })
  hi("TelescopeBorder",             { fg = p.black_border,     bg = p.black_surface })
  hi("TelescopePromptNormal",       { fg = p.text_heading,     bg = p.black_raised })
  hi("TelescopePromptBorder",       { fg = p.accent,           bg = p.black_raised })
  hi("TelescopePromptTitle",        { fg = p.black_deep,       bg = p.accent,        bold = true })
  hi("TelescopePreviewTitle",       { fg = p.black_deep,       bg = p.accent })
  hi("TelescopeResultsTitle",       { fg = p.text_disabled,    bg = p.black_surface })
  hi("TelescopePromptPrefix",       { fg = p.accent })
  hi("TelescopeSelectionCaret",     { fg = p.accent })
  hi("TelescopeSelection",          { fg = p.text_heading,     bg = p.black_highlight })
  hi("TelescopeMatching",           { fg = p.accent,           bold = true })
  hi("TelescopeResultsNormal",      { fg = p.text_body,        bg = p.black_surface })
  hi("TelescopePreviewNormal",      { fg = p.text_body,        bg = p.black_surface })

  -- ── nvim-tree ─────────────────────────────────────────────────────────────

  hi("NvimTreeNormal",              { fg = p.text_body,        bg = p.black_surface })
  hi("NvimTreeNormalFloat",         { fg = p.text_body,        bg = p.black_surface })
  hi("NvimTreeEndOfBuffer",         { fg = p.black_surface })
  hi("NvimTreeRootFolder",          { fg = p.accent,           bold = true })
  hi("NvimTreeFolderIcon",          { fg = p.accent })
  hi("NvimTreeFolderName",          { fg = p.text_body })
  hi("NvimTreeOpenedFolderName",    { fg = p.text_heading,     bold = true })
  hi("NvimTreeEmptyFolderName",     { fg = p.text_disabled })
  hi("NvimTreeFileName",            { fg = p.text_body })
  hi("NvimTreeOpenedFile",          { fg = p.accent })
  hi("NvimTreeModifiedFile",        { fg = p.warning })
  hi("NvimTreeExecFile",            { fg = p.success,          bold = true })
  hi("NvimTreeSpecialFile",         { fg = p.hint,             underline = true })
  hi("NvimTreeSymlink",             { fg = p.cyan })
  hi("NvimTreeSymlinkArrow",        { fg = p.text_muted })
  hi("NvimTreeGitDirty",            { fg = p.warning })
  hi("NvimTreeGitStaged",           { fg = p.success })
  hi("NvimTreeGitMerge",            { fg = p.info })
  hi("NvimTreeGitRenamed",          { fg = p.hint })
  hi("NvimTreeGitNew",              { fg = p.success })
  hi("NvimTreeGitDeleted",          { fg = p.error })
  hi("NvimTreeGitIgnored",          { fg = p.text_disabled })
  hi("NvimTreeCursorLine",          { bg = p.black_highlight })
  hi("NvimTreeVertSplit",           { fg = p.black_border,     bg = p.black_surface })
  hi("NvimTreeWindowPicker",        { fg = p.accent,           bg = p.black_raised,  bold = true })
  hi("NvimTreeBookmark",            { fg = p.accent })
  hi("NvimTreeWinSeparator",        { fg = p.black_border,     bg = p.black_surface })
  hi("NvimTreeIndentMarker",        { fg = p.black_border })

  -- ── blink.cmp ─────────────────────────────────────────────────────────────

  hi("BlinkCmpMenu",                { fg = p.text_body,        bg = p.black_surface })
  hi("BlinkCmpMenuBorder",          { fg = p.black_border,     bg = p.black_surface })
  hi("BlinkCmpMenuSelection",       { fg = p.text_heading,     bg = p.black_highlight })
  hi("BlinkCmpScrollBarThumb",      { bg = p.text_disabled })
  hi("BlinkCmpScrollBarGutter",     { bg = p.black_raised })
  hi("BlinkCmpLabel",               { fg = p.text_body })
  hi("BlinkCmpLabelDeprecated",     { fg = p.text_disabled,    strikethrough = true })
  hi("BlinkCmpLabelMatch",          { fg = p.accent,           bold = true })
  hi("BlinkCmpLabelDetail",         { fg = p.text_muted })
  hi("BlinkCmpLabelDescription",    { fg = p.text_disabled })
  hi("BlinkCmpKindText",            { fg = p.text_muted })
  hi("BlinkCmpKindMethod",          { fg = p.magenta_bright })
  hi("BlinkCmpKindFunction",        { fg = p.magenta_bright })
  hi("BlinkCmpKindConstructor",     { fg = p.text_heading })
  hi("BlinkCmpKindField",           { fg = p.text_body })
  hi("BlinkCmpKindVariable",        { fg = p.text_body })
  hi("BlinkCmpKindClass",           { fg = p.text_heading })
  hi("BlinkCmpKindInterface",       { fg = p.text_heading })
  hi("BlinkCmpKindModule",          { fg = p.text_heading })
  hi("BlinkCmpKindProperty",        { fg = p.text_body })
  hi("BlinkCmpKindUnit",            { fg = p.warning })
  hi("BlinkCmpKindValue",           { fg = p.cyan })
  hi("BlinkCmpKindEnum",            { fg = p.cyan })
  hi("BlinkCmpKindKeyword",         { fg = p.accent })
  hi("BlinkCmpKindSnippet",         { fg = p.hint })
  hi("BlinkCmpKindColor",           { fg = p.accent })
  hi("BlinkCmpKindFile",            { fg = p.text_muted })
  hi("BlinkCmpKindReference",       { fg = p.info })
  hi("BlinkCmpKindFolder",          { fg = p.text_muted })
  hi("BlinkCmpKindEnumMember",      { fg = p.cyan })
  hi("BlinkCmpKindConstant",        { fg = p.cyan })
  hi("BlinkCmpKindStruct",          { fg = p.text_heading })
  hi("BlinkCmpKindEvent",           { fg = p.warning })
  hi("BlinkCmpKindOperator",        { fg = p.text_muted })
  hi("BlinkCmpKindTypeParameter",   { fg = p.text_heading })
  hi("BlinkCmpDoc",                 { fg = p.text_body,        bg = p.black_surface })
  hi("BlinkCmpDocBorder",           { fg = p.black_border,     bg = p.black_surface })
  hi("BlinkCmpDocSeparator",        { fg = p.black_border })
  hi("BlinkCmpDocCursorLine",       { bg = p.black_highlight })
  hi("BlinkCmpSignatureHelp",       { fg = p.text_body,        bg = p.black_surface })
  hi("BlinkCmpSignatureHelpBorder", { fg = p.black_border,     bg = p.black_surface })
  hi("BlinkCmpSignatureHelpActiveParameter", { fg = p.accent,  bold = true })
  hi("BlinkCmpGhostText",           { fg = p.text_invisible })

  -- ── Flash.nvim ─────────────────────────────────────────────────────────────

  hi("FlashBackdrop",               { fg = p.text_disabled })
  hi("FlashMatch",                  { fg = p.black_deep,       bg = p.accent_glow })
  hi("FlashCurrent",                { fg = p.black_deep,       bg = p.accent,        bold = true })
  hi("FlashLabel",                  { fg = p.black_deep,       bg = p.accent,        bold = true })
  hi("FlashPrompt",                 { fg = p.accent,           bg = p.black_deep })
  hi("FlashPromptIcon",             { fg = p.accent })
  hi("FlashCursor",                 { fg = p.black_deep,       bg = p.accent })

  -- ── tiny-inline-diagnostic ────────────────────────────────────────────────

  hi("TinyInlineDiagnosticVirtualTextError",  { fg = p.error,   bg = p.black_surface })
  hi("TinyInlineDiagnosticVirtualTextWarn",   { fg = p.warning, bg = p.black_surface })
  hi("TinyInlineDiagnosticVirtualTextInfo",   { fg = p.info,    bg = p.black_surface })
  hi("TinyInlineDiagnosticVirtualTextHint",   { fg = p.hint,    bg = p.black_surface })
  hi("TinyInlineDiagnosticVirtualTextOk",     { fg = p.success, bg = p.black_surface })

  -- ── Git / gitsigns ────────────────────────────────────────────────────────

  hi("GitSignsAdd",                 { fg = p.success })
  hi("GitSignsChange",              { fg = p.warning })
  hi("GitSignsDelete",              { fg = p.error })
  hi("GitSignsAddNr",               { fg = p.success })
  hi("GitSignsChangeNr",            { fg = p.warning })
  hi("GitSignsDeleteNr",            { fg = p.error })
  hi("GitSignsAddLn",               { bg = p.black_surface })
  hi("GitSignsChangeLn",            { bg = p.black_surface })
  hi("GitSignsDeleteLn",            { bg = p.black_surface })
  hi("GitSignsCurrentLineBlame",    { fg = p.text_invisible,   italic = true })

  -- ── Copilot ───────────────────────────────────────────────────────────────

  hi("CopilotSuggestion",           { fg = p.text_invisible,   italic = true })
  hi("CopilotAnnotation",           { fg = p.text_invisible,   italic = true })

  -- ── Floating windows / borders ────────────────────────────────────────────

  hi("FloatBorder",                 { fg = p.black_border,     bg = p.black_surface })
  hi("FloatTitle",                  { fg = p.accent,           bg = p.black_surface, bold = true })
  hi("FloatFooter",                 { fg = p.text_disabled,    bg = p.black_surface })

  -- ── Neovim health ─────────────────────────────────────────────────────────

  hi("healthError",                 { fg = p.error })
  hi("healthSuccess",               { fg = p.success })
  hi("healthWarning",               { fg = p.warning })
end

return M
