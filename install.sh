#!/usr/bin/env bash
# install.sh — для не-Nix систем (DOT-8): симлинки ~/.config/<app> на репозиторий
# и заглушки машинного слоя. На NixOS этим занимается фича dotfiles-link (DOT-4).
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"

APPS=(nvim zsh starship foot hypr waybar rofi mako swayosd yazi mpv git mangohud claude-code aider)

# Некоторые приложения ждут каталог не в нижнем регистре — REGISTRY.md.
declare -A TARGET_NAME=(
  [mangohud]=MangoHud
)

check_deps() {
  cat <<'EOF'
Пакеты для менеджера пакетов дистрибутива (имена могут отличаться):
  neovim zsh starship foot hyprland waybar rofi mako swayosd yazi mpv git mangohud
EOF
}

link_app() {
  local app="$1"
  local target_name="${TARGET_NAME[$app]:-$app}"
  local src="$repo_root/$app"
  local dest="$config_home/$target_name"

  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    echo "install.sh: $dest уже существует и не симлинк — пропуск" >&2
    return
  fi
  mkdir -p "$config_home"
  ln -sfn "$src" "$dest"
  echo "linked $dest -> $src"
}

install_machine_stubs() {
  local machine_dir="$config_home/machine.d"
  mkdir -p "$machine_dir"
  for stub in "$repo_root"/machine.d.example/*; do
    local name
    name="$(basename "$stub")"
    local dest="$machine_dir/$name"
    [ -e "$dest" ] || cp "$stub" "$dest"
  done
  echo "machine.d заглушки в $machine_dir (правьте под свой хост)"
}

case "${1:-}" in
  --check-deps)
    check_deps
    ;;
  "")
    for app in "${APPS[@]}"; do
      link_app "$app"
    done
    install_machine_stubs
    ;;
  *)
    echo "usage: $0 [--check-deps]" >&2
    exit 1
    ;;
esac
