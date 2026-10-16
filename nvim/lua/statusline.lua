-- Статусная строка: капсула режима (DESIGN_SYSTEM.md P.3.5, DSN-S6/R6.9).
-- Цвета — highlight-группы GlassTideMode*/GlassTideStatusLine из колорсхемы
-- glass-tide (nvim/colors/glass-tide.lua); здесь только раскладка, не роли.
local M = {}

local MODE_GROUP = {
  n = "GlassTideModeNormal",
  no = "GlassTideModeNormal",
  nt = "GlassTideModeNormal",
  i = "GlassTideModeInsert",
  ic = "GlassTideModeInsert",
  v = "GlassTideModeVisual",
  V = "GlassTideModeVisual",
  [""] = "GlassTideModeVisual",
  R = "GlassTideModeReplace",
  Rv = "GlassTideModeReplace",
  c = "GlassTideModeCommand",
}

local MODE_LABEL = {
  n = "NORMAL",
  i = "INSERT",
  v = "VISUAL",
  V = "V-LINE",
  [""] = "V-BLOCK",
  R = "REPLACE",
  c = "COMMAND",
}

function M.render()
  local m = vim.fn.mode()
  local group = MODE_GROUP[m] or "GlassTideModeNormal"
  local label = MODE_LABEL[m] or m:upper()
  return table.concat({
    string.format("%%#%s# %s %%#GlassTideStatusLine#", group, label),
    " %f%m%r",
    "%=",
    "%y %l:%c %P ",
  })
end

function M.setup()
  vim.o.statusline = "%!v:lua.require'statusline'.render()"
end

return M
