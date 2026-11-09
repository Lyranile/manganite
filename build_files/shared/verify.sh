#!/usr/bin/env bash

set -euo pipefail

IMPORTANT_PACKAGES=(
	systemd
	pipewire
	wireplumber
	greetd
	noctalia
	noctalia-greeter
	adw-gtk3-theme
	qt6ct
	umbriel-nightly
	xdg-desktop-portal-umbriel-nightly
	ghostty
	zsh
)

for package in "${IMPORTANT_PACKAGES[@]}"; do
	rpm -q "$package" >/dev/null || {
		echo "Missing package: $package... Exiting"
		exit 1
	}
done

echo "All required packages present."

test -f /etc/greetd/config.toml
test -f /var/lib/noctalia-greeter/greeter.toml
test -f /etc/skel/.profile
test -f /etc/skel/.zshrc

echo "All main image smoke tests passed."
