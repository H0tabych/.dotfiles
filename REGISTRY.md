# Реестр портативных приложений (DOT-2)

Добавление приложения сюда = запись в таблицу + ADR-lite (краткая причина строкой в «Заметка»).
Приложение вне этого реестра конфигурируется Nix (DOT-2).

| Приложение | Каталог | Целевой путь (`~/.config/...`) | Версия/заметка | Проверка |
|---|---|---|---|---|
| neovim | `nvim/` | `nvim/` | без менеджера плагинов пока (lock-файл — после первой реальной настройки, DOT-11) | `nvim --headless -c 'quit'` без ошибок |
| zsh | `zsh/` | `zsh/` (требует `ZDOTDIR=~/.config/zsh`, задаёт Nix) | — | `zsh -n .zshrc` |
| starship | `starship/` | `starship/` (требует `STARSHIP_CONFIG=~/.config/starship/starship.toml`, задаёт Nix — DOT-12) | новая запись реестра (DSN-S6, R6.9); целевая версия 1.25; `starship-lite.toml` — без статуса VCS, подключается `.envrc` репозитория для больших деревьев (DESIGN_SYSTEM.md Приложение I.7) | `starship --version` + `starship explain` с принятым конфигом |
| foot | `foot/` | `foot/` | `include=` в `foot.ini` — foot ≥ 1.14 | `foot --check-config` |
| hypr | `hypr/` | `hypr/` | Hyprland ≥ 0.55: основной конфиг — Lua (`hyprland.lua`, `theme.lua`, `effects.lua`), hyprlang ещё поддерживается; тег `pre-lua` перед переходом (DSN-S4); `effects.lua` — симлинк на профиль (DSN-S7, R6.10), переставляет `hypr/scripts/profile` | `hyprctl` при живой сессии (ручная проверка) |
| waybar | `waybar/` | `waybar/` | — | `waybar -c config.jsonc -s style.css --log-level error` недолгий запуск |
| rofi | `rofi/` | `rofi/` | — | `rofi -dump-config` после `-config config.rasi` |
| mako | `mako/` | `mako/` | цвета + статика вместе (`theme/gen/templates/mako-config.tmpl`); `config` — симлинк на профиль (DSN-S7, R6.10), переставляет `hypr/scripts/profile` | `makoctl reload` при живой сессии |
| swayosd | `swayosd/` | `swayosd/` | новая запись реестра (DSN-S5, R6.8); `style.css` — статика с `@import url("theme.css")`, сам `theme.css` — симлинк на профиль (генератор/переключатель) | визуально при живой сессии (громкость/яркость/caps lock) |
| yazi | `yazi/` | `yazi/` | — | `yazi --version` + ручной запуск |
| mpv | `mpv/` | `mpv/` | тема (DSN-CMP-19, R7.2): `theme.conf` из генератора, `include=` в `mpv.conf`; `hwdec=vaapi`/`vaapi-device` на iGPU (APP-3) — в nixos-config (`video-player-mpv`) | `mpv --no-config --show-profile=default` не применимо; визуальная проверка (OSD в цвете `accent`, фон `mantle`) |
| git | `git/` | `git/` (файл `config`, не `gitconfig`) | identity — только через `machine.d/git-identity` (SEC-10) | `git config --list` без личной почты в выводе из репозитория |
| mangohud | `mangohud/` | **`MangoHud/`** (нестандартный регистр каталога у самого приложения) | — | `mangohud --dlsym true glxgears` (ручная проверка) |
| zathura | `zathura/` | `zathura/` | новая запись реестра (DSN-S9, R7.1); `zathurarc` — цвета из генератора, не зависит от профиля эффектов (DSN-CMP-18); `recolor` выключен по умолчанию, клавиша `R` переключает | `zathura --version` + визуальная проверка (тёмный UI, белая страница, `R` перекрашивает) |

## Палитра

