#!/usr/bin/bash
set -exo pipefail

# Live ISO workarounds for Manganite

# Disable services that should not run in the live environment
for s in \
    rpm-ostreed-automatic.timer \
    flatpak-system-update.timer \
    flatpak-user-update.timer \
    brew-bundle.service; do
    systemctl disable "$s" 2>/dev/null || true
done

# Ensure liveuser home exists
mkdir -p /home/liveuser
chown liveuser:liveuser /home/liveuser 2>/dev/null || true
