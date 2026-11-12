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
if [[ "${TEST_USER:-false}" == "true" ]]; then
	if ! id manganite >/dev/null 2>&1; then
		useradd -m -s /usr/bin/zsh manganite
	fi
	echo 'manganite:manganite' | chpasswd
fi

echo "::endgroup::"
