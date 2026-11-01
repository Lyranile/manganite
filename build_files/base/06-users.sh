#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

systemd-sysusers

chsh -s /usr/bin/zsh root 2>/dev/null || true
if id user >/dev/null 2>&1; then
    chsh -s /usr/bin/zsh user 2>/dev/null || true
fi
if [ -f /etc/default/useradd ]; then
    sed -i 's|^SHELL=.*|SHELL=/usr/bin/zsh|' /etc/default/useradd
    grep -q '^SHELL=' /etc/default/useradd || echo 'SHELL=/usr/bin/zsh' >> /etc/default/useradd
fi

echo "::endgroup::"
