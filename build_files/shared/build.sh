#!/bin/bash

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

/ctx/build_files/base/01-nvidia.sh
/ctx/build_files/base/02-services.sh
/ctx/build_files/base/03-packages.sh
/ctx/build_files/base/04-users.sh
/ctx/build_files/base/05-greeter.sh
/ctx/build_files/base/06-flatpaks.sh
/ctx/build_files/base/07-cleanup.sh
/ctx/build_files/base/19-initramfs.sh
/ctx/build_files/base/20-tests.sh

rm -rf /run/* /run/.[!.]* /tmp/* /tmp/.[!.]* /var/tmp/* /var/tmp/.[!.]* 2>/dev/null || true
