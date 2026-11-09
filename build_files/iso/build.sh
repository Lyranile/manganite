#!/usr/bin/bash

set -exo pipefail

{ export PS4='+( ${BASH_SOURCE}:${LINENO} ): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'; } 2>/dev/null

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create the directory that /root is symlinked to
mkdir -p "$(realpath /root)"

# bwrap tries to write /proc/sys/user/max_user_namespaces which is mounted as ro
mount -o remount,rw /proc/sys

# /var is a tmpfs mount during build; ensure required dirs exist
mkdir -p /var/tmp /var/cache /var/lib /var/roothome

# Stage the SELinux policy store on tmpfs
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

# Install flatpaks if list exists
if [[ -f "$SCRIPT_DIR/flatpaks.list" ]]; then
    echo "Installing flatpaks..."
    curl --retry 3 -Lo /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo
    grep -v '^#' "$SCRIPT_DIR/flatpaks.list" | grep -v '^$' | xargs -r flatpak install -y --noninteractive || true
fi

# Pull the container image to be installed
if [[ -n "${BASE_IMAGE:-}" ]]; then
    if ! podman image exists "${BASE_IMAGE}" 2>/dev/null; then
        podman pull "${BASE_IMAGE}"
    fi
else
    IMAGE_INFO="$(cat /usr/share/ublue-os/image-info.json)"
    IMAGE_TAG="$(jq -c -r '."image-tag"' <<<"$IMAGE_INFO")"
    IMAGE_REF="$(jq -c -r '."image-ref"' <<<"$IMAGE_INFO")"
    IMAGE_REF="${IMAGE_REF##*://}"
    podman pull "${IMAGE_REF}:${IMAGE_TAG}"
fi

ANACONDA=(
    anaconda-live
    anaconda-webui
)

dnf5 install -y \
    dracut-live \
    livesys-scripts \
    git \
    jq \
    rsync \
    desktop-file-utils \
    libblockdev-btrfs \
    libblockdev-lvm \
    libblockdev-dm \
    "${ANACONDA[@]}" \
    slitherer

kernel=$(find /usr/lib/modules -maxdepth 1 -type d -printf '%P\n' | grep . | head -1)
DRACUT_NO_XATTR=1 dracut -v --force --zstd --reproducible --no-hostonly \
    --add "dmsquash-live dmsquash-live-autooverlay" \
    "/usr/lib/modules/${kernel}/initramfs.img" "${kernel}"

# Configure livesys-scripts for Umbriel
if grep -q '^livesys_session=' /etc/sysconfig/livesys 2>/dev/null; then
    sed -i "s/^livesys_session=.*/livesys_session=umbriel/" /etc/sysconfig/livesys
else
    echo "livesys_session=umbriel" >> /etc/sysconfig/livesys
fi
systemctl enable livesys.service livesys-late.service

# Install the Umbriel livesys script
install -m 0755 "$SCRIPT_DIR/livesys-umbriel" /usr/libexec/livesys/sessions.d/livesys-umbriel

# Run the configure/postrootfs hook
export BASE_IMAGE="${BASE_IMAGE:-}"
bash "$SCRIPT_DIR/live.sh" && \
bash "$SCRIPT_DIR/anaconda.sh" && \
bash "$SCRIPT_DIR/tests.sh"

# image-builder needs gcdx64.efi / grub modules
_arch=$(uname -m)
if [[ $_arch == "x86_64" ]]; then
    dnf5 install -y grub2-efi-x64-cdboot
elif [[ $_arch == "aarch64" ]]; then
    dnf5 install -y grub2-efi-aa64-modules
fi

# image-builder expects the EFI directory to be in /boot/efi
mkdir -p /boot/efi
cp -av /usr/lib/efi/*/*/EFI /boot/efi/

_arch=$(uname -m)
if [[ $_arch == "x86_64" ]]; then
    cp -v /boot/efi/EFI/fedora/grubx64.efi /boot/efi/EFI/BOOT/fbx64.efi
elif [[ $_arch == "aarch64" ]]; then
    cp -v /boot/efi/EFI/fedora/grubaa64.efi /boot/efi/EFI/BOOT/fbaa64.efi
fi

# Set the timezone to UTC
rm -f /etc/localtime
systemd-firstboot --timezone UTC

# Mount a larger tmpfs to /var/tmp at boot time
mkdir -p /var/tmp
install -Dm644 "$SCRIPT_DIR/templates/var-tmp.mount" /etc/systemd/system/var-tmp.mount
systemctl enable var-tmp.mount

# Copy in the iso config for image-builder
mkdir -p /usr/lib/bootc-image-builder
cp "$SCRIPT_DIR/iso.yaml" /usr/lib/bootc-image-builder/iso.yaml

# Clean up dnf cache to save space
dnf5 clean all
