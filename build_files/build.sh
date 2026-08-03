#!/usr/bin/env bash
# manganite - Bazzite GNOME NVIDIA base + mangowm + DMS
set -eoux pipefail

source /ctx/build_files/packages.sh

SRC=/ctx/system_files

# Install packages (DMS comes from its COPR only when enabled)
dnf -y install "${FEDORA_PACKAGES[@]}"
dnf install --nogpgcheck --repofrompath \
    'terra,https://repos.fyralabs.com/terra$releasever' terra-release
dnf -y install "${TERRA_PACKAGES[@]}"

if [[ "$DMS" == "true" ]]; then
    dnf -y copr enable "$DMS_COPR_NAME"
    dnf -y install "${DMS_COPR_PACKAGES[@]}"
    dnf -y copr disable "$DMS_COPR_NAME"
fi

# Ship files: system_files/ mirrors the image root; etc/skel/ is copied
# into each new user's ~ by useradd, which is where dotfiles belong.
cp -a "$SRC/usr/." /usr/
cp -a "$SRC/etc/." /etc/

# Without mangowm, run DMS on every user session instead of the mango one
if [[ "$DMS" == "true" && "$MANGOWM" != "true" ]]; then
    systemctl --global enable dms
fi

systemctl enable gdm

# Disable repos added only for this build
for repo in /etc/yum.repos.d/terra*.repo \
            /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:*.repo; do
    [ -f "$repo" ] && sed -i 's@enabled=1@enabled=0@g' "$repo"
done
