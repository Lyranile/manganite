#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

dnf5 -y install \
	bibata-cursor-theme \
	brightnessctl \
	file-roller-nautilus \
	gcc \
	ghostty \
	ghostty-nautilus \
	git \
	greetd \
	i2c-tools \
	nautilus \
	nautilus-extensions \
	noctalia \
	noctalia-greeter \
	os-prober \
	papers-nautilus \
	papirus-icon-theme \
	playerctl \
	podman \
	polkit \
	sushi \
	umbriel-nightly \
	xdg-desktop-portal-umbriel-nightly \
	yazi \
	zsh

mkdir -p /etc/skel/.config
rm -rf /var/roothome/.cache

echo "::endgroup::"
