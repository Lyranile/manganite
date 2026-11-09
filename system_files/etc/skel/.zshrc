# History
HISTFILE=$HOME/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# Options
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt AUTO_CD
setopt COMPLETE_IN_WORD
setopt AUTO_MENU
setopt INTERACTIVE_COMMENTS
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt CORRECT

# Zinit
BREW_PREFIX="${BREW_PREFIX:-/home/linuxbrew/.linuxbrew}"
ZINIT_HOME="${BREW_PREFIX}/opt/zinit"
if [ -f "$ZINIT_HOME/zinit.zsh" ]; then
  source "$ZINIT_HOME/zinit.zsh"

  # Oh My Zsh
  zinit wait lucid for \
    OMZL::completion.zsh \
    OMZL::directories.zsh \
    OMZL::history.zsh \
    OMZP::git \
    OMZP::kubectl \
    OMZP::docker-compose \
    OMZP::aws \
    OMZP::terraform \
    OMZP::helm \
    OMZP::kubectx \
    OMZP::command-not-found \
    OMZP::sudo

  # Command completions
  zinit ice wait lucid blockf
  zinit light zsh-users/zsh-completions

  # Command autosuggestions
  zinit ice wait lucid atload'_zsh_autosuggest_start'
  zinit light zsh-users/zsh-autosuggestions

  # Substring search
  zinit ice wait lucid atload'bindkey "^[[A" history-substring-search-up; bindkey "^[[B" history-substring-search-down'
  zinit light zsh-users/zsh-history-substring-search

  # Syntax highlighting
  zinit ice wait lucid
  zinit light zdharma-continuum/fast-syntax-highlighting

  # Bracket closing
  zinit ice wait lucid
  zinit light hlissner/zsh-autopair

  # Aliased commands
  zinit ice wait lucid
  zinit light MichaelAquilina/zsh-you-should-use

  # Shift selection
  zinit ice wait lucid
  zinit light jirutka/zsh-shift-select
fi

fpath+="$HOME/.zfunc"
fpath+=("${BREW_PREFIX}/share/zsh/site-functions")

# Completion styles
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

# Colors styling
eval "$(dircolors -b)"
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Key bindings
bindkey -e

# Word movement
bindkey '^[f' forward-word
bindkey '^[b' backward-word

# Terminal compatibility
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
bindkey "^[[3~" delete-char

# Word navigation
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word
bindkey "^[f" forward-word
bindkey "^[b" backward-word

# History search
bindkey "^[[A" history-search-backward
bindkey "^[[B" history-search-forward

# Home/End fallback
bindkey "\e[H" beginning-of-line
bindkey "\e[F" end-of-line

# Tab navigation
bindkey "^I" menu-complete
bindkey "\e[Z" reverse-menu-complete

# Compute initializationa
fpath+=(~/.zfunc)
autoload -Uz compinit
mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"
compinit

# Profile loading
source "$HOME/.profile"

# Reinitialize completions
autoload -Uz compinit
compinit
