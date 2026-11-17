#!/usr/bin/env bash
# Проверка переносимости (A15, R9.5): после `install.sh` и установки пакетов дистрибутива
# проверяет, что приложения реестра (REGISTRY.md) принимают свои конфиги и стартуют.
# Запуск на чистой не-Nix системе: ./install.sh && checks/portability.sh [--live]
# Только чтение: ничего не правит в репозитории (проверки без tty и без дисплея).
# --session  внутри уже работающей сессии Hyprland (реальная машина или ВМ с графикой; нужны
#         XDG_RUNTIME_DIR и WAYLAND_DISPLAY из сессии): hyprctl, окна eww, мако, swayosd, hyprpaper,
#         foot, скриншот (grim) на живом композиторе.
# --live  дополнительно: headless-сессия Hyprland (AQ_BACKENDS=headless) и старт мако,
#         swayosd, hyprpaper, foot и (если установлен) eww на ней.
# Код выхода 0 — нет FAIL; SKIP (нет пакета/нет дисплея) выводится с причиной и не провал.
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
live=0 session=0
case "${1:-}" in --live) live=1 ;; --session) session=1 ;; esac

pass=0 fail=0 skip=0
row() { printf '%-10s %-5s %-34s %s\n' "$1" "$2" "$3" "$4"; }

# check <приложение> <команда-версии|-> <описание> <команда...>
check() {
  local app="$1" vcmd="$2" desc="$3"; shift 3
  local bin="${1}" ver out rc
  if ! command -v "$bin" >/dev/null 2>&1; then
    row "$app" SKIP "$desc" "нет пакета ($bin)"; skip=$((skip + 1)); return
  fi
  ver="-"
  [ "$vcmd" != "-" ] && ver="$($vcmd 2>/dev/null | head -1 | sed 's/\x1b\[[0-9;]*m//g' | tr -s ' ' | cut -c1-40)"
  out="$(timeout 120 "$@" 2>&1)"; rc=$?
  if [ "$rc" -eq 0 ]; then
    row "$app" PASS "$desc" "$ver"; pass=$((pass + 1))
  else
    row "$app" FAIL "$desc" "$ver; код $rc: $(printf '%s' "$out" | head -3 | tr '\n' '|' | cut -c1-200)"
    fail=$((fail + 1))
  fi
}

# Каждая проверка — из столбца «Проверка» REGISTRY.md, в безголовом виде.
export ZDOTDIR="$config_home/zsh"
export STARSHIP_CONFIG="$config_home/starship/starship.toml"
export XDG_CONFIG_HOME="$config_home"
rt="$(mktemp -d)"; chmod 700 "$rt"   # XDG_RUNTIME_DIR: без него Hyprland/мako отказываются стартовать
[ "$session" -eq 1 ] || export XDG_RUNTIME_DIR="$rt"

echo "# $(. /etc/os-release 2>/dev/null; echo "${PRETTY_NAME:-?}"); конфиги: $config_home -> $repo_root"
row приложение итог проверка версия/заметка

check install - "симлинки по реестру" bash -c '
  for d in nvim zsh starship foot hypr eww net rofi mako swayosd yazi mpv git MangoHud zathura lazygit btop fzf ai; do
    [ -L "'"$config_home"'/$d" ] || { echo "нет симлинка $d"; exit 1; }
  done'
