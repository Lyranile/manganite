#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

PACKAGES=(
	android-tools
	bat
	bibata-cursor-theme
	brightnessctl
	cava
	duf
	eza
	fastfetch
	fzf
	gcc
	ghostty
	git
	go-task
	greetd
	i2c-tools
	just
	make
	micro
	noctalia
	noctalia-greeter
	os-prober
	papirus-icon-theme
	playerctl
	pnpm
	polkit
	starship
	umbriel-nightly
	uv
	xdg-desktop-portal-umbriel-nightly
	yazi
	zoxide
	zsh
)

if [ "${#PACKAGES[@]}" -gt 0 ]; then
	dnf5 -y install "${PACKAGES[@]}"
fi

# Install zinit into the skeleton home so it is available without a runtime clone.
ZINIT_HOME="/etc/skel/.local/share/zinit/zinit.git"
mkdir -p "$(dirname "$ZINIT_HOME")"
[ ! -d "$ZINIT_HOME/.git" ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"

echo "::endgroup::"
