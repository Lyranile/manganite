# Allow build scripts to be referenced without being copied into the final image

ARG BASE_IMAGE_NAME="base-main"
ARG BASE_IMAGE_TAG="44"
ARG BASE_IMAGE="ghcr.io/ublue-os/${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}"

# Repos to enable permanently for the entire OS
ARG ENABLE_REPOS="terra"

# Packages to install (Fedora repos + the repos listed above)
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

ARG AKMODS_FLAVOR="main"

FROM ghcr.io/ublue-os/akmods:${AKMODS_FLAVOR}-${BASE_IMAGE_TAG} AS akmods
FROM ghcr.io/ublue-os/akmods-nvidia-open:${AKMODS_FLAVOR}-${BASE_IMAGE_TAG} AS akmods-nvidia

FROM scratch AS ctx
COPY build_files /

FROM ${BASE_IMAGE}

# Build args declared before the first FROM are not in scope after it
ARG ENABLE_REPOS
ARG INSTALL_PACKAGES
ARG AKMODS_FLAVOR
ARG BASE_IMAGE_TAG

COPY --from=ctx / /

# Enable the extra repos for the whole OS
RUN --mount=type=cache,dst=/var/cache/libdnf5 \
    for repo in ${ENABLE_REPOS}; do \
        dnf -y config-manager setopt "${repo}.enabled=1"; \
    done

# Install packages from Fedora and enabled repos
RUN --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf -y install ${INSTALL_PACKAGES}

# DMS (DankMaterialShell) from COPR, minimal deps
RUN --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf -y copr enable duxlabs/dux && \
    dnf -y copr enable duxlabs/dms && \
    dnf -y install dms --setopt=install_weak_deps=False

# Bind DMS to the MangoWC session
RUN mkdir -p /usr/lib/systemd/user/mango-session.target.wants && \
    ln -sf /usr/lib/systemd/user/dms.service /usr/lib/systemd/user/mango-session.target.wants/dms.service || true

# Configure Flatpak (remove Fedora remote, add Flathub)
RUN --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf remove -y fedora-flathub-remote 2>/dev/null || true && \
    mkdir -p /etc/flatpak/remotes.d/ && \
    curl --retry 3 -Lo /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo && \
    mv -f /usr/lib/systemd/system/flatpak-add-flathub-repos.service /usr/lib/systemd/system/flatpak-add-fedora-repos.service 2>/dev/null || true

# Enable base variant services
RUN systemctl enable getty@tty1 && \
    systemctl enable rpm-ostreed-automatic.timer flatpak-system-update.timer && \
    systemctl --global enable flatpak-user-update.timer

# Configure staged updates and sudo
RUN cp /usr/share/ublue-os/update-services/etc/rpm-ostreed.conf /etc/rpm-ostreed.conf 2>/dev/null || true && \
    sed -Ei "s/secure_path = (.*)/secure_path = \1:\/home\/linuxbrew\/.linuxbrew\/bin/" /etc/sudoers

# NVIDIA: install via ublue's prebuilt akmods
RUN --mount=type=cache,dst=/var/cache/libdnf5 \
    --mount=type=bind,from=akmods,src=/rpms/common,dst=/tmp/akmods-rpms \
    --mount=type=bind,from=akmods,src=/kernel-rpms,dst=/tmp/kernel-rpms \
    --mount=type=bind,from=akmods-nvidia,src=/rpms,dst=/tmp/akmods-nv-rpms \
    for pkg in kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra; do \
        rpm --erase "$pkg" --nodeps 2>/dev/null || true; \
    done && \
    dnf -y install --setopt=tsflags=noscripts /tmp/kernel-rpms/kernel-*.rpm && \
    (dnf -y versionlock add kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra 2>/dev/null || true) && \
    IMAGE_NAME="SKIP_PACKAGE_INSTALL" AKMODNV_PATH=/tmp/akmods-nv-rpms /tmp/akmods-nv-rpms/ublue-os/nvidia-install.sh && \
    echo 'add_drivers+=("nvidia")' > /etc/libdnf5/protected.d/nvidia.conf && \
    rm -f /usr/bin/chsh /usr/bin/lchsh

# Rebuild initramfs
RUN --mount=type=cache,dst=/var/cache/libdnf5 \
    KVER="$(rpm -q --queryformat='%{evr}.%{arch}' kernel-core)" && \
    /usr/bin/dracut --no-hostonly --kver "$KVER" --reproducible --zstd -v --add ostree -f "/usr/lib/modules/$KVER/initramfs.img" && \
    chmod 0600 "/usr/lib/modules/$KVER/initramfs.img"

# GRUB configuration
RUN if [ -f /etc/default/grub ]; then \
        sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=60/' /etc/default/grub; \
        grep -q '^GRUB_DEFAULT=' /etc/default/grub || echo 'GRUB_DEFAULT=saved' >> /etc/default/grub; \
        grep -q '^GRUB_SAVEDEFAULT=' /etc/default/grub || echo 'GRUB_SAVEDEFAULT=true' >> /etc/default/grub; \
        sed -i 's/^GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub; \
        grep -q '^GRUB_DISABLE_OS_PROBER=' /etc/default/grub || echo 'GRUB_DISABLE_OS_PROBER=false' >> /etc/default/grub; \
    fi

# Cleanup
RUN rm -rf /tmp/* /var/tmp/* 2>/dev/null || true
CMD ["/sbin/init"]

# Linting
RUN bootc container lint
