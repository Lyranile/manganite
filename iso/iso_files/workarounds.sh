#!/usr/bin/bash
set -exo pipefail

# Live ISO environment configuration for Manganite

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
if ! id liveuser >/dev/null 2>&1; then
    useradd -m -s /usr/bin/zsh liveuser 2>/dev/null || true
fi
passwd -d liveuser 2>/dev/null || true
chown -R liveuser:liveuser /home/liveuser 2>/dev/null || true

if [ -f /etc/greetd/config.toml ]; then
    if ! grep -q '^\[initial_session\]' /etc/greetd/config.toml; then
        cat >> /etc/greetd/config.toml <<'GREETD_EOF'

[initial_session]
command = "start-umbriel"
user = "liveuser"
GREETD_EOF
    fi
fi

# Live ISO must boot into the graphical session, not the anaconda installer target.
ln -sf /usr/lib/systemd/system/graphical.target /etc/systemd/system/default.target
