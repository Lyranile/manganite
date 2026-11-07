#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

dnf5 -y install \
	anaconda \
	anaconda-dracut \
	anaconda-gui \
	anaconda-install-img-deps \
	bibata-cursor-theme \
	dracut-config-generic \
	dracut-live \
	dracut-network \
	file-roller-nautilus \
	gcc \
	ghostty \
	ghostty-nautilus \
	git \
	greetd \
	grub2-efi-x64-cdboot \
	i2c-tools \
	isomd5sum \
	nautilus \
	nautilus-extensions \
	net-tools \
	noctalia \
	noctalia-greeter \
	os-prober \
	papers-nautilus \
	papirus-icon-theme \
	plymouth \
	podman \
	polkit \
	squashfs-tools \
	shim \
	sushi \
	umbriel-nightly \
	xdg-desktop-portal-umbriel-nightly \
	xorriso \
	zsh

mkdir -p /boot/efi
cp -ra /usr/lib/efi/*/*/EFI /boot/efi 2>/dev/null || true

mkdir -p /etc/skel/.config
rm -rf /var/roothome/.cache

echo "::endgroup::"
