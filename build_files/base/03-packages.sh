#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

dnf5 -y install \
	adw-gtk3-theme \
	bibata-cursor-theme \
	dracut-config-generic \
	file-roller-nautilus \
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
	plymouth \
	podman \
	polkit \
	qt6ct \
	sushi \
	umbriel-nightly \
	xdg-desktop-portal-umbriel-nightly \
	zsh

mkdir -p /boot/efi
cp -ra /usr/lib/efi/*/*/EFI /boot/efi 2>/dev/null || true

mkdir -p /etc/skel/.config
rm -rf /var/roothome/.cache

echo "::endgroup::"
