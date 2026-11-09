#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

systemd-sysusers

usermod -s /usr/bin/zsh root
if [ -f /etc/default/useradd ]; then
	sed -i 's|^SHELL=.*|SHELL=/usr/bin/zsh|' /etc/default/useradd
	grep -q '^SHELL=' /etc/default/useradd || echo 'SHELL=/usr/bin/zsh' >>/etc/default/useradd
fi

# Test user for QCOW2 testing (remove for production)
if ! id testuser >/dev/null 2>&1; then
    useradd -m -s /usr/bin/zsh testuser
fi
echo 'testuser:test' | chpasswd

echo "::endgroup::"
