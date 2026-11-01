ARG IMAGE_NAME="${IMAGE_NAME:-manganite}"
ARG BASE_IMAGE_NAME="base-main"
ARG BASE_IMAGE_TAG="44"
ARG BASE_IMAGE="ghcr.io/ublue-os/${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}"
ARG ENABLE_REPOS="terra"
ARG NVIDIA="true"

FROM scratch AS ctx
COPY build_files /build_files
COPY system_files /system_files

FROM ghcr.io/ublue-os/akmods:main-${BASE_IMAGE_TAG} AS akmods
FROM ghcr.io/ublue-os/akmods-nvidia-open:main-${BASE_IMAGE_TAG} AS akmods-nvidia

FROM ${BASE_IMAGE}

ARG IMAGE_NAME="${IMAGE_NAME:-manganite}"
ARG ENABLE_REPOS="terra"
ARG NVIDIA="true"

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    --mount=type=bind,from=akmods,source=/kernel-rpms,target=/tmp/kernel-rpms \
    --mount=type=bind,from=akmods,source=/rpms/ublue-os,target=/tmp/akmods-rpms \
    --mount=type=bind,from=akmods-nvidia,source=/rpms,target=/tmp/akmods-nv-rpms \
    /ctx/build_files/build.sh

# Lint container files
RUN ["bootc", "container", "lint"]

CMD ["/sbin/init"]
