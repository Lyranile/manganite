# Manganite bootc image - image-template pattern
#
# Non-NVIDIA (default):
#   podman build -f Containerfile -t manganite .
#
# NVIDIA (prebuilt ublue akmods; same flow as ublue-os/main):
#   podman build --build-arg NVIDIA=true -f Containerfile -t manganite .

ARG BASE_IMAGE_NAME="base-main"
ARG BASE_IMAGE_TAG="44"
ARG BASE_IMAGE="ghcr.io/ublue-os/${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}"

# Repositories to enable
ARG ENABLE_REPOS="terra"

ARG NVIDIA="true"
ARG IMAGE_NAME="manganite"

FROM scratch AS ctx
COPY system_files /system_files
COPY build_files /

FROM ghcr.io/ublue-os/akmods:main-${BASE_IMAGE_TAG} AS akmods
FROM ghcr.io/ublue-os/akmods-nvidia-open:main-${BASE_IMAGE_TAG} AS akmods_nvidia

FROM ${BASE_IMAGE}

ARG IMAGE_NAME="manganite"
ARG NVIDIA="true"
ARG ENABLE_REPOS="terra"
ARG FEDORA_MAJOR_VERSION="44"

RUN --mount=type=bind,from=ctx,src=/,dst=/ctx \
    --mount=type=cache,target=/var/cache \
    --mount=type=cache,target=/var/log \
    --mount=type=tmpfs,target=/tmp \
    --mount=type=bind,from=akmods,src=/rpms/ublue-os,dst=/tmp/akmods-rpms \
    --mount=type=bind,from=akmods,src=/kernel-rpms,dst=/tmp/kernel-rpms \
    --mount=type=bind,from=akmods_nvidia,src=/rpms,dst=/tmp/akmods-nv-rpms \
    rm -f /usr/bin/chsh \
    && rm -f /usr/bin/lchsh \
    && /ctx/install.sh \
    && if [ "${NVIDIA}" = "true" ]; then \
        AKMODNV_PATH=/tmp/akmods-nv-rpms /tmp/akmods-nv-rpms/ublue-os/nvidia-install.sh \
    ; fi \
    && /ctx/initramfs.sh \
    && /ctx/post-install.sh

RUN ["bootc", "container", "lint"]

CMD ["/sbin/init"]
