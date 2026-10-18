-- Подсветка синтаксиса и отступы (R6.12). Список парсеров — строго по
-- ARCHITECTURE.md A.5 («Парсеры treesitter»), не придумываем сверх него.
-- ПРОВЕРИТЬ: branch = "master" — классический API (nvim-treesitter.configs);
-- у проекта есть более новый branch "main" с другим API (без .configs.setup) —
-- не живой проверкой, уточнить на машине при первом :Lazy sync.
return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master",
  build = ":TSUpdate",
  opts = {
    ensure_installed = {
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
    },
    highlight = { enable = true },
    indent = { enable = true },
  },
  config = function(_, opts)
    require("nvim-treesitter.configs").setup(opts)
  end,
}
