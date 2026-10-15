-- Заглушка машинного слоя (DOT-5): мониторы и раскладка клавиатуры для hyprland.lua (DSN-S4).
-- Реальный файл — ~/.config/machine.d/hypr.lua, не коммитится.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

hl.config({
  input = {
    kb_layout = "us",
    kb_options = "grp:alt_shift_toggle",
  },
})
