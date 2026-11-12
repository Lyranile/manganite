set dotenv-filename := "image-template.env"
set dotenv-load

export image_name := env("IMAGE_NAME")
export repo_organization := env("REPO_ORGANIZATION")
export image_desc := env("IMAGE_DESC")
export image_keywords := env("IMAGE_KEYWORDS")
export image_logo_url := env("IMAGE_LOGO_URL")
export default_tag := env("DEFAULT_TAG")
export bib_image := env("BIB_IMAGE")

export PODMAN := "podman"
export BUILDAH := "buildah"
export SUDOIF := if `id -u` == "0" { "" } else { "sudo" }

iso_containerfile := "iso/Containerfile"

# Container storage location for bind-mounting into the ISO build container.
containers_storage := if `id -u` == "0" { "/var/lib/containers/storage" } else { env("HOME") + "/.local/share/containers/storage" }

alias build-vm := build-qcow2
alias rebuild-vm := rebuild-qcow2
alias run-vm := run-vm-qcow2

[private]
default:
    @just --list

# Check Just Syntax
[group('Just')]
check:
    #!/usr/bin/env bash
    find . -type f -name "*.just" | while read -r file; do
    	echo "Checking syntax: $file"
    	just --unstable --fmt --check -f $file
    done
    echo "Checking syntax: Justfile"
    just --unstable --fmt --check -f Justfile

# Fix Just Syntax
[group('Just')]
fix:
    #!/usr/bin/env bash
    find . -type f -name "*.just" | while read -r file; do
    	echo "Checking syntax: $file"
    	just --unstable --fmt -f $file
    done
    echo "Checking syntax: Justfile"
    just --unstable --fmt -f Justfile || { exit 1; }

