#!/usr/bin/env bash
# install.sh — для не-Nix систем (DOT-8): симлинки ~/.config/<app> на репозиторий
# и заглушки машинного слоя. На NixOS этим занимается фича dotfiles-link (DOT-4).
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"

APPS=(nvim zsh starship foot hypr eww net rofi mako swayosd yazi mpv git mangohud zathura lazygit btop fzf ai)

# Некоторые приложения ждут каталог не в нижнем регистре — REGISTRY.md.
declare -A TARGET_NAME=(
  [mangohud]=MangoHud
)

check_deps() {
  cat <<'EOF'
Пакеты для менеджера пакетов дистрибутива (имена проверены на Arch Linux, R9.5; в других
дистрибутивах могут отличаться):
  приложения реестра: neovim zsh starship foot hyprland rofi mako swayosd yazi mpv git mangohud
                      zathura zathura-pdf-mupdf lazygit btop fzf
  eww-панель:         eww из master (Arch: AUR `eww-git`; AUR-пакет `eww` 0.6.0 старее и не разбирает
                      `:focusable "none"`); нужны GTK3 и gtk-layer-shell
                      jq socat playerctl brightnessctl networkmanager bluez bluez-utils wireplumber
                      pipewire libnotify
  сессия Hyprland:    hyprpaper hyprlock
  zsh-плагины:        zsh-autosuggestions zsh-syntax-highlighting zsh-completions
                      zsh-history-substring-search (oh-my-zsh — Arch: AUR `oh-my-zsh-git`)
  разное:             fd ripgrep python (>= 3.11, генератор темы) gcc tree-sitter-cli (парсеры neovim)
                      ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols
EOF
}

# Переменные, которые на NixOS задаёт система (DOT-12), а на других системах — пользователь:
# приложения находят конфиг через переменную окружения, а не через ~/.config.
print_env_hint() {
  cat <<EOF

Переменные окружения (DOT-12) — добавьте в ~/.zshenv (или профиль своего шелла):
  export ZDOTDIR="$config_home/zsh"
  export STARSHIP_CONFIG="$config_home/starship/starship.toml"
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

# Дополнительные цели записи `ai` (R9.22, DOT-4, REGISTRY.md): стандартные пути агентов вне
# ~/.config. Навыки — по одному (каталог ~/.claude/skills ведёт сам Claude); существующее не
# симлинк — пропуск.
link_path() {
  local src="$1" dest="$2"
  [ -e "$src" ] || return 0
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    echo "install.sh: $dest уже существует и не симлинк — пропуск" >&2
    return
  fi
  mkdir -p "$(dirname "$dest")"
  ln -sfn "$src" "$dest"
  echo "linked $dest -> $src"
}

link_agent_paths() {
  link_path "$repo_root/ai/AGENTS.md" "$HOME/.agents/AGENTS.md"
  link_path "$repo_root/ai/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
  local skill name
  for skill in "$repo_root"/ai/skills/*/; do
    [ -d "$skill" ] || continue
    name="$(basename "$skill")"
    link_path "${skill%/}" "$HOME/.agents/skills/$name"
    link_path "${skill%/}" "$HOME/.claude/skills/$name"
  done
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
  # Обои (hyprpaper/hyprlock подключают hypr-wallpaper.conf через source=; на NixOS файл пишет
  # dotfiles-link.nix тем же содержимым). Без него hyprpaper отказывается читать конфиг (R9.5).
  local wp="$machine_dir/hypr-wallpaper.conf" wp_file
  if [ ! -e "$wp" ]; then
    wp_file="$(python3 -c "
import sys, tomllib
p = tomllib.load(open(sys.argv[1], 'rb'))
print(p['variant'][p['active']]['wallpaper']['file'])" "$repo_root/theme/palette.toml" 2>/dev/null || true)"
    printf '# Сгенерировано install.sh (DOT-5): путь к обоям активного варианта палитры.\n$wallpaper = %s/theme/wallpapers/%s\n' \
      "$repo_root" "${wp_file:-forest-river.jpg}" > "$wp"
  fi
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
    link_agent_paths
    install_machine_stubs
    print_env_hint
    ;;
  *)
    echo "usage: $0 [--check-deps]" >&2
    exit 1
    ;;
esac
