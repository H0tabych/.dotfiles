# .dotfiles

Отдельный, публичный, самодостаточный репозиторий конфигов приложений (DOT-1).
Не часть `nixos-config` — подключается туда input-ом (читает только `theme/palette.toml`)
и симлинкуется фичей `dotfiles-link` (DOT-4).

## Структура

См. `REGISTRY.md` — реестр приложений, целевые пути, заметки о версиях.
Палитра — `theme/palette.toml` + `theme/gen/generate.sh` (DOT-9).
Машинный слой (`~/.config/machine.d/*`) создаёт Nix/`install.sh`, в репозитории
только заглушки `machine.d.example/` (DOT-5) — секретов и констант хоста здесь нет.

## Установка на не-Nix системе

```sh
./install.sh --check-deps   # список пакетов для менеджера пакетов дистрибутива
./install.sh                # симлинки ~/.config/<app> + заглушки machine.d
```

## Правка палитры

1. Отредактировать `theme/palette.toml`.
2. `theme/gen/generate.sh`.
3. Закоммитить изменившиеся `*/colors.*` вместе с `palette.toml`.

## Проверки

`checks/scan-forbidden.sh` — поиск констант хоста, путей `/nix/store` и приватных
фактов (DOT-1, SEC-10). Запускается в CI (`.github/workflows/ci.yml`) и локально:

```sh
bash checks/scan-forbidden.sh
```
