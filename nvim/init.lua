-- Портативный конфиг neovim (DOT-3). Без менеджера плагинов — минимальная
-- рабочая база; добавление плагинов — отдельно, с lock-файлом (DOT-11, REGISTRY.md).
require("options")
require("keymaps")

-- Полная раскладка (floating/diagnostics/статусная капсула по DESIGN_SYSTEM.md
-- P.3.5, DSN-CMP-13) — шаг DSN-S6; здесь только перевод на роли палитры.
local colors = require("colors")
vim.api.nvim_set_hl(0, "Normal", { fg = colors.text, bg = colors.base })
vim.api.nvim_set_hl(0, "CursorLine", { bg = colors.surface1 })
vim.api.nvim_set_hl(0, "Visual", { bg = colors.accent, fg = colors.base })
vim.api.nvim_set_hl(0, "Comment", { fg = colors.overlay1, italic = true })
vim.api.nvim_set_hl(0, "Pmenu", { fg = colors.text, bg = colors.surface1 })
vim.api.nvim_set_hl(0, "PmenuSel", { fg = colors.base, bg = colors.accent })
