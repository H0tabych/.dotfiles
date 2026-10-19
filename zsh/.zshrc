# Портативный конфиг zsh (DOT-3, R6.13). oh-my-zsh — только для своих плагинов
# (git/sudo/extract/colored-man-pages/command-not-found/z, DESIGN_SYSTEM.md
# П.3.5); автодополнение/подсветка/нечёткий поиск — сторонние плагины и fzf,
# пути из машинного слоя с запасными путями дистрибутивов (ARCHITECTURE.md
# A.6 «zsh / редактор»). Значения окружения приоритетнее умолчаний (DOT-13).

HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
mkdir -p "$(dirname "$HISTFILE")"
HISTSIZE=10000
SAVEHIST=10000
setopt share_history hist_ignore_dups hist_ignore_space

setopt autocd
setopt interactive_comments

[ -f "$HOME/.config/machine.d/zsh-env" ] && source "$HOME/.config/machine.d/zsh-env"

# --- oh-my-zsh: регистрация + компинит (единственный, не дублируем свой) ---
# Запасные пути — типовые места дистрибутивов (DOT-8: dotfiles работают и без
# Nix); $OH_MY_ZSH и соседние переменные из machine.d/zsh-env их переопределяют.
: "${OH_MY_ZSH:=/usr/share/oh-my-zsh}"
: "${ZSH_COMPLETIONS:=/usr/share/zsh/site-functions}"
: "${ZSH_AUTOSUGGESTIONS:=/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh}"
: "${ZSH_HISTORY_SUBSTRING_SEARCH:=/usr/share/zsh-history-substring-search/zsh-history-substring-search.zsh}"
: "${ZSH_SYNTAX_HIGHLIGHTING:=/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh}"

export ZSH="$OH_MY_ZSH"
export ZSH_THEME=""
export ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
plugins=(git sudo extract colored-man-pages command-not-found z)

[ -d "$ZSH_COMPLETIONS" ] && fpath=("$ZSH_COMPLETIONS" $fpath)
[ -f "$ZSH/oh-my-zsh.sh" ] && source "$ZSH/oh-my-zsh.sh"

# --- Автодополнение по истории (fish-like) и подстрочный поиск по истории ---
if [ -f "$ZSH_AUTOSUGGESTIONS" ]; then
  source "$ZSH_AUTOSUGGESTIONS"
  # Подсказка — терминальный цвет 8 (overlay1, DESIGN_SYSTEM.md П.3.5), не
  # литеральный hex: ansi-тема, как у bat/delta.
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
fi

if [ -f "$ZSH_HISTORY_SUBSTRING_SEARCH" ]; then
  source "$ZSH_HISTORY_SUBSTRING_SEARCH"
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
fi

source "$ZDOTDIR/aliases.zsh"

PROMPT='%F{blue}%~%f %# '

# Промпт — starship (DSN-S6, R6.9): STARSHIP_CONFIG задаёт Nix (DOT-12).
# В tty без Nerd Font ($TERM=linux) остаётся простой PROMPT выше (DSN-CMP-12).
if [ "$TERM" != "linux" ] && command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# --- Нечёткий поиск (Ctrl+R/Ctrl+T/Alt+C), DEV-1 «быстрый поиск» ---
# `fzf --zsh` — встроенная интеграция (fzf >= 0.48), без путей из машинного
# слоя: берёт бинарник из PATH, работает одинаково на любом дистрибутиве.
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
  [ -f "$HOME/.config/fzf/config.zsh" ] && source "$HOME/.config/fzf/config.zsh"
fi

# --- direnv: автоактивация проектных окружений (env-manager-direnv.nix) ---
# Хук — целиком здесь (A.6, не два хука): Nix-фича включает только системный
# direnv/nix-direnv и выключает enable*Integration намеренно.
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"

# --- Подсветка синтаксиса — ДОЛЖНА быть последней строкой (требование плагина) ---
[ -f "$ZSH_SYNTAX_HIGHLIGHTING" ] && source "$ZSH_SYNTAX_HIGHLIGHTING"
