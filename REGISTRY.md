# Реестр портативных приложений (DOT-2)

Добавление приложения сюда = запись в таблицу + ADR-lite (краткая причина строкой в «Заметка»).
Приложение вне этого реестра конфигурируется Nix (DOT-2).

| Приложение | Каталог | Целевой путь (`~/.config/...`) | Версия/заметка | Проверка |
|---|---|---|---|---|
| neovim | `nvim/` | `nvim/` | без менеджера плагинов пока (lock-файл — после первой реальной настройки, DOT-11) | `nvim --headless -c 'quit'` без ошибок |
| zsh | `zsh/` | `zsh/` (требует `ZDOTDIR=~/.config/zsh`, задаёт Nix) | — | `zsh -n .zshrc` |
| foot | `foot/` | `foot/` | `include=` в `foot.ini` — foot ≥ 1.14 | `foot --check-config` |
| hypr | `hypr/` | `hypr/` | — | `hyprctl` при живой сессии (ручная проверка) |
| waybar | `waybar/` | `waybar/` | — | `waybar -c config.jsonc -s style.css --log-level error` недолгий запуск |
| rofi | `rofi/` | `rofi/` | — | `rofi -dump-config` после `-config config.rasi` |
| mako | `mako/` | `mako/` | весь файл генерируется (цвета + статика вместе, см. `theme/gen/templates/mako-config.tmpl`) | `makoctl reload` при живой сессии |
| yazi | `yazi/` | `yazi/` | — | `yazi --version` + ручной запуск |
| mpv | `mpv/` | `mpv/` | — | `mpv --no-config --show-profile=default` не применимо; визуальная проверка |
| git | `git/` | `git/` (файл `config`, не `gitconfig`) | identity — только через `machine.d/git-identity` (SEC-10) | `git config --list` без личной почты в выводе из репозитория |
| mangohud | `mangohud/` | **`MangoHud/`** (нестандартный регистр каталога у самого приложения) | — | `mangohud --dlsym true glxgears` (ручная проверка) |

## Палитра

`theme/palette.toml` — источник; `theme/gen/generate.sh` перегенерирует `colors.*`
во всех каталогах выше. После правки палитры — обязательно перезапустить генератор
и закоммитить результат (DOT-9).

## Машинный слой

`machine.d.example/` — заглушки для `~/.config/machine.d/*`, который создаёт Nix/`install.sh`
и который не коммитится (DOT-5). Сейчас используется для: `git-identity` (имя/почта, SEC-10),
`zsh-env` (переменные окружения шелла), `hypr-monitors.conf` (описание мониторов),
`hypr-input.conf` (раскладка клавиатуры, DESK-7).

## Статус

Это **стартовые** конфиги (R4.1, созданы без исходника — старой рабочей копии не было).
Минимальный рабочий набор, без личных привычек/плагинов — донастройка далее не входит в R4.1.
