-- Подсказчик горячих клавиш (R6.14). Берёт описания из `desc` уже заданных
-- keymap'ов (keymaps.lua, dap.lua) — отдельной регистрации не требует.
-- Свои цвета не нужны: группы WhichKey* по умолчанию линкуются на обычные
-- (Function/Comment/NormalFloat и т. п.), уже заданные в colors/glass-tide.lua.
return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "modern",
  },
}
