#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

dnf5 remove -y fedora-flathub-remote 2>/dev/null || true
dnf5 remove -y firefox 2>/dev/null || true
mkdir -p /etc/flatpak/remotes.d/
curl --retry 3 -Lo /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo
mv -f /usr/lib/systemd/system/flatpak-add-flathub-repos.service /usr/lib/systemd/system/flatpak-add-fedora-repos.service 2>/dev/null || true

systemctl set-default graphical.target &&
	systemctl disable getty@tty1 2>/dev/null || true
systemctl enable rpm-ostreed-automatic.timer flatpak-system-update.timer flatpak-preinstall.service &&
	systemctl --global enable flatpak-user-update.timer &&
	systemctl enable flatpak-nuke-fedora.service

cp /usr/share/ublue-os/update-services/etc/rpm-ostreed.conf /etc/rpm-ostreed.conf 2>/dev/null || true &&
	sed -Ei "s/secure_path = (.*)/secure_path = \1:\/home\/linuxbrew\/.linuxbrew\/bin/" /etc/sudoers

if [ -f /etc/default/grub ]; then
	sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=60/' /etc/default/grub
	grep -q '^GRUB_DEFAULT=' /etc/default/grub || echo 'GRUB_DEFAULT=saved' >>/etc/default/grub
	grep -q '^GRUB_SAVEDEFAULT=' /etc/default/grub || echo 'GRUB_SAVEDEFAULT=true' >>/etc/default/grub
	sed -i 's/^GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
	grep -q '^GRUB_DISABLE_OS_PROBER=' /etc/default/grub || echo 'GRUB_DISABLE_OS_PROBER=false' >>/etc/default/grub
fi

echo "::endgroup::"
