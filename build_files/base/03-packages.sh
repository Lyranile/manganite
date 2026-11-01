#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

dnf5 -y install \
	bat \
	bibata-cursor-theme \
	bottom \
	brightnessctl \
	cava \
	duf \
	eza \
	fastfetch \
	fd-find \
	fzf \
	gcc \
	ghostty \
	git \
	go-task \
	greetd \
	i2c-tools \
	just \
	make \
	micro \
	noctalia \
	noctalia-greeter \
	os-prober \
	papirus-icon-theme \
	playerctl \
	pnpm \
	polkit \
	rclone \
	ripgrep \
	starship \
	tealdeer \
	trash-cli \
	umbriel-nightly \
	uv \
	xdg-desktop-portal-umbriel-nightly \
	yazi \
	zoxide \
	zsh

ZINIT_HOME="/etc/skel/.local/share/zinit/zinit.git"
mkdir -p "$(dirname "$ZINIT_HOME")"
[ ! -d "$ZINIT_HOME/.git" ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"

# Generate starship tokyo-night preset config (once, at build time)
mkdir -p /etc/skel/.config
starship preset tokyo-night -o /etc/skel/.config/starship.toml

echo "::endgroup::"
