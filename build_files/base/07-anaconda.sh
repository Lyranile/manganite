#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

echo "install:x:0:0:root:/root:/usr/libexec/anaconda/run-anaconda" >> /etc/passwd
echo "install::14438:0:99999:7:::" >> /etc/shadow
passwd -d root || true

mkdir -p /etc/anaconda.repos.d
cp /etc/yum.repos.d/* /etc/anaconda.repos.d/ 2>/dev/null || true
cp /usr/share/dnf5/repos.d/* /etc/anaconda.repos.d/ 2>/dev/null || true

ln -sf /lib/systemd/system/anaconda.target /etc/systemd/system/default.target
rm -f /usr/lib/systemd/system-generators/systemd-gpt-auto-generator
ln -sf /usr/lib/systemd/system/anaconda-shell@.service /usr/lib/systemd/system/autovt@.service

mkdir -p /usr/lib/systemd/logind.conf.d
cat > /usr/lib/systemd/logind.conf.d/anaconda-shell.conf <<'EOF'
[Login]
ReserveVT=2
EOF

mkdir -p /etc/systemd/user/pipewire.service.d
cat > /etc/systemd/user/pipewire.service.d/allowroot.conf <<'EOF'
[Unit]
ConditionUser=
EOF

mkdir -p /etc/systemd/user/pipewire.socket.d
cat > /etc/systemd/user/pipewire.socket.d/allowroot.conf <<'EOF'
[Unit]
ConditionUser=
EOF

if [ -f /usr/share/anaconda/list-harddrives-stub ]; then
  mv /usr/share/anaconda/list-harddrives-stub /usr/bin/list-harddrives
fi

mkdir -p "$(realpath /root 2>/dev/null || echo /root)"
mkdir -p /root

echo "::endgroup::"
