# Path Arguments
export PATH="$HOME/.local/bin:$HOME/bin:/usr/bin:/run/host/usr/bin"
export XDG_CONFIG_HOME="$HOME/.config"

# Shell Name
SHELL=$(cat /proc/$$/comm)

# Starship Aliases
if [ "$(command -v starship)" ]; then
	eval "$(starship init "${SHELL}")"
	eval "$(starship completions "${SHELL}")"
fi

# Editor Aliases
if [ "$(command -v zed)" ]; then
	export EDITOR="zed"
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
	eval "$(zoxide init "${SHELL}")"
	alias cd="z"
fi

# Picker Aliases
if [ "$(command -v fzf)" ]; then
	eval "$(fzf --"${SHELL}")"
fi

# Cat Aliases
if [ "$(command -v bat)" ]; then
	alias less="bat"
	alias cat="bat --paging=never"
fi

# Node Aliases
if [ "$(command -v pnpm)" ]; then
	alias npm='pnpm'
	alias npx='pnpm exec'
fi

# Man Aliases
if [ "$(command -v tldr)" ]; then
	alias man="tldr"
fi

# Difference Aliases
if [ "$(command -v delta)" ]; then
	alias diff="delta"
fi

# Task Aliases
if [ "$(command -v go-task)" ]; then
	alias task="go-task"
fi

# Grep Aliases
if [ "$(command -v ug)" ]; then
	alias grep='ug'
	alias egrep='ug -E'
	alias fgrep='ug -F'
	alias xzgrep='ug -z'
	alias xzegrep='ug -zE'
	alias xzfgrep='ug -zF'
fi

# Python Aliases
if [ "$(command -v python3)" ]; then
	alias python="python3"
	alias pip="pip3"
	alias venv="source .venv/bin/activate"
fi

# UV Aliases
if [ "$(command -v uv)" ]; then
	eval '$(uv generate-shell-completion ${SHELL})'
	eval '$(uvx --generate-shell-completion $SHELL)'
fi

# GTK themes
if command -v gsettings >/dev/null 2>&1; then
	gsettings set org.gnome.desktop.interface icon-theme 'Papirus' 2>/dev/null || true
	gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice' 2>/dev/null || true
	gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null || true
fi