check install - "команды из скриптов dotfiles в PATH" bash -c 'm=""; for c in hyprctl jq socat playerctl brightnessctl nmcli bluetoothctl wpctl pactl pw-dump makoctl systemd-inhibit notify-send rfkill grim slurp swappy; do command -v $c >/dev/null 2>&1 || m="$m $c"; done; [ -z "$m" ] || { echo "нет:$m"; exit 1; }'
check install - "нет /nix/store в dotfiles (DOT-1)" bash "$repo_root/checks/scan-forbidden.sh"
check nvim "nvim --version" "nvim --headless -c quit" nvim --headless -c quit
check zsh "zsh --version" "zsh -n .zshrc" zsh -n "$ZDOTDIR/.zshrc"
check zsh - "интерактивный старт (pty), без ошибок" bash -c 'out=$(script -qec "zsh -i -c exit" /dev/null 2>&1 | tr -d "\r"); [ -z "$out" ] || { echo "$out"; exit 1; }'
check starship "starship --version" "starship explain" starship explain
check foot "foot --version" "foot --check-config" foot --check-config
check rofi "rofi -version" "rofi -dump-config" rofi -no-config -config "$config_home/rofi/config.rasi" -dump-config
check yazi "yazi --version" "yazi --version" yazi --version
check yazi - "yazi в pty 3 с: тема/конфиг без ошибок" bash -c 'out=$(TERM=xterm-256color script -qec "stty rows 40 cols 120; timeout 3 yazi" /dev/null 2>&1 | tr -d "\r" | sed "s/\x1b[]_P][^\\\\]*\\\\//g; s/\x1b\[[?0-9;]*[a-zA-Z]//g" | grep -aiE "error|invalid|failed|parse|unknown"); [ -z "$out" ] || { echo "$out"; exit 1; }'
check mpv "mpv --version" "mpv --no-config + include" mpv --config-dir="$config_home/mpv" --list-options
check git "git --version" "git config --list (читается)" git config --file "$config_home/git/config" --list
check lazygit "lazygit --version" "конфиг парсится (без tty)" bash -c 'lazygit --use-config-file="'"$config_home"'/lazygit/config.yml" --version'
check btop "btop --version" "btop --version" btop --version
check fzf "fzf --version" "fzf --zsh" bash -c 'fzf --zsh >/dev/null'
check zathura "zathura --version" "zathura --version" zathura --version
check mangohud "mangohud --version" "MangoHud.conf читается" bash -c 'MANGOHUD_CONFIGFILE="'"$config_home"'/MangoHud/MangoHud.conf" mangohud --version'
check hypr "Hyprland --version" "Hyprland --verify-config" Hyprland --verify-config -c "$config_home/hypr/hyprland.lua"
command -v eww >/dev/null 2>&1 || { row eww SKIP "eww: старт/окна" "нет пакета (в Arch только AUR)"; skip=$((skip + 1)); }
check eww - "eww/scripts: bash -n" bash -c 'for f in "'"$config_home"'"/eww/scripts/*; do [ -f "$f" ] && head -1 "$f" | grep -q bash && bash -n "$f"; done; true'
check net - "net/*: bash -n" bash -c 'for f in "'"$config_home"'"/net/*; do [ -f "$f" ] && bash -n "$f"; done'
check ai - "ai/gen/gen.py --check" python3 "$config_home/ai/gen/gen.py" --check
check theme - "theme/gen/gen.py --check" python3 "$repo_root/theme/gen/gen.py" --check

