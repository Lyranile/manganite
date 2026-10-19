# Allow build scripts to be referenced without being copied into the final image

ARG BASE_IMAGE_NAME="base-main"
ARG BASE_IMAGE_TAG="44"
ARG BASE_IMAGE="ghcr.io/ublue-os/${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}"

# Repos to enable permanently for the entire OS
ARG ENABLE_REPOS="terra"

# Packages to install (Fedora repos + the repos listed above)
# noctalia is in Fedora 44+; use an explicit .44 tag (the 'stable' tag on
# kinoite-nvidia is abandoned). NVIDIA is baked in via ublue akmods.
ARG INSTALL_PACKAGES="git \
  papirus-icon-theme \
  bibata-cursor-theme \
  xdg-desktop-portal-gtk \
  xdg-desktop-portal-wlr \
  brightnessctl \
  wl-clipboard \
  i2c-tools \
  playerctl \
  cliphist \
  polkit \
  android-tools \
  cava \
  just \
  pnpm \
  uv \
  alacritty \
  starship \
  noctalia \
  mangowm \
  zoxide \
  micro \
  yazi \
  zsh"

FROM ${BASE_IMAGE}

# Build args declared before the first FROM are not in scope after it
ARG ENABLE_REPOS
ARG INSTALL_PACKAGES

COPY build_files/ /

# Enable the extra repos for the whole OS
RUN --mount=type=cache,dst=/var/cache/libdnf5 \
    for repo in ${ENABLE_REPOS}; do \
        dnf -y config-manager setopt "${repo}.enabled=1"; \
    done

# Install packages from Fedora and the enabled repos
RUN --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf -y install ${INSTALL_PACKAGES}

# NVIDIA: base-main ships no drivers, so install akmods-nvidia plus the
# userspace bits from the Fedora release repo. Drop this block if you
# do not need proprietary drivers.
RUN --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf -y install \
        "https://download.fedoraproject.org/pub/fedora/linux/releases/${BASE_IMAGE_TAG}/Everything/x86_64/os/Packages/f/akmods-nvidia-*.rpm" \
        nvidia-modprobe nvidia-persistenced vdpauinfo libva-vdpau-driver && \
    echo "add_drivers+(\"nvidia\")" > /etc/libdnf5/protected.d/nvidia.conf && \
    rm -f /usr/bin/chsh /usr/bin/lchsh && \
    sed -Ei "s/secure_path = (.*)/secure_path = \1:\/home\/linuxbrew\/.linuxbrew\/bin/" /etc/sudoers || true

CMD ["/sbin/init"]

RUN bootc container lint
