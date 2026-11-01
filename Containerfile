ARG IMAGE_NAME="manganite"
ARG BASE_IMAGE_NAME="base-main"
ARG BASE_IMAGE_TAG="44"
ARG BASE_IMAGE="ghcr.io/ublue-os/${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}"
ARG BREW_IMAGE="ghcr.io/ublue-os/brew:latest"
ARG ENABLE_REPOS="terra"
ARG NVIDIA="true"

FROM ${BREW_IMAGE} AS brew

FROM scratch AS ctx
COPY build_files /build_files
# Provide linuxbrew (and its users) so 04-brew.sh can install Homebrew packages.
COPY --from=brew /system_files /system_files
# manganite-owned files overlay last so they take precedence over brew
COPY system_files /system_files

FROM ghcr.io/ublue-os/akmods:main-${BASE_IMAGE_TAG} AS akmods
FROM ghcr.io/ublue-os/akmods-nvidia-open:main-${BASE_IMAGE_TAG} AS akmods-nvidia

FROM ${BASE_IMAGE}

ARG IMAGE_NAME
ARG ENABLE_REPOS
ARG NVIDIA

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    --mount=type=bind,from=akmods,source=/kernel-rpms,target=/tmp/kernel-rpms \
    --mount=type=bind,from=akmods,source=/rpms/ublue-os,target=/tmp/akmods-rpms \
    --mount=type=bind,from=akmods-nvidia,source=/rpms,target=/tmp/akmods-nv-rpms \
    /ctx/build_files/shared/build.sh

CMD ["/sbin/init"]

RUN --network=none \
    bootc container lint --fatal-warnings --no-truncate
