#!/usr/bin/bash
set -exo pipefail

# Configure Anaconda for the live ISO
mkdir -p /etc/anaconda/profile.d
cat >/etc/anaconda/profile.d/manganite.conf <<'EOF'
[Profile]
profile_id = manganite

[Profile Detection]
os_id = manganite

[User Interface]
hidden_webui_pages =
    network
EOF

# Ensure the Anaconda WebUI is available
dnf5 install -y anaconda-webui slitherer || true
