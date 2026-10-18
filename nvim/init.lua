-- Портативный конфиг neovim (DOT-3, R6.12). Менеджер плагинов — lazy.nvim
-- (nvim/lua/plugins/), lock-файл nvim/lazy-lock.json (DOT-11, REGISTRY.md).
require("options")
require("keymaps")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = { { import = "plugins" } },
  install = { colorscheme = { "glass-tide" } },
  checker = { enabled = false },
})

-- Полная раскладка (floating/diagnostics/статусная капсула, DESIGN_SYSTEM.md
-- P.3.5) — DSN-S6/R6.9: colors/glass-tide.lua + lua/statusline.lua.
vim.cmd.colorscheme("glass-tide")
require("statusline").setup()
