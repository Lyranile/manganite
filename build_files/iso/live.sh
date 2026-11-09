#!/usr/bin/bash
set -exo pipefail

# Live ISO environment configuration for Manganite

# Disable services that should not run in the live environment
for service in \
	rpm-ostreed-automatic.timer \
	flatpak-system-update.timer \
	flatpak-user-update.timer \
	brew-bundle.service; do
	systemctl disable "$service" 2>/dev/null || true
done

# Ensure liveuser exists for autologin
if ! id liveuser >/dev/null 2>&1; then
	useradd -m -s /usr/bin/zsh liveuser
fi
echo 'liveuser:live' | chpasswd
chown -R liveuser:liveuser /home/liveuser

# Use the dedicated live greeter config (with autologin)
install -Dm644 /src/build_files/iso/greetd-live.toml /etc/greetd/config.toml

# Live ISO must boot into the graphical session, not the anaconda installer target.
ln -sf /usr/lib/systemd/system/graphical.target /etc/systemd/system/default.target
