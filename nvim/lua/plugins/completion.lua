-- Автодополнение (R6.12). blink.cmp — без зависимости от внешнего сборщика
-- сниппетов; витрина берёт Pmenu/PmenuSel из colors/glass-tide.lua, своих
-- цветов здесь не задаём.
return {
  "saghen/blink.cmp",
  version = "*",
  opts = {
    keymap = { preset = "default" },
    appearance = { nerd_font_variant = "mono" },
    sources = { default = { "lsp", "path", "buffer" } },
  },
}
