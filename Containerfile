# Image-template pattern: derive from ublue base image
# Use base-main (minimal, no DE) or base-nvidia (with NVIDIA pre-built)
#
# Non-NVIDIA (default):
#   podman build -f Containerfile -t manganite .
#
# NVIDIA:
#   podman build --build-arg BASE_IMAGE_NAME=base-nvidia --build-arg BASE_IMAGE_TAG=latest -f Containerfile -t manganite .

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

FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files

FROM ${BASE_IMAGE}

### MODIFICATIONS

# Copy system files overlay
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    cp -avf /ctx/system_files/. /

# Enable extra repos
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

# Configure Flatpak (remove Fedora remote, add Flathub)
RUN --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf remove -y fedora-flathub-remote 2>/dev/null || true && \
    mkdir -p /etc/flatpak/remotes.d/ && \
    curl --retry 3 -Lo /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo && \
    mv -f /usr/lib/systemd/system/flatpak-add-flathub-repos.service /usr/lib/systemd/system/flatpak-add-fedora-repos.service 2>/dev/null || true

# Enable base variant services (getty, update timers)
RUN systemctl enable getty@tty1 && \
    systemctl enable rpm-ostreed-automatic.timer flatpak-system-update.timer && \
    systemctl --global enable flatpak-user-update.timer

# Configure staged updates and sudo
RUN cp /usr/share/ublue-os/update-services/etc/rpm-ostreed.conf /etc/rpm-ostreed.conf 2>/dev/null || true && \
    sed -Ei "s/secure_path = (.*)/secure_path = \1:\/home\/linuxbrew\/.linuxbrew\/bin/" /etc/sudoers

# Disable COPRs so they don't end up enabled on the final image
RUN --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf -y copr disable duxlabs/dms duxlabs/dux 2>/dev/null || true

# GRUB configuration
RUN if [ -f /etc/default/grub ]; then \
        sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=60/' /etc/default/grub; \
        grep -q '^GRUB_DEFAULT=' /etc/default/grub || echo 'GRUB_DEFAULT=saved' >> /etc/default/grub; \
        grep -q '^GRUB_SAVEDEFAULT=' /etc/default/grub || echo 'GRUB_SAVEDEFAULT=true' >> /etc/default/grub; \
        sed -i 's/^GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub; \
        grep -q '^GRUB_DISABLE_OS_PROBER=' /etc/default/grub || echo 'GRUB_DISABLE_OS_PROBER=false' >> /etc/default/grub; \
    fi

# Cleanup
RUN rm -rf /tmp/* /usr/etc

### LINTING
RUN bootc container lint
