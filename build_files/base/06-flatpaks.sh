#!/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

flatpak install --system --noninteractive flathub \
	com.github.tchx84.Flatseal \
	io.github.kolunmi.Bazaar \
	net.nokyan.Resources \
	org.gnome.baobab \
	org.gnome.Calculator \
	org.gnome.Characters \
	org.gnome.clocks \
	org.gnome.Decibels \
	org.gnome.FileRoller \
	org.gnome.Logs \
	org.gnome.Loupe \
	org.gnome.Papers \
	org.gnome.Showtime \
	org.gnome.Snapshot

echo "::endgroup::"
