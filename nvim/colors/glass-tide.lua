-- Колорсхема Glass Tide (DOT-3, портативно — статика, не генератор).
-- Читает сгенерированную таблицу nvim/lua/colors.lua (DOT-9, theme/gen/gen.py);
-- сама раскладка highlight-групп — здесь, вручную, по DESIGN_SYSTEM.md P.3.5.

if vim.g.colors_name then
  vim.cmd("hi clear")
end
vim.o.termguicolors = true
vim.g.colors_name = "glass-tide"

local colors = require("colors")

local function hl(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- Окно terminal-эмулятора (foot) уже полупрозрачное — фон Neovim остаётся
-- NONE, иначе глазс-тайд теряется за сплошной заливкой (P.3.5).
hl("Normal", { fg = colors.text, bg = "NONE" })
hl("NormalNC", { fg = colors.text, bg = "NONE" })
hl("SignColumn", { bg = "NONE" })
hl("EndOfBuffer", { fg = colors.surface1, bg = "NONE" })

hl("NormalFloat", { fg = colors.text, bg = colors.surface0 })
hl("FloatBorder", { fg = colors.surface1, bg = colors.surface0 })
hl("Pmenu", { fg = colors.text, bg = colors.surface0 })
hl("PmenuSel", { fg = colors.base, bg = colors.accent })
hl("PmenuSbar", { bg = colors.surface0 })
hl("PmenuThumb", { bg = colors.surface2 })

hl("CursorLine", { bg = colors.surface1 })
hl("CursorLineNr", { fg = colors.accent, bold = true })
hl("LineNr", { fg = colors.overlay0 })
hl("Visual", { bg = colors.surface2 })
hl("Search", { fg = colors.base, bg = colors.warning })
hl("IncSearch", { fg = colors.base, bg = colors.accent })

hl("Comment", { fg = colors.overlay1, italic = true })

-- Синтаксис кода (R6.13, ПРОВЕРЕНО живьём: без этого блока treesitter/regex
-- подсветка исправно работает, но берёт цвета встроенной темы Neovim по
-- умолчанию, не из палитры — classic-группы ниже покрывают оба механизма:
-- `@capture` линкуются на них по умолчанию (`@keyword` -> Keyword и т. п.,
-- ПРОВЕРЕНО `nvim_get_hl`), поэтому отдельные `@`-группы не нужны.
hl("Keyword", { fg = colors.accent, bold = true })
hl("Statement", { fg = colors.accent, bold = true })
hl("Conditional", { fg = colors.accent })
hl("Repeat", { fg = colors.accent })
hl("Label", { fg = colors.accent })
hl("Exception", { fg = colors.accent, bold = true })

hl("String", { fg = colors.success })
hl("Character", { fg = colors.success })

hl("Number", { fg = colors.accent_warm })
hl("Float", { fg = colors.accent_warm })
hl("Boolean", { fg = colors.accent_warm, bold = true })

hl("Function", { fg = colors.info })
hl("Identifier", { fg = colors.text })
hl("Variable", { fg = colors.text })

hl("Type", { fg = colors.teal })
hl("StorageClass", { fg = colors.teal })
hl("Structure", { fg = colors.teal })

hl("Constant", { fg = colors.special })
hl("Operator", { fg = colors.subtext1 })
hl("Delimiter", { fg = colors.subtext1 })
hl("Special", { fg = colors.special })

hl("PreProc", { fg = colors.warning })
hl("Macro", { fg = colors.warning })
hl("Define", { fg = colors.warning })

hl("Todo", { fg = colors.warning, bold = true })
hl("Error", { fg = colors.error, bold = true })

hl("WinSeparator", { fg = colors.surface1 })
hl("StatusLine", { fg = colors.text, bg = colors.surface1 })
hl("StatusLineNC", { fg = colors.overlay1, bg = colors.surface0 })

-- Диагностика — семантика и знаки (DESIGN_SYSTEM.md P.3.5).
local diagnostics = {
  Error = colors.error,
  Warn = colors.warning,
  Info = colors.info,
  Hint = colors.teal,
  Ok = colors.success,
}
for name, color in pairs(diagnostics) do
  hl("Diagnostic" .. name, { fg = color })
  hl("DiagnosticSign" .. name, { fg = color })
  hl("DiagnosticUnderline" .. name, { undercurl = true, sp = color })
  hl("DiagnosticVirtualText" .. name, { fg = color, bg = colors.surface0 })
end

-- Капсула режима в статусной строке (DSN-S6/R6.9, статусная строка —
-- nvim/lua/statusline.lua): accent/success/special/warning/info по режиму,
-- три из них (accent/warning/special) требует DESIGN_SYSTEM.md P.3.5.
hl("GlassTideModeNormal", { fg = colors.base, bg = colors.accent, bold = true })
hl("GlassTideModeInsert", { fg = colors.base, bg = colors.success, bold = true })
hl("GlassTideModeVisual", { fg = colors.base, bg = colors.special, bold = true })
hl("GlassTideModeReplace", { fg = colors.base, bg = colors.warning, bold = true })
hl("GlassTideModeCommand", { fg = colors.base, bg = colors.info, bold = true })
hl("GlassTideStatusLine", { fg = colors.text, bg = colors.surface1 })
