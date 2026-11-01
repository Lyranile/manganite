#!/usr/bin/bash

set -eoux pipefail

echo "::group:: Copy Files"
dnf config-manager setopt keepcache=1
rsync -rvKl /ctx/system_files/. /
mkdir -p /var/roothome
echo "::endgroup::"

if ! rpm -q dnf5 >/dev/null; then
    rpm-ostree install dnf5 dnf5-plugins
fi

for repo in ${ENABLE_REPOS}; do
    dnf5 config-manager setopt "${repo}.enabled=1"
done

/ctx/build_files/01-packages.sh
/ctx/build_files/02-kernel-akmods.sh

if [ "${NVIDIA}" = "true" ]; then
    AKMODNV_PATH=/tmp/akmods-nv-rpms /tmp/akmods-nv-rpms/ublue-os/nvidia-install.sh
fi

/ctx/build_files/03-services.sh
/ctx/build_files/04-users.sh
/ctx/build_files/05-greeter.sh
/ctx/build_files/06-cleanup.sh
/ctx/build_files/19-initramfs.sh
/ctx/build_files/20-tests.sh

# Final cleanup so /run and /tmp are empty for bootc lint.
rm -rf /run/* /run/.[!.]* /tmp/* /tmp/.[!.]* /var/tmp/* /var/tmp/.[!.]* 2>/dev/null || true
