#!/bin/bash

set -eoux pipefail

echo "::group:: Copy Files"
dnf config-manager setopt keepcache=1
rsync -rvKl --chown=0:0 /ctx/system_files/. /
mkdir -p /var/roothome
echo "::endgroup::"

if ! rpm -q dnf5 >/dev/null; then
	rpm-ostree install dnf5 dnf5-plugins
fi

for repo in ${ENABLE_REPOS}; do
	dnf5 config-manager setopt "${repo}.enabled=1"
done

# SELinux policy store is moved to tmpfs (/dev/shm) for the duration of the
# build. libsemanage commits modules by renaming directories, which fails on
# overlayfs when a file descriptor is held open (EXDEV/ENOTEMPTY). A tmpfs
# store avoids this; it is copied back to /etc/selinux at the end.
restore_selinux_store() {
	if [ -d /dev/shm/selinux/targeted ]; then
		rm -rf /etc/selinux/targeted
		cp -a /dev/shm/selinux/targeted /etc/selinux/targeted
		sed -i 's|^store-root=.*|store-root=/etc/selinux|' /etc/selinux/semanage.conf
		rm -rf /dev/shm/selinux
	fi
}
trap restore_selinux_store EXIT

mkdir -p /dev/shm/selinux
cp -a /etc/selinux/targeted /dev/shm/selinux/targeted
sed -i 's|^store-root=.*|store-root=/dev/shm/selinux|' /etc/selinux/semanage.conf

/ctx/build_files/base/01-nvidia.sh
/ctx/build_files/base/02-services.sh
/ctx/build_files/base/03-packages.sh
/ctx/build_files/base/04-users.sh
/ctx/build_files/base/05-greeter.sh
/ctx/build_files/base/06-cleanup.sh
/ctx/build_files/base/07-anaconda.sh
/ctx/build_files/base/19-initramfs.sh
/ctx/build_files/base/20-tests.sh

rm -rf /run/* /run/.[!.]* /tmp/* /tmp/.[!.]* /var/tmp/* /var/tmp/.[!.]* 2>/dev/null || true
