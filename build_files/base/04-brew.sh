#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

BREW=/home/linuxbrew/.linuxbrew/bin/brew

# Homebrew packages to install (one per line; lines starting with # are ignored).
PACKAGES=(
	bat
	cava
	duf
	eza
	fastfetch
	fzf
	gcc
	git
	go-task
	just
	make
	micro
	pnpm
	rclone
	ripgrep
	starship
	tldr
	trash-cli
	uv
	yazi
	zoxide
	zsh
)

if [ -x "$BREW" ] && [ "${#PACKAGES[@]}" -gt 0 ]; then
	for pkg in "${PACKAGES[@]}"; do
		case "$pkg" in
		'' | \#*) continue ;;
		esac
		runuser -u linuxbrew -- "$BREW" install "$pkg" || true
	done
fi

echo "::endgroup::"
