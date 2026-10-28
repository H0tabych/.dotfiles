# Реестр портативных приложений (DOT-2)

Добавление приложения сюда = запись в таблицу + ADR-lite (краткая причина строкой в «Заметка»).
Приложение вне этого реестра конфигурируется Nix (DOT-2).

| Приложение | Каталог | Целевой путь (`~/.config/...`) | Версия/заметка | Проверка |
|---|---|---|---|---|
| neovim | `nvim/` | `nvim/` | R6.12: lazy.nvim (`nvim/lua/plugins/`, lock-файл `nvim/lazy-lock.json`, DOT-11) — treesitter, nvim-lspconfig (на LSP из `lsp-global.nix`), blink.cmp, nvim-dap/nvim-dap-ui (адаптеры `debugpy-adapter`/`lldb-dap`, оба из `lsp-global.nix`); R6.12 исправление — classic-группы синтаксиса в `colors/glass-tide.lua` (treesitter брал цвета встроенной темы Neovim, не палитру); R6.14 — which-key.nvim (подсказчик горячих клавиш, берёт `desc` уже заданных keymap'ов, явная группа `<leader>d`); R6.15 — запуск отладки в общем виде (файл/модуль/аргументы/cwd — спрашиваются при каждом запуске, не привязаны к одному файлу), `gd`/`gD`/`K` (LSP definition/declaration/hover — ПРОВЕРЕНО: НЕ входят в стандартные клавиши Neovim 0.12, добавлены через LspAttach); R8.4 (`nvim/lua/plugins/ai.lua`, AI_SUBSYSTEM.md §3.2) — minuet-ai.nvim (FIM через `openai_fim_compatible` на Ollama, virtual text, `notify = false` — AI-CMP-3) и codecompanion.nvim (чат/инлайн, адаптер `ollama`, группа клавиш `<leader>a`); адрес и роль→модель — из `machine.d/ai-env` (AI-CMP-4); на этом хосте (4 ГБ VRAM) `local-chat` не определена — адаптер чата не регистрируется, ожидаемо до R8.5 | `nvim --headless -c 'quit'` без ошибок; ПРОВЕРЕНО headless-прогоном с сетью и `gcc` в PATH — плагины клонируются, парсеры treesitter компилируются; `nvim_get_hl` на реальном файле подтвердил цвета синтаксиса; `nvim_buf_get_keymap`/`vim.lsp.get_clients` на реальном файле подтвердили `gd`/`gD`/`K` и подключение pyright/ruff; R8.4 — ПРОВЕРИТЬ на машине (`:Lazy sync`, живой FIM и чат) |
| zsh | `zsh/` | `zsh/` (требует `ZDOTDIR=~/.config/zsh`, задаёт Nix) | R6.13: oh-my-zsh подключён (только свои плагины — git/sudo/extract/colored-man-pages/command-not-found/z); сторонние плагины — zsh-autosuggestions, zsh-syntax-highlighting (последней строкой — требование плагина), zsh-completions, zsh-history-substring-search; пути — `machine.d/zsh-env` с запасными путями дистрибутивов (ARCHITECTURE.md A.6) | `zsh -n .zshrc`; ПРОВЕРЕНО живым интерактивным прогоном (псевдо-tty, реальные store-пути всех плагинов) — все загружаются без ошибок; тот же прогон без переменных Nix (запасные пути отсутствуют) — без ошибок, деградация без плагинов |
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
| lazygit | `lazygit/` | `lazygit/` | новая запись реестра (DSN П.3.5, R6.12); `config.yml` целиком из генератора (`theme/gen/templates/lazygit-config.yml.tmpl`) — только `gui.theme`, остальные поля lazygit — умолчания | ПРОВЕРЕНО: `lazygit --use-config-file=lazygit/config.yml` на тестовом репозитории — конфиг парсится (ошибка только про отсутствие tty в headless-среде) |
| btop | `btop/` | `btop/` | новая запись реестра (DSN П.3.5, R6.12); `btop.conf` — статика (`color_theme`/`theme_background=false`), `themes/glass-tide.theme` — из генератора (`theme/gen/templates/btop-theme.theme.tmpl`); при первом живом запуске btop сам дописывает в `btop.conf` остальные ключи-умолчания (штатное поведение) | ПРОВЕРЕНО: `btop --default-config` сверил формат ключей; живой визуальный прогон — на пользователе (нужен реальный tty) |
| fzf | `fzf/` | `fzf/` | новая запись реестра (DSN П.3.5, R6.13); `config.zsh` — статика (`FZF_DEFAULT_COMMAND`/`FZF_CTRL_T_COMMAND`/`FZF_ALT_C_COMMAND` на `fd`), подключает `theme.zsh` из генератора (`theme/gen/templates/fzf-theme.zsh.tmpl`); интеграция с zsh — `fzf --zsh` в `.zshrc`, без путей из машинного слоя (встроенный механизм fzf >= 0.48) | ПРОВЕРЕНО: `fzf --help`/man сверили формат `--color`; живой интерактивный прогон zsh — `Ctrl+R`/`Ctrl+T`/`Alt+C` и `$FZF_DEFAULT_OPTS` подключены без ошибок |

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
формате Lua для `hyprland.lua`, DSN-S4), `ai-env` (R8.4: адрес инференса и
роль→модель для `nvim/lua/plugins/ai.lua`, AI-CMP-4).

## Статус

Это **стартовые** конфиги (R4.1, созданы без исходника — старой рабочей копии не было).
Минимальный рабочий набор, без личных привычек/плагинов — донастройка далее не входит в R4.1.
