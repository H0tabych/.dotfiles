# Реестр портативных приложений (DOT-2)

Добавление приложения сюда = запись в таблицу + ADR-lite (краткая причина строкой в «Заметка»).
Приложение вне этого реестра конфигурируется Nix (DOT-2).

| Приложение | Каталог | Целевой путь (`~/.config/...`) | Версия/заметка | Проверка |
|---|---|---|---|---|
| neovim | `nvim/` | `nvim/` | без менеджера плагинов пока (lock-файл — после первой реальной настройки, DOT-11) | `nvim --headless -c 'quit'` без ошибок |
| zsh | `zsh/` | `zsh/` (требует `ZDOTDIR=~/.config/zsh`, задаёт Nix) | — | `zsh -n .zshrc` |
| foot | `foot/` | `foot/` | `include=` в `foot.ini` — foot ≥ 1.14 | `foot --check-config` |
| hypr | `hypr/` | `hypr/` | Hyprland ≥ 0.55: основной конфиг — Lua (`hyprland.lua`, `theme.lua`, `effects.lua`), hyprlang ещё поддерживается; тег `pre-lua` перед переходом (DSN-S4) | `hyprctl` при живой сессии (ручная проверка) |
| waybar | `waybar/` | `waybar/` | — | `waybar -c config.jsonc -s style.css --log-level error` недолгий запуск |
| rofi | `rofi/` | `rofi/` | — | `rofi -dump-config` после `-config config.rasi` |
| mako | `mako/` | `mako/` | весь файл генерируется (цвета + статика вместе, см. `theme/gen/templates/mako-config.tmpl`) | `makoctl reload` при живой сессии |
| yazi | `yazi/` | `yazi/` | — | `yazi --version` + ручной запуск |
| mpv | `mpv/` | `mpv/` | — | `mpv --no-config --show-profile=default` не применимо; визуальная проверка |
| git | `git/` | `git/` (файл `config`, не `gitconfig`) | identity — только через `machine.d/git-identity` (SEC-10) | `git config --list` без личной почты в выводе из репозитория |
| mangohud | `mangohud/` | **`MangoHud/`** (нестандартный регистр каталога у самого приложения) | — | `mangohud --dlsym true glxgears` (ручная проверка) |

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

Статус (DSN-S2 дизайн-системы, 2026-10-14): генератор и 7 ранее существовавших
потребителей переведены на новую схему токенов. Остальные потребители
(Lua-композитор, starship, swayosd, qt6ct, sddm-astronaut) и про-профильная
генерация (ac/battery/solid/game) — следующие шаги (DSN-S3…DSN-S8,
DESIGN_SYSTEM.md Приложение I.4).

## Машинный слой

`machine.d.example/` — заглушки для `~/.config/machine.d/*`, который создаёт Nix/`install.sh`
и который не коммитится (DOT-5). Сейчас используется для: `git-identity` (имя/почта, SEC-10),
`zsh-env` (переменные окружения шелла), `hypr-monitors.conf` (описание мониторов),
`hypr-input.conf` (раскладка клавиатуры, DESK-7), `hypr.lua` (те же факты в
формате Lua для `hyprland.lua`, DSN-S4).

## Статус

Это **стартовые** конфиги (R4.1, созданы без исходника — старой рабочей копии не было).
Минимальный рабочий набор, без личных привычек/плагинов — донастройка далее не входит в R4.1.
