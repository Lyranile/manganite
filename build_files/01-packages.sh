#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

dnf5 -y install \
    umbriel-nightly \
    xdg-desktop-portal-umbriel-nightly \
    noctalia \
    noctalia-greeter \
    starship ghostty \
    fastfetch zoxide micro cava yazi bat duf eza fzf zsh \
    just make pnpm gcc git uv go-task \
    os-prober polkit greetd \
    brightnessctl i2c-tools playerctl \
    android-tools \
    bibata-cursor-theme papirus-icon-theme

echo "::endgroup::"