# Clean Repo
[group('Utility')]
clean:
    #!/usr/bin/env bash
    set -eoux pipefail
    rm -rf _build* output sbom_out
    rm -f previous.manifest.json changelog.md output.env /tmp/*-tags.json
    rm -rf output/

# Sudo Clean Repo
[group('Utility')]
[private]
sudo-clean:
    just sudoif just clean

# sudoif bash function
[group('Utility')]
[private]
sudoif command *args:
    #!/usr/bin/env bash
    function sudoif(){
        if [[ "${UID}" -eq 0 ]]; then
            "$@"
        elif [[ "$(command -v sudo)" && -n "${SSH_ASKPASS:-}" ]] && [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; then
            sudo --askpass "$@" || exit 1
        elif [[ "$(command -v sudo)" ]]; then
            sudo "$@" || exit 1
        else
            exit 1
        fi
    }
    sudoif {{ command }} {{ args }}

# This Justfile recipe builds a container image using Podman.
#
# Arguments:
#   $target_image - The tag you want to apply to the image (default: $image_name).
#   $tag - The tag for the image (default: $default_tag).
#
# The script constructs the version string using the tag and the current date.
# If the git working directory is clean, it also includes the short SHA of the current HEAD.
#
# just build $target_image $tag
#
# Example usage:
#   just build myimage mytag
#
# This will build an image 'myimage:mytag'
#

# Build the image using the specified parameters
build $target_image=image_name $tag=default_tag:
    #!/usr/bin/env bash

    set -euox pipefail

    BUILD_ARGS=()
    LABELS=()
    if [[ -z "$(git status -s)" ]]; then
        GIT_SHA=$(git rev-parse --short HEAD)
        LABELS+=("--label" "io.artifacthub.package.readme-url=https://raw.githubusercontent.com/{{ repo_organization }}/{{ image_name }}/${GIT_SHA}/README.md")
        LABELS+=("--label" "org.opencontainers.image.documentation=https://raw.githubusercontent.com/{{ repo_organization }}/{{ image_name }}/${GIT_SHA}/README.md")
        LABELS+=("--label" "org.opencontainers.image.source=https://github.com/{{ repo_organization }}/{{ image_name }}/blob/${GIT_SHA}/Containerfile")
        LABELS+=("--label" "org.opencontainers.image.url=https://github.com/{{ repo_organization }}/{{ image_name }}/tree/${GIT_SHA}")
        LABELS+=("--label" "org.opencontainers.image.version={{ default_tag }}.$(date +%Y%m%d)-${GIT_SHA}")
    fi

    # Image metadata for https://artifacthub.io/ - This is optional but is highly recommended so we all can get a index of all the custom images
    # The metadata by itself is not going to do anything, you choose if you want your image to be on ArtifactHub or not.
    LABELS+=("--label" "io.artifacthub.package.deprecated=false")
    LABELS+=("--label" "io.artifacthub.package.keywords={{ image_keywords }}")
    LABELS+=("--label" "io.artifacthub.package.license=Apache-2.0")
    LABELS+=("--label" "io.artifacthub.package.logo-url={{ image_logo_url }}")
    LABELS+=("--label" "io.artifacthub.package.prerelease=false")
    LABELS+=("--label" "org.opencontainers.image.created=$(date -u +%Y\-%m\-%d\T%H\:%M\:%S\Z)")
    LABELS+=("--label" "org.opencontainers.image.description={{ image_desc }}")
    LABELS+=("--label" "org.opencontainers.image.title={{ image_name }}")
    LABELS+=("--label" "org.opencontainers.image.vendor={{ repo_organization }}")

    # This actually builds the image!
    PODMAN_BUILD_ARGS=("${BUILD_ARGS[@]}" "${LABELS[@]}" --pull=newer --tag "${target_image}:${tag}" --file Containerfile --build-arg "NVIDIA_VARIANT=${NVIDIA_VARIANT:-open}" --build-arg "LIVE_USER=${LIVE_USER:-false}")

    podman build "${PODMAN_BUILD_ARGS[@]}" .

# Split the image for smaller updates (New)!
rechunk $target_image=image_name $tag=default_tag:
    #!/usr/bin/env bash

    set -xeuo pipefail

    # TODO: pin chunkah image to hash once mature enough
    # You may run into space issues on github runners as we are making a
    # complete copy of the image, which likely has no shared layers, unless your
    # base image is also using chunkah
    CHUNKAH_CONFIG_FILE="$(mktemp)"

    # You may omit the current directory here if you are confident that you
    # won't run out of space on /tmp for your image
    CHUNKAH_OUTPUT_DIR="$(mktemp -d ./"${target_image}"_chunkah_XXXXXX)"

    trap 'rm -f "${CHUNKAH_CONFIG_FILE}"; rm -rf "${CHUNKAH_OUTPUT_DIR}"' EXIT
    podman inspect "${target_image}:${tag}" > "${CHUNKAH_CONFIG_FILE}"

    podman run --rm \
      --mount=type=image,src="${target_image}:${tag}",target=/chunkah \
      -v "${CHUNKAH_CONFIG_FILE}:/chunkah-config.json:ro,Z" \
      -v "${CHUNKAH_OUTPUT_DIR}:/run/out:Z" \
      quay.io/coreos/chunkah:latest \
      build \
      --verbose \
      --compressed \
      --max-layers 128 \
      --prune /sysroot/ \
      --label ostree.commit- --label ostree.final-diffid- \
      --config /chunkah-config.json \
      --output oci:/run/out/chunked

    CHUNKED_IMAGE="$(podman pull "oci:${CHUNKAH_OUTPUT_DIR}/chunked")"
    podman tag "${CHUNKED_IMAGE}" "${target_image}:${tag}"

# Split the image for smaller updates (Classical)!
ostree-rechunk $target_image=image_name $tag=default_tag:
    #!/usr/bin/env bash

    set -xeuo pipefail

    # Use the already-built local image to avoid pulling from a remote registry
    RPM_OSTREE_CHUNKER_IMAGE="localhost/${target_image}:${tag}"

    GRAPHROOT="$(podman info --format '{{ '{{.Store.GraphRoot}}' }}')"

    podman run --rm --pull=never --privileged \
      --mount=type=image,src="${target_image}:${tag}",target=/rpm-ostree \
      --mount=type=bind,src=${GRAPHROOT},target=/run/host-container-storage,rw \
      --mount=type=tmpfs,target=/run/rpm-ostree-storage \
      --entrypoint /usr/bin/rpm-ostree \
      "${RPM_OSTREE_CHUNKER_IMAGE}" \
      compose build-chunked-oci \
      --max-layers 127 \
      --format-version=2 \
      --bootc \
      --rootfs /rpm-ostree \
      --output "containers-storage:[overlay@/run/host-container-storage+/run/rpm-ostree-storage]localhost/${target_image}:${tag}"

# Generate Default Tag
[group('Utility')]
generate-default-tag $tag=default_tag:
    #!/usr/bin/env bash
    set -eoux pipefail

    echo "${tag}"

# Generate Tags
[group('Utility')]
generate-build-tags $target_image=image_name $tag=default_tag:
    #!/usr/bin/env bash
    set -eoux pipefail

    DATE=$(date +%Y%m%d)
    BUILD_TAGS=()
    if [[ -z "$(git status -s)" ]]; then
        GIT_SHA=$(git rev-parse --short HEAD)
        BUILD_TAGS+=("${tag}-${GIT_SHA}")
        BUILD_TAGS+=("${tag}-${DATE}-${GIT_SHA}")
        BUILD_TAGS+=("${DATE}-${GIT_SHA}")
    fi

    BUILD_TAGS+=("${DATE}")
    BUILD_TAGS+=("${tag}")
    BUILD_TAGS+=("${tag}-${DATE}")

    echo "${BUILD_TAGS[@]}"

# Tag Images
[group('Utility')]
tag-images $target_image=image_name $tag=default_tag tags="":
    #!/usr/bin/env bash
    set -eoux pipefail

    # Get Image, and untag
    IMAGE=$(podman inspect ${target_image}:${tag} | jq -r .[].Id)
    podman untag ${IMAGE}

    # Tag Image
    for tag in {{ tags }}; do
        podman tag $IMAGE "${target_image}:${tag}"
    done

    # Show Images
    podman images

# Image Name
[group('Utility')]
[private]
image_name $target_image=image_name:
    #!/usr/bin/env bash
    set -eoux pipefail

    echo "${image_name}"

# Command: _rootful_load_image
# Description: This script checks if the current user is root or running under sudo. If not, it attempts to resolve the image tag using podman inspect.
#              If the image is found, it loads it into rootful podman. If the image is not found, it pulls it from the repository.
#
# Parameters:
#   $target_image - The name of the target image to be loaded or pulled.
#   $tag - The tag of the target image to be loaded or pulled. Default is 'default_tag'.
#
# Example usage:
#   _rootful_load_image my_image latest
#
# Steps:
# 1. Check if the script is already running as root or under sudo.
# 2. Check if target image is in the non-root podman container storage)
# 3. If the image is found, load it into rootful podman using podman scp.
# 4. If the image is not found, pull it from the remote repository into reootful podman.

_rootful_load_image $target_image=image_name $tag=default_tag:
    #!/usr/bin/env bash
    set -eoux pipefail

    # Check if already running as root or under sudo
    if [[ -n "${SUDO_USER:-}" || "${UID}" -eq "0" ]]; then
        echo "Already root or running under sudo, no need to load image from user podman."
        exit 0
    fi

    # Try to resolve the image tag using podman inspect
    set +e
    resolved_tag=$(podman inspect -t image "${target_image}:${tag}" | jq -r '.[].RepoTags.[0]')
    return_code=$?
    set -e

    USER_IMG_ID=$(podman images --filter reference="${target_image}:${tag}" --format "'{{ '{{.ID}}' }}'")

    if [[ $return_code -eq 0 ]]; then
        # If the image is found, load it into rootful podman
        ID=$(just sudoif podman images --filter reference="${target_image}:${tag}" --format "'{{ '{{.ID}}' }}'")
        if [[ "$ID" != "$USER_IMG_ID" ]]; then
            # If the image ID is not found or different from user, copy the image from user podman to root podman
            COPYTMP=$(mktemp -p "${PWD}" -d -t _build_podman_scp.XXXXXXXXXX)
            just sudoif TMPDIR=${COPYTMP} podman image scp ${UID}@localhost::"${target_image}:${tag}" root@localhost::"${target_image}:${tag}"
            rm -rf "${COPYTMP}"
        fi
    else
        # If the image is not found, pull it from the repository
        just sudoif podman pull "${target_image}:${tag}"
    fi

# Build a bootc bootable image using Bootc Image Builder (BIB)
# Converts a container image to a bootable image
# Parameters:
#   target_image: The name of the image to build (ex. localhost/fedora)
#   tag: The tag of the image to build (ex. latest)
#   type: The type of image to build (ex. qcow2, raw, iso)
#   config: The configuration file to use for the build (default: disk_config/disk.toml)

# Example: just _rebuild-bib localhost/fedora latest qcow2 disk_config/disk.toml
_build-bib $target_image $tag $type $config: (_rootful_load_image target_image tag)
    #!/usr/bin/env bash
    set -euo pipefail

    BUILDTMP=$(mktemp -p "${PWD}" -d -t _build-bib.XXXXXXXXXX)

    if [[ "${type}" == "iso" ]]; then
      sudo podman run \
        --rm \
        -it \
        --privileged \
        --pull=newer \
        --net=host \
        --security-opt label=type:unconfined_t \
        -v $BUILDTMP:/output \
        -v /var/lib/containers/storage:/var/lib/containers/storage \
        ghcr.io/osbuild/image-builder-cli:latest \
        build \
        --output-dir /output \
        --output-name "${target_image##*/}" \
        --bootc-ref "${target_image}:${tag}" \
        --bootc-default-fs btrfs \
        generic-iso
    else
      args="--type ${type} "
      args+="--use-librepo=True "
      args+="--rootfs=btrfs"

      sudo podman run \
        --rm \
        -it \
        --privileged \
        --pull=newer \
        --net=host \
        --security-opt label=type:unconfined_t \
        -v $(pwd)/${config}:/config.toml:ro \
        -v $BUILDTMP:/output \
        -v /var/lib/containers/storage:/var/lib/containers/storage \
        "${bib_image}" \
        ${args} \
        "${target_image}:${tag}"
    fi

    rm -rf output
    mkdir -p output
    sudo mv -f $BUILDTMP/* output/
    sudo rmdir $BUILDTMP
    sudo chown -R $USER:$USER output/

# Podman builds the image from the Containerfile and creates a bootable image
# Parameters:
#   target_image: The name of the image to build (ex. localhost/fedora)
#   tag: The tag of the image to build (ex. latest)
#   type: The type of image to build (ex. qcow2, raw, iso)
#   config: The configuration file to use for the build (deafult: disk_config/disk.toml)

# Example: just _rebuild-bib localhost/fedora latest qcow2 disk_config/disk.toml
_rebuild-bib $target_image $tag $type $config: (build target_image tag) && (_build-bib target_image tag type config)

# Build a QCOW2 virtual machine image
[group('Build Virtal Machine Image')]
build-qcow2 $target_image=("localhost/" + image_name) $tag=default_tag: && (_build-bib target_image tag "qcow2" "disk_config/disk.toml")

# Build a RAW virtual machine image
[group('Build Virtal Machine Image')]
build-raw $target_image=("localhost/" + image_name) $tag=default_tag: && (_build-bib target_image tag "raw" "disk_config/disk.toml")

# Build a LIVE ISO with the Anaconda WebUI using Titanoboa (builds installer image first)
[group('Build Virtal Machine Image')]
build-iso $target_image=("localhost/" + image_name) $tag=default_tag:
    just build ${target_image} ${tag}
    podman build --cap-add sys_admin --security-opt label=disable --build-context containers-storage={{ containers_storage }} -f {{ iso_containerfile }} --build-arg BASE_IMAGE=${target_image}:${tag} -t ${target_image}-installer:${tag} .
    TITANOBOA_CTR_IMAGE=${target_image}-installer:${tag} TITANOBOA_OUTPUT_DIR=./output ./iso/titanoboa/main.sh

# Rebuild a QCOW2 virtual machine image
[group('Build Virtal Machine Image')]
rebuild-qcow2 $target_image=("localhost/" + image_name) $tag=default_tag: && (_rebuild-bib target_image tag "qcow2" "disk_config/disk.toml")

# Rebuild a RAW virtual machine image
[group('Build Virtal Machine Image')]
rebuild-raw $target_image=("localhost/" + image_name) $tag=default_tag: && (_rebuild-bib target_image tag "raw" "disk_config/disk.toml")

# Rebuild an ISO virtual machine image
[group('Build Virtal Machine Image')]
rebuild-iso $target_image=("localhost/" + image_name) $tag=default_tag: (build target_image tag)
    just build-iso ${target_image} ${tag}

# Run a virtual machine with the specified image type and configuration
_run-vm $target_image $tag $type $config:
    #!/usr/bin/env bash
    set -eoux pipefail

    # Determine the image file based on the type
    image_file="output/${type}/disk.${type}"
    if [[ $type == iso ]]; then
        image_file="output/${target_image##*/}.iso"
    fi

    # Build the image if it does not exist
    if [[ ! -f "${image_file}" ]]; then
        just "build-${type}" "$target_image" "$tag"
    fi

    # Determine an available port to use
    port=8006
    while grep -q :${port} <<< $(ss -tunalp); do
        port=$(( port + 1 ))
    done
    echo "Using Port: ${port}"
    echo "Connect to http://localhost:${port}"

    # Set up the arguments for running the VM
    run_args=()
    run_args+=(--rm --privileged)
    run_args+=(--pull=newer)
    run_args+=(--publish "127.0.0.1:${port}:8006")
    run_args+=(--env "CPU_CORES=4")
    run_args+=(--env "RAM_SIZE=8G")
    run_args+=(--env "DISK_SIZE=64G")
    run_args+=(--env "TPM=Y")
    run_args+=(--env "GPU=Y")
    run_args+=(--device=/dev/kvm)
    run_args+=(--volume "${PWD}/${image_file}":"/boot.${type}":Z)
    run_args+=(docker.io/qemux/qemu)

    # Run the VM and open the browser to connect
    (sleep 30 && xdg-open http://localhost:"$port") &
    podman run "${run_args[@]}"

# Run a virtual machine from a QCOW2 image
[group('Run Virtal Machine')]
run-vm-qcow2 $target_image=("localhost/" + image_name) $tag=default_tag: && (_run-vm target_image tag "qcow2" "disk_config/disk.toml")

# Run a virtual machine from a RAW image
[group('Run Virtal Machine')]
run-vm-raw $target_image=("localhost/" + image_name) $tag=default_tag: && (_run-vm target_image tag "raw" "disk_config/disk.toml")

# Run a virtual machine from an ISO (live WebUI)
[group('Run Virtal Machine')]
run-vm-iso $target_image=("localhost/" + image_name) $tag=default_tag:
    #!/usr/bin/env bash
    set -eoux pipefail
    image_file="output/Manganite-Live.iso"
    if [[ ! -f "${image_file}" ]]; then
        just build-iso ${target_image} ${tag}
    fi
    port=8006
    while grep -q :${port} <<< $(ss -tunalp); do port=$(( port + 1 )); done
    echo "Using Port: ${port}"
    podman run --rm --privileged --pull=newer --publish "127.0.0.1:${port}:8006" \
        --env "CPU_CORES=4" --env "RAM_SIZE=8G" --env "DISK_SIZE=64G" \
        --env "TPM=Y" --env "GPU=Y" --device=/dev/kvm \
        --volume "${PWD}/${image_file}":"/boot.iso":Z \
        docker.io/qemux/qemu

# Run a virtual machine using systemd-vmspawn
[group('Run Virtal Machine')]
spawn-vm rebuild="0" type="qcow2" ram="6G":
    #!/usr/bin/env bash

    set -euo pipefail

    [ "{{ rebuild }}" -eq 1 ] && echo "Rebuilding the ISO" && just build-vm {{ rebuild }} {{ type }}

    systemd-vmspawn \
      -M "bootc-image" \
      --console=gui \
      --cpus=2 \
      --ram=$(echo {{ ram }}| numfmt --from=iec) \
      --network-user-mode \
      --vsock=false --pass-ssh-key=false \
      -i ./output/**/*.{{ type }}

# Runs shell check on all Bash scripts
lint:
    #!/usr/bin/env bash
    set -eoux pipefail
    # Check if shellcheck is installed
    if ! command -v shellcheck &> /dev/null; then
        echo "shellcheck could not be found. Please install it."
        exit 1
    fi
    # Run shellcheck on all Bash scripts
    find . -iname "*.sh" -type f -exec shellcheck "{}" ';'

# Runs shfmt on all Bash scripts
format:
    #!/usr/bin/env bash
    set -eoux pipefail
    # Check if shfmt is installed
    if ! command -v shfmt &> /dev/null; then
        echo "shfmt could not be found. Please install it."
        exit 1
    fi
    # Run shfmt on all Bash scripts
    find . -iname "*.sh" -type f -exec shfmt --write "{}" ';'

# Run Container
[group('Utility')]
run $target_image=image_name $tag=default_tag:
    #!/usr/bin/env bash
    set -eoux pipefail
    ${PODMAN} run -it --rm "${target_image}:${tag}" bash

# Create bootable disk image
[group('Utility')]
disk-image $target_image=image_name $tag=default_tag:
    #!/usr/bin/env bash
    set -eoux pipefail
    IMG_SIZE=40G
    BYTES_IMAGE_SIZE=$(numfmt --from=iec ${IMG_SIZE})
    if [ ! -e "./bootable.img" ]; then
        fallocate -l "${BYTES_IMAGE_SIZE}" "./bootable.img"
    fi
    ${SUDOIF} ${PODMAN} run --rm --privileged --pid=host \
        -v /var/lib/containers:/var/lib/containers \
        -v /dev:/dev \
        -v "${PWD}:/data" \
        "${target_image}:${tag}" \
        bootc install to-disk --generic-image --via-loopback /data/bootable.img --wipe --bootloader grub

# Export OCI archive for PR testing
[group('Utility')]
export-oci $target_image=image_name $tag=default_tag:
    #!/usr/bin/env bash
    set -eoux pipefail
    ARCHIVE_NAME="${target_image##*/}-$(arch).oci"
    ${PODMAN} push --compression-format=zstd --compression-level=3 \
        "${target_image}:${tag}" "oci-archive:${ARCHIVE_NAME}"

# Run bootc commands inside the image
[group('Utility')]
bootc $target_image=image_name $tag=default_tag *ARGS:
    #!/usr/bin/env bash
    set -eoux pipefail
    ${PODMAN} run --rm --privileged --pid=host \
        -v /var/lib/containers:/var/lib/containers \
        -v /dev:/dev \
        -v "${PWD}:/data" \
        "${target_image}:${tag}" bootc {{ ARGS }}

# Secure Boot signature check
[group('Utility')]
secureboot $target_image=image_name $tag=default_tag:
    #!/usr/bin/env bash
    set -eoux pipefail
    kernel_release=$(${PODMAN} inspect "${target_image}:${tag}" | jq -r '.[].Config.Labels["ostree.linux"]')
    TMP=$(${PODMAN} create "${target_image}:${tag}" bash)
    ${PODMAN} cp "$TMP":/usr/lib/modules/"${kernel_release}"/vmlinuz /tmp/vmlinuz
    ${PODMAN} rm "$TMP"
    curl --retry 3 -Lo /tmp/akmods.der https://github.com/ublue-os/akmods/raw/main/certs/public_key.der
    openssl x509 -in /tmp/akmods.der -out /tmp/akmods.crt 2>/dev/null || true
    CMD="$(command -v sbverify || true)"
    if [[ -z "${CMD:-}" ]]; then
        temp_name="sbverify-${RANDOM}"
        ${PODMAN} run -dt --entrypoint /bin/sh \
            --volume /tmp/vmlinuz:/tmp/vmlinuz:z \
            --volume /tmp/akmods.crt:/tmp/akmods.crt:z \
            --name "${temp_name}" docker.io/library/alpine:edge
        ${PODMAN} exec "${temp_name}" apk add sbsigntool >/dev/null
        CMD="${PODMAN} exec ${temp_name} /usr/bin/sbverify"
    fi
    $CMD --list /tmp/vmlinuz
    if ! $CMD --cert /tmp/akmods.crt /tmp/vmlinuz; then
        echo "Secure Boot signature check failed."
        [[ -n "${temp_name:-}" ]] && ${PODMAN} rm -f "${temp_name}"
        exit 1
    fi
    [[ -n "${temp_name:-}" ]] && ${PODMAN} rm -f "${temp_name}"
    echo "Secure Boot signature check passed."

# Generate SBOM
[group('Utility')]
gen-sbom $target_image=image_name $tag=default_tag:
    #!/usr/bin/env bash
    set -eoux pipefail
    OUT_DIR="sbom_out/${target_image##*/}"
    mkdir -p "${OUT_DIR}"
    ${PODMAN} container create --replace --name "${target_image##*/}" "${target_image}:${tag}"
    ROOTFS="${OUT_DIR}/rootfs"
    mkdir -p "${ROOTFS}"
    ${PODMAN} export "${target_image##*/}" | tar -C "${ROOTFS}" -xf -
    ${PODMAN} container rm "${target_image##*/}"
    if command -v syft >/dev/null 2>&1; then
        syft --source-name "${target_image}:${tag}" "${OUT_DIR}" -o "syft-json=${OUT_DIR}/sbom.json"
    else
        echo "syft not found; rootfs exported to ${ROOTFS}"
    fi
    rm -rf "${ROOTFS}"