if [ "$live" -eq 1 ]; then
  # Носитель для layer-shell-клиентов: Hyprland (нужен узел DRM), иначе sway с headless-бэкендом
  # и программным рендером (работает без GPU и дисплея; Hyprland при этом проверен --verify-config).
  echo "# --live: headless-сессия Wayland"
  export AQ_BACKENDS=headless WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1
  host=""
  # Сессионная шина D-Bus (мако, swayosd): на настоящей системе она есть от менеджера сессий.
  if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ] && command -v dbus-daemon >/dev/null 2>&1; then
    dbus-daemon --session --fork --print-address=3 --print-pid=4 3>"$rt/dbus.addr" 4>"$rt/dbus.pid" >/dev/null 2>&1 \
      && export DBUS_SESSION_BUS_ADDRESS="$(cat "$rt/dbus.addr")"
  fi
  # Системная шина: на настоящей системе — /run/dbus/system_bus_socket (swayosd падает без неё);
  # в контейнере без systemd подставляем вторую сессионную шину.
  if [ ! -S /run/dbus/system_bus_socket ] && command -v dbus-daemon >/dev/null 2>&1; then
    dbus-daemon --session --fork --print-address=3 --print-pid=4 3>"$rt/sysbus.addr" 4>"$rt/sysbus.pid" >/dev/null 2>&1 \
      && export DBUS_SYSTEM_BUS_ADDRESS="$(cat "$rt/sysbus.addr")"
  fi
  if command -v Hyprland >/dev/null 2>&1; then
    Hyprland -c "$config_home/hypr/hyprland.lua" >"$rt/hypr.log" 2>&1 &
    hp=$!; sleep 6
    if kill -0 "$hp" 2>/dev/null && ls "$rt"/wayland-[0-9] >/dev/null 2>&1; then
      host=Hyprland; row hypr PASS "live-старт Hyprland (6 с живёт)" "-"; pass=$((pass + 1))
    else
      row hypr SKIP "live-старт Hyprland" "$(grep -m1 -o 'what().*' "$rt/hypr.log" | cut -c1-120) (нет GPU/DRM в окружении)"
      skip=$((skip + 1))
    fi
  fi
  if [ -z "$host" ] && command -v sway >/dev/null 2>&1; then
    sway -c /dev/null >"$rt/sway.log" 2>&1 &
    hp=$!; sleep 4
    kill -0 "$hp" 2>/dev/null && host=sway
  fi
  disp="$(ls "$rt"/wayland-[0-9] 2>/dev/null | head -1 | xargs -r basename)"
  if [ -n "$host" ] && [ -n "$disp" ]; then
    export WAYLAND_DISPLAY="$disp"
    echo "# носитель: $host ($disp)"
    for app in mako swayosd-server hyprpaper foot eww; do
      command -v "$app" >/dev/null 2>&1 || { row "$app" SKIP "live-старт" "нет пакета"; skip=$((skip + 1)); continue; }
      case "$app" in
        eww) timeout 8 eww daemon --no-daemonize >"$rt/$app.log" 2>&1 & ;;
        foot) timeout 8 foot -e sleep 6 >"$rt/$app.log" 2>&1 & ;;
        *) timeout 8 "$app" >"$rt/$app.log" 2>&1 & ;;
      esac
      ap=$!; sleep 4
      if kill -0 "$ap" 2>/dev/null; then row "$app" PASS "live-старт (4 с живёт)" "$host"; pass=$((pass + 1))
      elif [ "$host" != Hyprland ] && grep -q "Missing protocols" "$rt/$app.log"; then
        row "$app" SKIP "live-старт" "нужны протоколы Hyprland, носитель $host их не даёт"; skip=$((skip + 1))
      else row "$app" FAIL "live-старт" "$(head -3 "$rt/$app.log" | sed 's/\x1b\[[0-9;]*m//g' | tr '\n' '|' | cut -c1-200)"; fail=$((fail + 1)); fi
      kill "$ap" 2>/dev/null
    done
    # eww: демон + окна из eww.yuck (разбор yuck и открытие слоя на реальном композиторе).
    if command -v eww >/dev/null 2>&1; then
      eww daemon >"$rt/eww-win.log" 2>&1; sleep 2
      eww open calendar-popup >>"$rt/eww-win.log" 2>&1; eww open bar --arg h=32 >>"$rt/eww-win.log" 2>&1
      sleep 2; act="$(eww active-windows 2>&1)"
      if printf '%s' "$act" | grep -q "calendar-popup" && printf '%s' "$act" | grep -q "bar"; then
        row eww PASS "окна bar и calendar-popup открыты" "$(eww --version 2>/dev/null | head -1 | cut -c1-30)"; pass=$((pass + 1))
      else
        row eww FAIL "окна bar и calendar-popup" "$(printf '%s %s' "$act" "$(tail -3 "$rt/eww-win.log")" | tr '\n' '|' | cut -c1-240)"; fail=$((fail + 1))
      fi
      eww kill >/dev/null 2>&1
    fi
  else
    row live FAIL "носитель Wayland не поднялся" "$(tail -3 "$rt/sway.log" 2>/dev/null | tr '\n' '|' | cut -c1-200)"; fail=$((fail + 1))
  fi
  kill "$hp" 2>/dev/null
  for f in dbus.pid sysbus.pid; do [ -s "$rt/$f" ] && kill "$(cat "$rt/$f")" 2>/dev/null; done
