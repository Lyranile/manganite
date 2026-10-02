# Tokens
export XDG_CONFIG_HOME="$HOME/.config"
export HOMEBREW_NO_ENV_HINTS=1

SHELL=$(cat /proc/$$/comm)

# Starship
if [ "$(command -v starship)" ]; then
	eval "$(starship init ${SHELL})"
	eval "$(starship completions ${SHELL})"
fi

# List Aliases
if [ "$(command -v eza)" ]; then
	FLAGS="--git --icons=auto --classify --group-directories-first --time-style=long-iso --color-scale"
	alias ls="eza $FLAGS"
	alias l="eza $FLAGS --git-ignore"
	alias ll="eza $FLAGS --all --header --long"
	alias tree="eza $FLAGS --tree"
fi

# Zoxide Aliases
if [ "$(command -v zoxide)" ]; then
	eval "$(zoxide init ${SHELL})"
	alias cd="z"
fi

# Picker Aliases
if [ "$(command -v fzf)" ]; then
	eval "$(fzf --${SHELL})"
fi

# Atuin Aliases
if [ "$(command -v atuin)" ]; then
	eval "$(atuin init ${SHELL})"
fi

# Cat Aliases
if [ "$(command -v bat)" ]; then
	alias less="bat"
	alias cat="bat --paging=never"
fi

# Processes Aliases
if [ "$(command -v duf)" ]; then
    alias ps='procs'
fi

# Pip Aliases
if [ "$(command -v pip)" ]; then
    alias pip='uv'
fi

# Npm Aliases
if [ "$(command -v npm)" ]; then
    alias npm='pnpm'
fi
