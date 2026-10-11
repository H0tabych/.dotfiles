#!/usr/bin/env bash
# Генератор colors.* для каждого приложения из единственного источника
# палитры theme/palette.toml (DOT-9). Результат — коммитится.
#
# Запуск: theme/gen/generate.sh  (из любого каталога)
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

palette="theme/palette.toml"
templates_dir="theme/gen/templates"

declare -A COLOR
while IFS='=' read -r key val; do
  key="$(echo "$key" | xargs)"
  val="$(echo "$val" | xargs)"
  val="${val%\"}"
  val="${val#\"}"
  [ -n "$key" ] && COLOR["$key"]="$val"
done < <(sed -n '/^\[colors\]/,/^\[/p' "$palette" | grep '=')

declare -A DEST=(
  [nvim-colors.lua.tmpl]=nvim/lua/colors.lua
  [foot-colors.ini.tmpl]=foot/colors.ini
  [waybar-colors.css.tmpl]=waybar/colors.css
  [rofi-colors.rasi.tmpl]=rofi/colors.rasi
  [hypr-colors.conf.tmpl]=hypr/colors.conf
  [mako-config.tmpl]=mako/config
  [yazi-theme.toml.tmpl]=yazi/theme.toml
)

for tmpl in "$templates_dir"/*.tmpl; do
  name="$(basename "$tmpl")"
  dest="${DEST[$name]:-}"
  if [ -z "$dest" ]; then
    echo "generate.sh: нет назначения для шаблона $name" >&2
    exit 1
  fi

  content="$(cat "$tmpl")"
  for key in "${!COLOR[@]}"; do
    value="${COLOR[$key]}"
    raw="${value#\#}"
    content="${content//__${key}__/${value}}"
    content="${content//__${key}_raw__/${raw}}"
  done

  mkdir -p "$(dirname "$dest")"
  printf '%s\n' "$content" > "$dest"
  echo "generated $dest"
done
