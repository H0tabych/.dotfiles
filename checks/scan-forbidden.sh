#!/usr/bin/env bash
# Проверка DOT-1/DOT-14: в репозитории не должно быть путей /nix/store,
# констант хоста и приватных фактов (SEC-10 — например, личная почта в git).
# Запуск: checks/scan-forbidden.sh (из корня репозитория или откуда угодно).
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

fail=0

check() {
  local pattern="$1"
  local label="$2"
  local hits
  hits="$(grep -RIn --exclude-dir=.git --exclude-dir=checks \
    --exclude=README.md --exclude=REGISTRY.md -E -- "$pattern" . || true)"
  if [ -n "$hits" ]; then
    echo "scan-forbidden: найдено запрещённое ($label):" >&2
    echo "$hits" >&2
    fail=1
  fi
}

check '/nix/store' "путь /nix/store"
check 'sgms-laptop' "имя хоста"
check '/home/sgm([^a-zA-Z0-9_./-]|$)' "абсолютный путь пользователя (используйте \$HOME)"
check 'hotabychsgm@gmail\.com' "личная почта (SEC-10)"
check '-----BEGIN [A-Z ]*PRIVATE KEY-----' "приватный ключ"
check 'AGE-SECRET-KEY-' "age-секрет"

if [ "$fail" -ne 0 ]; then
  echo "scan-forbidden: ПРОВАЛ" >&2
  exit 1
fi

echo "scan-forbidden: OK, запрещённых констант и секретов не найдено"
