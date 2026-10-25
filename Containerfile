# Manganite bootc image - image-template pattern
#
# Non-NVIDIA (default):
#   podman build -f Containerfile -t manganite .
#
# NVIDIA (prebuilt ublue akmods; same flow as ublue-os/main):
#   podman build --build-arg NVIDIA=true -f Containerfile -t manganite .

# Options
ARG BASE_IMAGE_NAME="base-main"
ARG BASE_IMAGE_TAG="44"
ARG BASE_IMAGE="ghcr.io/ublue-os/${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}"
ARG NVIDIA="false"

# Repositories to enable
ARG ENABLE_REPOS="terra"

# Packages from Fedora repos
ARG INSTALL_PACKAGES="git \
  papirus-icon-theme \
  bibata-cursor-theme \
  xdg-desktop-portal-gtk \
  xdg-desktop-portal-wlr \
  brightnessctl \
  wl-clipboard \
  i2c-tools \
  os-prober \
  playerctl \
  cliphist \
  polkit \
  android-tools \
  fastfetch \
  go-task \
  cava \
  just \
  make \
  pnpm \
  gcc \
  uv \
  alacritty \
  starship \
  mangowm \
  zoxide \
  micro \
  atuin \
  procs \
  yazi \
  zsh \
  eza \
  bat \
  fzf \
  duf"

# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY system_files /system_files

FROM ghcr.io/ublue-os/akmods:main-${BASE_IMAGE_TAG} AS akmods
FROM ghcr.io/ublue-os/akmods-nvidia-open:main-${BASE_IMAGE_TAG} AS akmods-nvidia

FROM ${BASE_IMAGE}

ARG NVIDIA
ARG ENABLE_REPOS
ARG INSTALL_PACKAGES
# Always defined: akmods' nvidia-install.sh runs under `set -u` and reads it
# unguarded (upstream declares/accepts it in exactly this way; only
# silverblue/kinoite get extra packages, so any value is fine for us)
ARG IMAGE_NAME="${IMAGE_NAME:-manganite}"

### MODIFICATIONS

# Copy system files to the root filesystem
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    cp -rv /ctx/system_files/. /

# Ensure the dnf5 plugin commands exist
RUN --mount=type=cache,dst=/var/cache/libdnf5 \
    --mount=type=cache,dst=/var/log \
    dnf -y install dnf5-plugins

# Enable extra repos that were shipped in system_files/etc/yum.repos.d
RUN --mount=type=cache,dst=/var/cache/libdnf5 \
    for repo in ${ENABLE_REPOS}; do \
        dnf -y config-manager setopt "${repo}.enabled=1"; \
    done

# Install packages from repositories
RUN --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf -y install ${INSTALL_PACKAGES}

# Enable DMS and install minimal dependencies
RUN --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf -y copr enable duxlabs/dms && \
    dnf -y copr enable duxlabs/dux && \
    dnf -y install dms --setopt=install_weak_deps=False

# Disable COPRs so they do not stay enabled on the final system
RUN --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf -y copr disable duxlabs/dms && \
    dnf -y copr disable duxlabs/dux

# Install prebuilt open NVIDIA akmods.
RUN --mount=type=bind,from=akmods,source=/kernel-rpms,target=/tmp/kernel-rpms \
    --mount=type=bind,from=akmods,source=/rpms/ublue-os,target=/tmp/akmods-rpms \
    --mount=type=bind,from=akmods-nvidia,source=/rpms,target=/tmp/akmods-nv-rpms \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    if [ "${NVIDIA}" = "true" ]; then \
        dnf -y install /tmp/akmods-rpms/*.rpm && \
        dnf config-manager setopt fedora-multimedia.enabled=1 && \
        dnf config-manager setopt fedora-multimedia.priority=90 && \
        for pkg in kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra; do \
            rpm --erase "$pkg" --nodeps; \
        done && \
        KERNEL_VERSION="$(find /tmp/kernel-rpms/kernel-core-*.rpm -prune -printf "%f\n" | sed 's/kernel-core-//g;s/.rpm//g')" && \
        KERNEL_RPMS="/tmp/kernel-rpms/kernel-${KERNEL_VERSION}.rpm /tmp/kernel-rpms/kernel-core-${KERNEL_VERSION}.rpm /tmp/kernel-rpms/kernel-modules-${KERNEL_VERSION}.rpm /tmp/kernel-rpms/kernel-modules-core-${KERNEL_VERSION}.rpm /tmp/kernel-rpms/kernel-modules-extra-${KERNEL_VERSION}.rpm" && \
        cd /usr/lib/kernel/install.d && \
        mv 05-rpmostree.install 05-rpmostree.install.bak && \
        mv 50-dracut.install 50-dracut.install.bak && \
        printf '%s\n' '#!/bin/sh' 'exit 0' > 05-rpmostree.install && \
        printf '%s\n' '#!/bin/sh' 'exit 0' > 50-dracut.install && \
        chmod +x 05-rpmostree.install 50-dracut.install && \
        dnf -y install ${KERNEL_RPMS} && \
        mv -f 05-rpmostree.install.bak 05-rpmostree.install && \
        mv -f 50-dracut.install.bak 50-dracut.install && \
        dnf -y versionlock add kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra && \
        cd - && \
        AKMODNV_PATH=/tmp/akmods-nv-rpms /tmp/akmods-nv-rpms/ublue-os/nvidia-install.sh; \
    fi

# Configure Flatpak
RUN --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf remove -y fedora-flathub-remote 2>/dev/null || true && \
    mkdir -p /etc/flatpak/remotes.d/ && \
    curl --retry 3 -Lo /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo && \
    mv -f /usr/lib/systemd/system/flatpak-add-flathub-repos.service /usr/lib/systemd/system/flatpak-add-fedora-repos.service 2>/dev/null || true

# Enable base variant services getty on tty1, rpm-ostree timers, flatpak
RUN systemctl enable getty@tty1 && \
    systemctl enable rpm-ostreed-automatic.timer flatpak-system-update.timer && \
    systemctl --global enable flatpak-user-update.timer && \
    systemctl enable flatpak-nuke-fedora.service

# Configure staged updates
RUN cp /usr/share/ublue-os/update-services/etc/rpm-ostreed.conf /etc/rpm-ostreed.conf 2>/dev/null || true && \
    sed -Ei "s/secure_path = (.*)/secure_path = \1:\/home\/linuxbrew\/.linuxbrew\/bin/" /etc/sudoers

# Configure GRUB
RUN if [ -f /etc/default/grub ]; then \
        sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=60/' /etc/default/grub; \
        grep -q '^GRUB_DEFAULT=' /etc/default/grub || echo 'GRUB_DEFAULT=saved' >> /etc/default/grub; \
        grep -q '^GRUB_SAVEDEFAULT=' /etc/default/grub || echo 'GRUB_SAVEDEFAULT=true' >> /etc/default/grub; \
        sed -i 's/^GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub; \
        grep -q '^GRUB_DISABLE_OS_PROBER=' /etc/default/grub || echo 'GRUB_DISABLE_OS_PROBER=false' >> /etc/default/grub; \
    fi

# Cleanup temporary files
RUN --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf -y clean all && \
    rm -rf /tmp/* /var/tmp/*

# Lint container files
RUN bootc container lint
