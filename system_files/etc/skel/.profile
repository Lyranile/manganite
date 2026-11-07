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
if [ "$(command -v micro)" ]; then
	export EDITOR="micro"
fi

# List Aliases
if [ "$(command -v eza)" ]; then
	alias ls="eza --git --icons=auto --classify --group-directories-first --time-style=long-iso --color-scale"
	alias l="eza --git --icons=auto --classify --group-directories-first --time-style=long-iso --color-scale --git-ignore"
	alias ll="eza --git --icons=auto --classify --group-directories-first --time-style=long-iso --color-scale --all --header --long"
	alias tree="eza --git --icons=auto --classify --group-directories-first --time-style=long-iso --color-scale --tree"
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

# Bottom Aliases
if [ "$(command -v btm)" ]; then
	alias top="btm"
fi

# Difference Aliases
if [ "$(command -v delta)" ]; then
	alias diff="delta"
fi

# Docker Aliases
if [ "$(command -v podman)" ]; then
	alias docker="podman"
fi
if [ "$(command -v podman-compose)" ]; then
	alias docker-compose="podman-compose"
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

# Bazaar Aliases
if [ "$(command -v flatpak)" ]; then
	alias bazaar='flatpak run --command=bazaar io.github.kolunmi.Bazaar'
fi

# UV Aliases
if [ "$(command -v uv)" ]; then
	eval '$(uv generate-shell-completion ${SHELL})'
	eval '$(uvx --generate-shell-completion $SHELL)'
fi

if [ "$(command -v flatpak)" ]; then
  flatpak_alias() {
  	if flatpak info "$2" >/dev/null 2>&1; then
  		eval "alias $1='flatpak run $2'"
  	fi
  }
  flatpak_alias pinta com.github.PintaProject.Pinta
  flatpak_alias flatseal com.github.tchx84.Flatseal
  flatpak_alias collision dev.geopjr.Collision
  flatpak_alias warehouse io.github.flattool.Warehouse
  flatpak_alias bazaar io.github.kolunmi.Bazaar
  flatpak_alias converter io.gitlab.adhami3310.Converter
  flatpak_alias impression io.gitlab.adhami3310.Impression
  flatpak_alias resources net.nokyan.Resources
  flatpak_alias waterfox net.waterfox.waterfox
  flatpak_alias baobab org.gnome.baobab
  flatpak_alias calculator org.gnome.Calculator
  flatpak_alias characters org.gnome.Characters
  flatpak_alias clocks org.gnome.clocks
  flatpak_alias decibels org.gnome.Decibels
  flatpak_alias fileroller org.gnome.FileRoller
  flatpak_alias logs org.gnome.Logs
  flatpak_alias loupe org.gnome.Loupe
  flatpak_alias papers org.gnome.Papers
  flatpak_alias showtime org.gnome.Showtime
  flatpak_alias snapshot org.gnome.Snapshot
  unset flatpak_alias
fi
