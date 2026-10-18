-- LSP-клиент (R6.12). Серверы — только из глобального запасного набора
-- lsp-global.nix (DEV-1): nixd, clangd, pyright, ruff, lua_ls, bashls.
-- rust_analyzer — ТОЛЬКО если бинарник есть в PATH (DEV-4: приходит из
-- проектного окружения, не глобально) — иначе ссылка на отсутствующий в
-- PATH бинарник (DEV-9).
-- ПРОВЕРЕНО headless-прогоном: установленный nvim-lspconfig (master,
-- 2026-10-18) уже на новом API — `require('lspconfig')[name].setup()`
-- выдаёт deprecation-ошибку (убирается в v3.0.0); используем
-- vim.lsp.config/vim.lsp.enable (:help lspconfig-nvim-0.11) — сам плагин
-- при загрузке регистрирует конфиги известных серверов для этого API.
-- Диагностика — уже существующие группы Diagnostic* из colors/glass-tide.lua,
-- здесь только включение virtual_text/signs, без новых цветов.
return {
  "neovim/nvim-lspconfig",
  config = function()
    local servers = { "nixd", "clangd", "pyright", "ruff", "lua_ls", "bashls" }

    if vim.fn.executable("rust-analyzer") == 1 then
      table.insert(servers, "rust_analyzer")
    end

    -- ПРОВЕРИТЬ: sqlfluff не входит в стандартный набор nvim-lspconfig —
    -- `sqlfluff lsp` заявлен разработчиком, но живым запуском здесь не
    -- подтверждён (нет проекта с sqlfluff на этой машине).
    if vim.fn.executable("sqlfluff") == 1 then
      vim.lsp.config("sqlfluff", {
        cmd = { "sqlfluff", "lsp" },
        filetypes = { "sql" },
      })
      table.insert(servers, "sqlfluff")
    end

    vim.lsp.enable(servers)

    vim.diagnostic.config({
      virtual_text = true,
      signs = true,
      underline = true,
      severity_sort = true,
    })
  end,
}
