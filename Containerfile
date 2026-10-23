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
  playerctl \
  cliphist \
  polkit \
  android-tools \
  fastfetch \
  cava \
  just \
  pnpm \
  uv \
  alacritty \
  starship \
  mangowm \
  zoxide \
  micro \
  yazi \
  zsh \
  eza \
  bat \
  fzf \
  atuin \
  duf \
  procs"

# NVIDIA variant: "proprietary" (default) or "open" (nvidia-open / NVK-friendly)
ARG NVIDIA_VARIANT="proprietary"
ARG AKMODS_FLAVOR="main"

FROM ghcr.io/ublue-os/akmods:${AKMODS_FLAVOR}-${BASE_IMAGE_TAG} AS akmods
FROM ghcr.io/ublue-os/akmods-nvidia:${AKMODS_FLAVOR}-${BASE_IMAGE_TAG} AS akmods-nvidia
FROM ghcr.io/ublue-os/akmods-nvidia-open:${AKMODS_FLAVOR}-${BASE_IMAGE_TAG} AS akmods-nvidia-open

FROM ${BASE_IMAGE}

# Build args declared before the first FROM are not in scope after it
ARG ENABLE_REPOS
ARG INSTALL_PACKAGES
ARG NVIDIA_VARIANT
ARG AKMODS_FLAVOR
ARG BASE_IMAGE_TAG

COPY build_files/ /

# Enable the extra repos for the whole OS
RUN --mount=type=cache,dst=/var/cache/libdnf5 \
    for repo in ${ENABLE_REPOS}; do \
        dnf -y config-manager setopt "${repo}.enabled=1"; \
    done

# Install packages from Fedora and the enabled repos
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

# NVIDIA: install the chosen variant (proprietary or open) using ublue's
# prebuilt akmods, replacing the kernel with the one shipped by the akmods
# image so the kmod matches.
RUN --mount=type=cache,dst=/var/cache/libdnf5 \
    --mount=type=bind,from=akmods,src=/rpms/common,dst=/tmp/akmods-rpms \
    --mount=type=bind,from=akmods,src=/kernel-rpms,dst=/tmp/kernel-rpms \
    --mount=type=bind,from=akmods-nvidia,src=/rpms,dst=/tmp/akmods-nv-proprietary \
    --mount=type=bind,from=akmods-nvidia-open,src=/rpms,dst=/tmp/akmods-nv-open \
    if [ "${NVIDIA_VARIANT}" = "open" ]; then \
        NV_PATH=/tmp/akmods-nv-open; \
    else \
        NV_PATH=/tmp/akmods-nv-proprietary; \
    fi && \
    for pkg in kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra; do \
        rpm --erase "$pkg" --nodeps 2>/dev/null || true; \
    done && \
    dnf -y install --setopt=tsflags=noscripts /tmp/kernel-rpms/kernel-*.rpm && \
    (dnf -y versionlock add kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra 2>/dev/null || true) && \
    AKMODNV_PATH="${NV_PATH}" "${NV_PATH}/ublue-os/nvidia-install.sh" && \
    echo 'add_drivers+=("nvidia")' > /etc/libdnf5/protected.d/nvidia.conf && \
    rm -f /usr/bin/chsh /usr/bin/lchsh && \
    sed -Ei "s/secure_path = (.*)/secure_path = \1:\/home\/linuxbrew\/.linuxbrew\/bin/" /etc/sudoers || true

CMD ["/sbin/init"]

RUN bootc container lint
