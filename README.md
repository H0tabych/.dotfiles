# .dotfiles

Отдельный, публичный, самодостаточный репозиторий конфигов приложений (DOT-1).
Не часть `nixos-config` — подключается туда input-ом (читает только `theme/palette.toml`)
и симлинкуется фичей `dotfiles-link` (DOT-4).

## Структура

См. `REGISTRY.md` — реестр приложений, целевые пути, заметки о версиях.
Дизайн-система Glass Tide — `docs/architecture/DESIGN_SYSTEM.md` в `nixos-config`
(ADR-36). Палитра — `theme/palette.toml` + `theme/gen/gen.py` (DOT-9).
Машинный слой (`~/.config/machine.d/*`) создаёт Nix/`install.sh`, в репозитории
только заглушки `machine.d.example/` (DOT-5) — секретов и констант хоста здесь нет.

## Установка на не-Nix системе

```sh
./install.sh --check-deps   # список пакетов для менеджера пакетов дистрибутива
./install.sh                # симлинки ~/.config/<app> + заглушки machine.d
```

## Правка палитры

1. Отредактировать `theme/palette.toml`.
2. `python3 theme/gen/gen.py` (стандартная библиотека Python, зависимостей не требует).
3. Закоммитить изменившиеся сгенерированные файлы вместе с `palette.toml`.

При смене файла обоев в `theme/wallpapers/` — отдельно `theme/gen/probe.py`
(требует Pillow/numpy) пересчитывает контрольные точки контраста `probe`,
результат копируется в `palette.toml` руками.

## Проверки

`checks/scan-forbidden.sh` — поиск констант хоста, путей `/nix/store` и приватных
фактов (DOT-1, SEC-10). `theme/gen/gen.py --check` — схема, монотонность и
контраст палитры (DSN-A1/A2, DESIGN_SYSTEM.md раздел 11). Оба запускаются в CI
(`.github/workflows/ci.yml`) и локально:

```sh
bash checks/scan-forbidden.sh
python3 theme/gen/gen.py --check
```
