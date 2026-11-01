#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

if [ "${NVIDIA:-true}" = "true" ]; then
	dnf5 -y install /tmp/akmods-rpms/*.rpm

	dnf5 config-manager setopt fedora-multimedia.enabled=1
	dnf5 config-manager setopt fedora-multimedia.priority=90

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

	cd /usr/lib/kernel/install.d
	mv 05-rpmostree.install 05-rpmostree.install.bak
	mv 50-dracut.install 50-dracut.install.bak
	printf '%s\n' '#!/bin/sh' 'exit 0' >05-rpmostree.install
	printf '%s\n' '#!/bin/sh' 'exit 0' >50-dracut.install
	chmod +x 05-rpmostree.install 50-dracut.install

	dnf5 -y install "${KERNEL_RPMS[@]}"

	mv -f 05-rpmostree.install.bak 05-rpmostree.install
	mv -f 50-dracut.install.bak 50-dracut.install
	cd -

	find /boot -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null || true

	dnf5 versionlock add kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra
	AKMODNV_PATH=/tmp/akmods-nv-rpms /tmp/akmods-nv-rpms/ublue-os/nvidia-install.sh
fi

echo "::endgroup::"
