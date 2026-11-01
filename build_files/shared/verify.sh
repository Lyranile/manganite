#!/bin/bash

set -euo pipefail

IMPORTANT_PACKAGES=(
	systemd
	pipewire
	wireplumber
	greetd
	noctalia
	noctalia-greeter
	umbriel-nightly
	xdg-desktop-portal-umbriel-nightly
	ghostty
	starship
	zsh
	just
	micro
	bat
	eza
	fzf
	zoxide
)

for package in "${IMPORTANT_PACKAGES[@]}"; do
	rpm -q "$package" >/dev/null || {
		echo "Missing package: $package... Exiting"
		exit 1
	}
done

echo "All required packages present."
