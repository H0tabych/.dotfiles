# Портативный конфиг zsh (DOT-3). Без фреймворка — минимальная база.
# Значения окружения приоритетнее умолчаний (DOT-13).

HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
mkdir -p "$(dirname "$HISTFILE")"
HISTSIZE=10000
SAVEHIST=10000
setopt share_history hist_ignore_dups hist_ignore_space

setopt autocd
setopt interactive_comments

autoload -Uz compinit && compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"

source "$ZDOTDIR/aliases.zsh"

PROMPT='%F{blue}%~%f %# '

[ -f "$HOME/.config/machine.d/zsh-env" ] && source "$HOME/.config/machine.d/zsh-env"

# Промпт — starship (DSN-S6, R6.9): STARSHIP_CONFIG задаёт Nix (DOT-12).
# В tty без Nerd Font ($TERM=linux) остаётся простой PROMPT выше (DSN-CMP-12).
if [ "$TERM" != "linux" ] && command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