Дизайн-система Glass Tide (`docs/architecture/DESIGN_SYSTEM.md` в nixos-config,
ADR-36). `theme/palette.toml` — единственный источник токенов (роли цвета,
варианты, альфы, шрифты, форма, движение; схема — Приложение S.1 документа);
`theme/gen/gen.py` (только стандартная библиотека Python) перегенерирует
`colors.*`/`theme.conf`/`config`/`theme.toml` во всех каталогах выше —
`gen.py` без флагов для активного варианта (профиль `ac`), `gen.py --check`
только проверяет (DSN-A1/A2: контраст DSN-COL-4 по обоим вариантам, схема,
монотонность, литералы — без записи файлов). После правки палитры —
обязательно перезапустить генератор и закоммитить результат вместе с
сгенерированными файлами (DOT-9); CI гоняет и `--check`, и сверку `git diff`.

Контрольные точки `probe` в `theme/palette.toml` пересчитывает отдельно
`theme/gen/probe.py` (требует Pillow/numpy — не входит в stdlib, поэтому вне
`gen.py`): запускается вручную при смене файла обоев в `theme/wallpapers/`,
результат копируется в `palette.toml` руками.

Статус (DSN-S2, 2026-10-14): генератор и 7 ранее существовавших потребителей
переведены на новую схему токенов. DSN-S4 (R6.7, 2026-10-15) добавил
Lua-композитор (`hypr/theme.lua`, `hypr/effects.lua`, только профиль `ac`).
DSN-S5 (R6.8): добавлены SwayOSD, `hypr/theme.conf` (роли для hyprlock) и
`hypr/hyprpaper.conf` (обои варианта, не зависят от профиля — L6, раздел 2.1
документа); waybar/rofi/swayosd теперь генерируют per-profile файл
`theme-<профиль>.<ext>` + симлинк `theme.<ext>` без суффикса на только что
сгенерированный профиль (переставляет его сам переключатель — DSN-S7/R6.10).
DSN-S6 (R6.9): добавлен starship (`starship/starship.toml`,
`starship/starship-lite.toml` — без профильного варианта, см. запись выше) и
исправлены секции `yazi/theme.toml` под 26.5.6 (`[mgr]`/`[indicator]`/
`[tabs]`/`[mode]` вместо `[manager]` с вложенными `tab_*`/`mode_*` —
`[cmp]`/`[notify]`/`[filetype]`/`[icon]` не добавлены, схема полей не
подтверждена, ПРОВЕРИТЬ визуально). DSN-S7 (R6.10): `hypr/effects.lua` и
`mako/config` тоже переведены на per-profile файл + симлинк (как
waybar/rofi/swayosd); генератор пишет файлы всех четырёх профилей
(`ac`/`battery`/`solid`/`game`) за один прогон; появился сам переключатель —
скрипт `hypr/scripts/profile` (DESK-9), переставляющий все пять симлинков и
перезагружающий компоненты (`hyprctl reload`, `pkill -SIGUSR2 waybar`,
`makoctl reload`); состояние — `$XDG_STATE_HOME/glass-tide/profile`
(DSN-PWR-7). Остальные потребители (qt6ct — частично DSN-S3, sddm-astronaut)
— следующий шаг (DSN-S8, DESIGN_SYSTEM.md Приложение I.4). DSN-S9/R7.1:
добавлены `zathura/zathurarc` (PLAIN_DEST, см. запись выше) и
`theme/export/glass-tide-<вариант>.tdesktop-theme` — ZIP для разового
ручного импорта в Telegram Desktop (DSN-CMP-17), имена ключей палитры
Telegram — `ПРОВЕРИТЬ` вживую (Приложение I.6, M5). DSN-S9/R7.2: добавлен
`mpv/theme.conf` (PLAIN_DEST, см. запись выше) — альфа фона OSD фиксирована
генератором (0.90), не хранится в `palette.toml`.

## Машинный слой

`machine.d.example/` — заглушки для `~/.config/machine.d/*`, который создаёт Nix/`install.sh`
и который не коммитится (DOT-5). Сейчас используется для: `git-identity` (имя/почта, SEC-10),
`zsh-env` (переменные окружения шелла), `hypr-monitors.conf` (описание мониторов),
`hypr-input.conf` (раскладка клавиатуры, DESK-7), `hypr.lua` (те же факты в
формате Lua для `hyprland.lua`, DSN-S4).

## Статус

Это **стартовые** конфиги (R4.1, созданы без исходника — старой рабочей копии не было).
Минимальный рабочий набор, без личных привычек/плагинов — донастройка далее не входит в R4.1.
