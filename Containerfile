# Allow build scripts to be referenced without being copied into the final image

ARG BASE_IMAGE_NAME="kinoite-nvidia"
ARG BASE_IMAGE_TAG="stable"
ARG BASE_IMAGE="ghcr.io/ublue-os/${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}"

# Repos to enable permanently for the entire OS
ARG ENABLE_REPOS="terra"

# Packages to install (Fedora repos + the repos listed above)
# noctalia is in Fedora 44+ (kinoite:stable is 44); no extra copr needed — aligns with ublue-os/main F44
ARG INSTALL_PACKAGES="android-tools brightnessctl cava cliphist foot git i2c-tools just micro papirus-icon-theme playerctl polkit uv wl-clipboard xdg-desktop-portal-gtk xdg-desktop-portal-wlr zoxide bibata-cursor-theme bun-bin ghostty mangowm starship noctalia"

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

# Aurora KDE tweaks copied from aurora/build_scripts/base/16-override-install.sh
RUN rm -f /usr/bin/chsh /usr/bin/lchsh && \
    sed -Ei "s/secure_path = (.*)/secure_path = \1:\/home\/linuxbrew\/.linuxbrew\/bin/" /etc/sudoers || true && \
    ln -sf "/usr/share/fonts/google-noto-sans-cjk-fonts" "/usr/share/fonts/noto-cjk" || true && \
    rm -rf /usr/share/doc/HTML && \
    rm -f /usr/lib64/qt6/plugins/kf6/krunner/krunner_appstream.so && \
    rm -f /etc/profile.d/gnome-ssh-askpass.{csh,sh} && \
    mkdir -p /var/lib/samba/usershares && chown -R root:usershares /var/lib/samba/usershares || true && \
    firewall-offline-cmd --service=samba --service=samba-client || true && \
    setsebool -P samba_enable_home_dirs=1 || true && setsebool -P samba_export_all_ro=1 || true && setsebool -P samba_export_all_rw=1 || true && \
    sed -i '/^\[homes\]/,/^\[/{/^\[homes\]/d;/^\[/!d}' /etc/samba/smb.conf || true

CMD ["/sbin/init"]

RUN bootc container lint
