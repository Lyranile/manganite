#!/usr/bin/bash

set -eoux pipefail

echo "::group:: Copy Files"

# Speeds up local builds and workaround network flakes, mainly for COPR and negativo
dnf config-manager setopt keepcache=1

# Copy Files to Container
rsync -rvKl /ctx/system_files/. /

mkdir -p /var/roothome

echo "::endgroup::"

# Install dnf5 if not installed
if ! rpm -q dnf5 >/dev/null; then
    rpm-ostree install dnf5 dnf5-plugins
fi

# Enable extra repos that were shipped in system_files/etc/yum.repos.d
for repo in ${ENABLE_REPOS}; do
    dnf5 config-manager setopt "${repo}.enabled=1"
done

# Install Additional Packages
/ctx/build_files/01-packages.sh

# Install Kernel and Akmods
/ctx/build_files/02-kernel-akmods.sh

# Install NVIDIA driver (from akmods-nvidia build stage)
if [ "${NVIDIA}" = "true" ]; then
    AKMODNV_PATH=/tmp/akmods-nv-rpms /tmp/akmods-nv-rpms/ublue-os/nvidia-install.sh
fi

# Systemd Services and GRUB
/ctx/build_files/03-services.sh

# Users
/ctx/build_files/04-users.sh

# Greeter State
/ctx/build_files/05-greeter.sh

echo "::group:: Cleanup"
/ctx/build_files/06-cleanup.sh
echo "::endgroup::"

# Regenerate initramfs
/ctx/build_files/19-initramfs.sh

# Simple Tests
/ctx/build_files/20-tests.sh
