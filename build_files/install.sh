#!/bin/bash

set -euo pipefail

# Copy the contents of system_files/ of the git repo to /
cp -rv /ctx/system_files/. /

# make root's home
mkdir -p /var/roothome

# Install dnf5 if not installed
if ! rpm -q dnf5 >/dev/null; then
    rpm-ostree install dnf5 dnf5-plugins
fi

# Enable extra repos that were shipped in system_files/etc/yum.repos.d
for repo in ${ENABLE_REPOS}; do
    dnf5 config-manager setopt "${repo}.enabled=1"
done

# ---------- Image packages ----------
dnf5 -y install \
    umbriel-nightly xdg-desktop-portal-umbriel-nightly noctalia \
    starship ghostty \
    os-prober polkit greetd just make pnpm gcc git uv go-task \
    fastfetch zoxide micro cava yazi bat duf eza fzf zsh \
    brightnessctl i2c-tools playerctl \
    bibata-cursor-theme papirus-icon-theme \
    android-tools

# ---------- Prebuilt akmods (kernel + nvidia driver) ----------
if [ "${NVIDIA:-true}" = "true" ]; then
    # Install prebuilt open NVIDIA akmods.
    dnf5 -y install /tmp/akmods-rpms/*.rpm

    # Use negativo17 for 3rd party packages with higher priority than default
    dnf5 config-manager setopt fedora-multimedia.enabled=1
    dnf5 config-manager setopt fedora-multimedia.priority=90

    # Use signed kernel and versionlock: swap the stock kernel for the
    # akmod-built kernel that the prebuilt NVIDIA module was built against.
    for pkg in kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra; do
        rpm --erase "$pkg" --nodeps
    done

    KERNEL_VERSION="$(find /tmp/kernel-rpms/kernel-core-*.rpm -prune -printf "%f\n" | sed 's/kernel-core-//g;s/.rpm//g')"
    KERNEL_RPMS=(
        "/tmp/kernel-rpms/kernel-${KERNEL_VERSION}.rpm"
        "/tmp/kernel-rpms/kernel-core-${KERNEL_VERSION}.rpm"
        "/tmp/kernel-rpms/kernel-modules-${KERNEL_VERSION}.rpm"
        "/tmp/kernel-rpms/kernel-modules-core-${KERNEL_VERSION}.rpm"
        "/tmp/kernel-rpms/kernel-modules-extra-${KERNEL_VERSION}.rpm"
    )

    # Bypass rpm-ostree/dracut kernel-install hooks while installing the kernel.
    cd /usr/lib/kernel/install.d \
        && mv 05-rpmostree.install 05-rpmostree.install.bak \
        && mv 50-dracut.install 50-dracut.install.bak \
        && printf '%s\n' '#!/bin/sh' 'exit 0' > 05-rpmostree.install \
        && printf '%s\n' '#!/bin/sh' 'exit 0' > 50-dracut.install \
        && chmod +x 05-rpmostree.install 50-dracut.install

    dnf5 -y install "${KERNEL_RPMS[@]}"

    mv -f 05-rpmostree.install.bak 05-rpmostree.install \
        && mv -f 50-dracut.install.bak 50-dracut.install
    cd -

    dnf5 versionlock add kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra
fi
