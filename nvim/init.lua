-- Портативный конфиг neovim (DOT-3). Без менеджера плагинов — минимальная
-- рабочая база; добавление плагинов — отдельно, с lock-файлом (DOT-11, REGISTRY.md).
require("options")
require("keymaps")

-- Полная раскладка (floating/diagnostics/статусная капсула, DESIGN_SYSTEM.md
-- P.3.5) — DSN-S6/R6.9: colors/glass-tide.lua + lua/statusline.lua.
vim.cmd.colorscheme("glass-tide")
require("statusline").setup()
