#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

systemd-sysusers

usermod -s /usr/bin/zsh root
if [ -f /etc/default/useradd ]; then
	sed -i 's|^SHELL=.*|SHELL=/usr/bin/zsh|' /etc/default/useradd
	grep -q '^SHELL=' /etc/default/useradd || echo 'SHELL=/usr/bin/zsh' >>/etc/default/useradd
fi

# Optional test user for local VM testing (disabled in production)
if [[ "${LIVE_USER:-false}" == "true" ]]; then
	mkdir -p /usr/lib/sysusers.d
	echo 'u liveuser 1000:1000 "Live User" /home/liveuser /usr/bin/zsh' > /usr/lib/sysusers.d/99-liveuser-test.conf
	systemd-sysusers
	if ! id liveuser >/dev/null 2>&1; then
		useradd -m -s /usr/bin/zsh liveuser
	fi
	mkdir -p /home/liveuser
	chown liveuser:liveuser /home/liveuser
	passwd -d liveuser || true

	# Auto-login for testing (no password prompt)
	install -Dm644 /ctx/build_files/shared/greetd.toml /etc/greetd/config.toml
fi

echo "::endgroup::"
