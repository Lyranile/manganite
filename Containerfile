# Allow build scripts to be referenced without being copied into the final image

ARG BASE_IMAGE_NAME="bazzite-gnome-nvidia"
ARG BASE_IMAGE_TAG="stable"
ARG BASE_IMAGE="ghcr.io/ublue-os/${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}"
# ARG BASE_IMAGE="ghcr.io/ublue-os/base-nvidia:44"

# Repos to enable permanently for the entire OS
ARG ENABLE_REPOS="terra copr:copr.fedorainfracloud.org:avengemedia:dms coprdep:copr.fedorainfracloud.org:avengemedia:danklinux"

# Packages to install (Fedora repos + the repos listed above)
ARG INSTALL_PACKAGES="android-tools brightnessctl cava cliphist foot git i2c-tools just micro papirus-icon-theme playerctl polkit uv wl-clipboard xdg-desktop-portal-gtk xdg-desktop-portal-wlr zoxide bibata-cursor-theme bun-bin ghostty mangowm starship dms quickshell-git dankcalendar-git matugen dgop danksearch"

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

CMD ["/sbin/init"]

RUN bootc container lint
