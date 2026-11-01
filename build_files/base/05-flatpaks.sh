#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

PACKAGES=(
    com.github.tchx84.Flatseal
    io.github.kolunmi.Bazaar
    net.nokyan.Resources
    net.waterfox.waterfox
    org.gnome.baobab
    org.gnome.Calculator
    org.gnome.Characters
    org.gnome.clocks
    org.gnome.Decibels
    org.gnome.FileRoller
    org.gnome.gitlab.ilhooq.Bookup
    org.gnome.Logs
    org.gnome.Loupe
    org.gnome.Papers
    org.gnome.Showtime
    org.gnome.Snapshot
    re.sonny.Junction
)

if [ "${#PACKAGES[@]}" -gt 0 ]; then
    for app in "${PACKAGES[@]}"; do
        case "$app" in
            ''|\#*) continue ;;
        esac
        flatpak install --system --noninteractive flathub "$app" || true
    done
fi

echo "::endgroup::"
