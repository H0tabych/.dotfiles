-- Портативный конфиг neovim (DOT-3). Без менеджера плагинов — минимальная
-- рабочая база; добавление плагинов — отдельно, с lock-файлом (DOT-11, REGISTRY.md).
require("options")
require("keymaps")

local colors = require("colors")
vim.api.nvim_set_hl(0, "Normal", { fg = colors.foreground, bg = colors.background })
vim.api.nvim_set_hl(0, "CursorLine", { bg = colors.black })
vim.api.nvim_set_hl(0, "Visual", { bg = colors.accent, fg = colors.background })
vim.api.nvim_set_hl(0, "Comment", { fg = colors.bright_black, italic = true })
vim.api.nvim_set_hl(0, "Pmenu", { fg = colors.foreground, bg = colors.black })
vim.api.nvim_set_hl(0, "PmenuSel", { fg = colors.background, bg = colors.accent })
