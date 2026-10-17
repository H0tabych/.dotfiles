-- hypr/hyprland.lua — портативная часть (DOT-3; DESIGN_SYSTEM.md P.3.1).
-- Значения дизайна — только из theme/effects (сгенерировано, DSN-TOK-8); это
-- основной конфиг Hyprland >= 0.55 (REGISTRY.md), hyprlang больше не используется
-- (откат — тег pre-lua). Монитор-специфичные строки и раскладка — в machine.d
-- (DOT-5): dofile ниже подключает факты хоста, которые собирает nixos-config.
local t = require("theme")
local fx = require("effects")
pcall(dofile, os.getenv("HOME") .. "/.config/machine.d/hypr.lua")

hl.config({
  general = {
    gaps_in = t.gap.inner,
    gaps_out = t.gap.outer,
    border_size = t.border.window,
    layout = "dwindle",
    col = {
      active_border = { colors = { t.rgba("accent", 0.95), t.rgba("accent_warm", 0.95) }, angle = 135 },
      inactive_border = t.rgba("text", 0.06),
    },
  },
  decoration = {
    rounding = t.radius.window,
    rounding_power = 2,
    active_opacity = 1.0,
    inactive_opacity = 1.0,
    dim_inactive = fx.dim,
    dim_strength = t.dim,
    shadow = {
      enabled = fx.shadow,
      range = t.shadow.range,
      render_power = t.shadow.power,
      color = t.argb("crust", t.shadow.active),
      color_inactive = t.argb("crust", t.shadow.inactive),
    },
    blur = {
      enabled = fx.blur,
      size = fx.blur_size,
      passes = fx.blur_passes,
      noise = fx.blur_noise,
      contrast = fx.blur_contrast,
      brightness = fx.blur_brightness,
      vibrancy = fx.blur_vibrancy,
      new_optimizations = true,
      xray = false,
      popups = true,
      ignore_opacity = true,
    },
  },
  animations = { enabled = fx.anim },
  input = {
    follow_mouse = 1,
    sensitivity = 0,
  },
  misc = {
    disable_hyprland_logo = true,
  },
})

hl.curve("glass", { type = "bezier", points = { {0.22, 1.0}, {0.36, 1.0} } })
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 3.0 * fx.k, bezier = "glass", style = "popin 92%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.8 * fx.k, bezier = "glass", style = "popin 92%" })
hl.animation({ leaf = "fade",       enabled = true, speed = 2.5 * fx.k, bezier = "glass" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3.5 * fx.k, bezier = "glass", style = "slidevert" })

-- Стекло поверхностей оболочки (DSN-MAT-7, раздел 8 — панель/лаунчер/уведомления/OSD не исключения)
for _, ns in ipairs({ "waybar", "rofi", "notifications", "swayosd" }) do
  hl.layer_rule({ name = "glass-" .. ns, match = { namespace = "^" .. ns .. "$" }, blur = fx.blur, ignore_alpha = 0.2 })
end

-- Исключения (раздел 8: DSN-EXC-1…DSN-EXC-4)
hl.window_rule({ name = "solid-video",   match = { content = "video" }, no_blur = true, opaque = true, no_dim = true })
hl.window_rule({ name = "solid-game",    match = { content = "game" },  no_blur = true, opaque = true, no_dim = true, no_shadow = true })
hl.window_rule({ name = "solid-content", match = { class = "^(firefox|org\\.telegram\\.desktop|thunderbird|libreoffice-.*|org\\.pwmt\\.zathura|mpv)$" },
                 no_blur = true, opaque = true })
hl.window_rule({ name = "solid-steam",   match = { class = "^(steam|steam_app_.*)$" }, no_blur = true, opaque = true, no_dim = true })
hl.window_rule({ name = "solid-float",   match = { float = true }, no_blur = true })
hl.window_rule({ name = "flat-fullscreen", match = { fullscreen = true }, rounding = 0, border_size = 0 })
-- Профили battery/solid: терминал становится сплошным без перезапуска (DSN-PWR-3)
if fx.terminal_opaque then
  hl.window_rule({ name = "term-opaque", match = { class = "^(foot|footclient)$" }, opaque = true })
end

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("foot"))
hl.bind(mainMod .. " + Q",      hl.dsp.window.close())
hl.bind(mainMod .. " + M",      hl.dsp.exit())
hl.bind(mainMod .. " + Space",  hl.dsp.exec_cmd("rofi -show drun"))
hl.bind(mainMod .. " + V",      hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F",      hl.dsp.window.fullscreen())

-- DSN-PWR-2 (раздел 9, DSN-S7/R6.10): ручной выбор профиля эффектов solid/game;
-- ac/battery переключаются автоматически (effects-profile.nix). Скрипт
-- идемпотентен — повторное нажатие на уже активном профиле ничего не делает.
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("~/.config/hypr/scripts/profile solid"))
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.exec_cmd("~/.config/hypr/scripts/profile game"))

-- 10 рабочих столов, 1..9 затем 0 (DSN-LAY-3: всегда на виду, waybar —
-- persistent-workspaces). Клавиша "0" -> стол 10, как на цифровом ряду клавиатуры.
for i = 1, 9 do
  hl.bind(mainMod .. " + " .. i,         hl.dsp.focus({ workspace = i }))
  hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mainMod .. " + 0",         hl.dsp.focus({ workspace = 10 }))
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- DSN-CMP-9 (screenshot-grim.nix): выделение области + редактор (swappy);
-- Shift+Print — весь экран, тоже в редактор. ПРОВЕРИТЬ (новый пункт I.6,
-- M18): запись без модификатора в hl.bind не сверена по исходникам (во всех
-- остальных биндах этого файла — ровно один модификатор, mainMod); если не
-- сработает — заменить на hyprlang-биндинг ("bind = , Print, exec, …") рядом,
-- hyprlang в 0.55 всё ещё поддерживается (REGISTRY.md).
hl.bind("Print",         hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot --full"))

-- Клавиши громкости (DSN-S5/R6.8, M28): с клавиатуры звук не регулировался —
-- swayosd-libinput-backend ловит только CapsLock/NumLock/ScrollLock (README
-- SwayOSD 0.3.1, раздел "LibInput Backend (Optional)"), громкость он не
-- трогает вовсе; клик по иконке waybar работал отдельно, через свой on-click.
-- Нужны явные биндинги на swayosd-client (как в примерах README для Sway/
-- Hyprland). repeating — повтор при удержании; locked — работает и при
-- активном input-инхибиторе (экран блокировки).
local volOpts = { repeating = true, locked = true }
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise"), volOpts)
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"), volOpts)
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), volOpts)
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"), volOpts)
