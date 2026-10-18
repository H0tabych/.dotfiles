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
-- R6.15: `gd` (определение) и `K` (hover) — ПРОВЕРЕНО в runtime Neovim 0.12
-- (lua/vim/_core/defaults.lua) — НЕ входят в стандартные LSP-клавиши (там
-- только grn/gra/grx/grr/gri/grt/gO/<C-S>); добавляем сами, только в буфере
-- с подключённым клиентом (LspAttach), чтобы не трогать `K` (keywordprg) и
-- `gd` (встроенный goto-local-declaration) там, где LSP не подключён.
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

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("lsp-attach-keymaps", { clear = true }),
      callback = function(args)
        local map = function(lhs, rhs, desc)
          vim.keymap.set("n", lhs, rhs, { buffer = args.buf, desc = desc })
        end
        map("gd", vim.lsp.buf.definition, "LSP: go to definition")
        map("gD", vim.lsp.buf.declaration, "LSP: go to declaration")
        map("K", vim.lsp.buf.hover, "LSP: hover")
      end,
    })
  end,
}
