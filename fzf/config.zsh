# Статика (DOT-3) — команды поиска fzf, без токенов палитры. Сама тема —
# fzf/theme.zsh (генератор, DESIGN_SYSTEM.md П.3.5), подключается отсюда.
# fd — тот же быстрый поиск, что в search-tools.nix (nixos-config, DEV-1);
# уважает .gitignore сам по себе, поэтому отдельный --glob "!.git" не нужен.
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

source "${0:h}/theme.zsh"