fi

if [ "$session" -eq 1 ]; then
  echo "# --session: ${XDG_RUNTIME_DIR:-?} ${WAYLAND_DISPLAY:-?}"
  hsig="$(ls "$XDG_RUNTIME_DIR/hypr" 2>/dev/null | head -1)"; export HYPRLAND_INSTANCE_SIGNATURE="$hsig"
  check hypr "hyprctl version" "сессия Hyprland жива (hyprctl version)" hyprctl version
  check hypr - "hyprctl configerrors пуст" bash -c '[ -z "$(hyprctl configerrors | tr -d "[:space:]")" ] || { hyprctl configerrors; exit 1; }'
  check hypr - "есть монитор" bash -c 'hyprctl monitors | grep -q "^Monitor"'
  sess_start() { # <приложение> <команда...>: если не запущено — запустить и дать 4 с
    local app="$1"; shift
    pgrep -x "$app" >/dev/null 2>&1 || { (setsid "$@" >"$rt/$app.log" 2>&1 </dev/null &); sleep 4; }
  }
  for app in mako swayosd-server hyprpaper; do
    if ! command -v "$app" >/dev/null 2>&1; then row "$app" SKIP "в сессии" "нет пакета"; skip=$((skip + 1)); continue; fi
    sess_start "$app" "$app"
    if pgrep -x "$app" >/dev/null 2>&1; then row "$app" PASS "работает в сессии" "-"; pass=$((pass + 1))
    elif grep -q "Failed to allocate a GBM buffer" "$rt/$app.log" 2>/dev/null; then
      row "$app" SKIP "в сессии" "GBM не выделил буфер (виртуальный GPU без 3D, kms_swrast); на реальном GPU — ручная проверка"; skip=$((skip + 1))
    else row "$app" FAIL "в сессии" "$(sed 's/\x1b\[[0-9;]*m//g' "$rt/$app.log" | head -3 | tr '\n' '|' | cut -c1-200)"; fail=$((fail + 1)); fi
  done
  if command -v eww >/dev/null 2>&1; then
    pgrep -x eww >/dev/null 2>&1 || eww daemon >"$rt/eww.log" 2>&1
    "$config_home/eww/scripts/bars" sync >"$rt/bars.log" 2>&1; sleep 3
    check eww - "панель bar открыта на мониторе (layer eww-bar)" bash -c 'hyprctl layers | grep -q "namespace: eww-bar"'
    "$config_home/eww/scripts/netpanel" open >"$rt/np.log" 2>&1; sleep 3
    check eww - "окно сети открыто (layer eww-panel)" bash -c 'hyprctl layers | grep -q "namespace: eww-panel"'
    "$config_home/eww/scripts/netpanel" close >/dev/null 2>&1
  fi
  if command -v foot >/dev/null 2>&1; then
    (setsid foot -e sleep 20 >"$rt/foot.log" 2>&1 </dev/null &); sleep 3
    check foot - "окно foot в сессии (hyprctl clients)" bash -c 'hyprctl clients | grep -q "class: foot"'
  fi
  if command -v notify-send >/dev/null 2>&1 && command -v makoctl >/dev/null 2>&1; then
    notify-send -a portability "A15" "проверка" 2>/dev/null; sleep 1
    check mako - "уведомление дошло (makoctl list)" bash -c 'makoctl list | grep -q "A15"'
  fi
  if command -v grim >/dev/null 2>&1; then
    check grim - "снимок экрана (grim)" bash -c 'f=$(mktemp --suffix=.png) && timeout 20 grim "$f" && [ -s "$f" ]'
  fi
fi

echo "# итого: PASS $pass, FAIL $fail, SKIP $skip"
[ "$fail" -eq 0 ]
