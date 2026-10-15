-- Сгенерировано theme/gen/gen.py из theme/palette.toml (вариант tree, профиль ac) — не редактируйте
-- require("theme") (DESIGN_SYSTEM.md P.3.1): роли цвета и геометрия для hyprland.lua.
local M = {}

M.c = {
  crust       = "070D12",
  mantle      = "0A141B",
  base        = "0E1A22",
  surface0    = "16252F",
  surface1    = "1F313D",
  surface2    = "2A3F4D",
  overlay0    = "4A6070",
  overlay1    = "839AA5",
  subtext0    = "A6B7BF",
  subtext1    = "BECAD0",
  text        = "DCE7EC",
  accent      = "7FD6B0",
  accent_warm = "F2A988",
  on_accent   = "070D12",
  success     = "B5DB86",
  warning     = "F0B86E",
  error       = "F0817F",
  info        = "7AAEEA",
  special     = "B49AE8",
  teal        = "6CCFCB",
}

local function alpha_hex(a)
  return string.format("%02x", math.floor(a * 255 + 0.5))
end

-- "rgba(RRGGBBAA)" — формат hyprlang-строки цвета (general.col.*, см. пример пакета).
function M.rgba(role, a)
  return "rgba(" .. M.c[role] .. alpha_hex(a) .. ")"
end

-- 0xAARRGGBB — целое число, формат decoration.shadow.color (см. example/hyprland.lua).
function M.argb(role, a)
  return tonumber(alpha_hex(a) .. M.c[role], 16)
end

M.gap = { inner = 6, outer = 12 }
M.border = { window = 2, rim = 1 }
M.radius = { window = 12 }
M.shadow = { range = 20, power = 3, active = 0.55, inactive = 0.3 }
M.dim = 0.08

return M
