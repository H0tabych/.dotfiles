-- Подсветка синтаксиса и отступы (R6.12). Список парсеров — строго по
-- ARCHITECTURE.md A.5 («Парсеры treesitter»), не придумываем сверх него.
-- ПРОВЕРЕНО живьём: branch = "master" заморожена проектом и совместима
-- только с Neovim ≤0.11 (их README); на Neovim 0.12.4 она ломается при
-- разборе инъекций markdown (nil-узел в languagetree.lua). branch = "main" —
-- единственная, рассчитанная на 0.12+; API другой: без .configs.setup,
-- подсветка/отступы включаются вручную через vim.treesitter.start().
local parsers = {
  "rust",
  "c",
  "cpp",
  "python",
  "sql",
  "nix",
  "lua",
  "bash",
  "toml",
  "yaml",
  "json",
  "markdown",
  "markdown_inline",
}

-- Типы файлов для автокоманды: совпадают с парсерами, кроме markdown_inline
-- (не самостоятельный filetype, подключается инъекцией из markdown) и bash
-- (filetype у shell-скриптов — "sh", парсер для него — "bash").
local filetypes = {
  "rust",
  "c",
  "cpp",
  "python",
  "sql",
  "nix",
  "lua",
  "sh",
  "bash",
  "toml",
  "yaml",
  "json",
  "markdown",
}

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").install(parsers)

    vim.api.nvim_create_autocmd("FileType", {
      pattern = filetypes,
      callback = function()
        vim.treesitter.start()
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}
