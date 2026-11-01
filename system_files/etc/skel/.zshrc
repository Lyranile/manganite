# Zinit
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
source "$ZINIT_HOME/zinit.zsh"
fpath+="$HOME/.zfunc"

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

# Oh My Zsh Plugins
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

_setup_history_substring_keys() {
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
}

_setup_instructions() {
  zicompinit
  zicdreplay
}

# Command Completions
zinit ice wait lucid blockf
zinit light zsh-users/zsh-completions

# Command Autosuggestions
zinit ice wait lucid atload'_zsh_autosuggest_start'
zinit light zsh-users/zsh-autosuggestions

# Substring Search
zinit ice wait lucid atload'_setup_history_substring_keys'
zinit light zsh-users/zsh-history-substring-search

# Syntax Highlighting
zinit ice wait lucid
zinit light zdharma-continuum/fast-syntax-highlighting

# Bracket Closing
zinit ice wait lucid
zinit light hlissner/zsh-autopair

# Aliased Commands
zinit ice wait lucid
zinit light MichaelAquilina/zsh-you-should-use

# Shift Selection
zinit ice wait lucid
zinit light jirutka/zsh-shift-select

# Completion styles
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.zcompcache"

# Completion colors
typeset -a colors
IFS=: read -rA colors <<< "$LS_COLORS"
zstyle ':completion:*' list-colors "${colors[@]}"

# Bindkeys
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

# Compute Initialization
autoload -Uz compinit
rm -f ~/.zcompdump
compinit

# Profile Loading
source "$HOME/.profile"
fpath+=~/.zfunc; autoload -Uz compinit; compinit
