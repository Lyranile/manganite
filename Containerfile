# manganite - mangowm + DMS layered on the Bazzite GNOME (NVIDIA) base
#
# ARG BASE_IMAGE="ghcr.io/ublue-os/base-nvidia:44"
#
# Allow build scripts to be referenced without being copied into the final image
ARG BASE_IMAGE_NAME="bazzite-gnome-nvidia"
ARG BASE_IMAGE_TAG="stable"
ARG BASE_IMAGE="ghcr.io/ublue-os/${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}"

ARG DMS="true"
ARG MANGOWM="true"

FROM scratch AS ctx
COPY build_files /build_files
COPY system_files /system_files

# Base Image
FROM ${BASE_IMAGE} AS base
## Other possible base images include:
# FROM ghcr.io/ublue-os/bazzite:testing
# FROM ghcr.io/ublue-os/aurora:stable
# FROM ghcr.io/ublue-os/bluefin-nvidia-open:stable

# ... and so on, here are more base images
# Universal Blue Images: https://github.com/orgs/ublue-os/packages
# Fedora base image: quay.io/fedora/fedora-bootc:44
# CentOS base images: quay.io/centos-bootc/centos-bootc:stream10

### [IM]MUTABLE /opt
## Some bootable images, like Fedora, have /opt symlinked to /var/opt, in order to
## make it mutable/writable for users. However, some packages write files to this directory,
## thus its contents might be wiped out when bootc deploys an image, making it troublesome for
## some packages. Eg, google-chrome, docker-desktop.

## Uncomment the following line if one desires to make /opt immutable and be able to be used
## by the package manager.
ARG FEDORA_MAJOR_VERSION="44"
ARG IMAGE_NAME="manganite"
ARG IMAGE_VENDOR="ublue-os"
ARG SHA_HEAD_SHORT=""
ARG UBLUE_IMAGE_TAG="stable"
ARG VERSION=""
ARG DMS="true"
ARG MANGOWM="true"

# RUN rm /opt && mkdir /opt
RUN --mount=type=cache,dst=/var/cache/libdnf5 \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    /ctx/build_files/build.sh

### MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.
CMD ["/sbin/init"]

RUN bootc container lint
