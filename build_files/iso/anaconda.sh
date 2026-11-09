#!/usr/bin/env bash

set -eoux pipefail

ANACONDA_DIR="${ANACONDA_DIR:-/usr/share/anaconda}"
PROFILE_DIR="/etc/anaconda/profile.d"
POST_DIR="${ANACONDA_DIR}/post-scripts"
TEMPLATE_DIR="/src/build_files/iso/anaconda"

if [[ -n "${BASE_IMAGE:-}" ]]; then
	IMAGE_REF="${BASE_IMAGE%%:*}"
	IMAGE_TAG="${BASE_IMAGE##*:}"
else
	IMAGE_INFO="$(cat /usr/share/ublue-os/image-info.json)"
	IMAGE_TAG="$(jq -c -r '."image-tag"' <<<"$IMAGE_INFO")"
	IMAGE_REF="$(jq -c -r '."image-ref"' <<<"$IMAGE_INFO")"
	IMAGE_REF="${IMAGE_REF##*://}"
fi

# Anaconda Profile
mkdir -p "${PROFILE_DIR}"
install -Dm644 "${TEMPLATE_DIR}/profile.conf" "${PROFILE_DIR}/manganite.conf"

# Interactive Kickstart: install the bootc container image
mkdir -p "${ANACONDA_DIR}" "${POST_DIR}"
cat >"${ANACONDA_DIR}/interactive-defaults.ks" <<EOF
ostreecontainer --url=${IMAGE_REF}:${IMAGE_TAG} --transport=containers-storage --no-signature-verification
%include ${ANACONDA_DIR}/post-scripts/install-configure-upgrade.ks
%include ${ANACONDA_DIR}/post-scripts/install-flatpaks.ks
EOF

# Post-install: switch to the published image
cat >"${POST_DIR}/install-configure-upgrade.ks" <<EOF
%post --erroronfail
bootc switch --mutate-in-place --enforce-container-sigpolicy --transport registry ${IMAGE_REF}:${IMAGE_TAG}
%end
EOF

# Post-install: copy flatpaks into the deployed system
install -Dm644 "${TEMPLATE_DIR}/install-flatpaks.ks" "${POST_DIR}/install-flatpaks.ks"

# Validate kickstart if tools are available
if command -v ksflatten >/dev/null 2>&1; then
	ksflatten -c "${ANACONDA_DIR}/interactive-defaults.ks" || true
fi
if command -v ksvalidator >/dev/null 2>&1; then
	ksvalidator "${ANACONDA_DIR}/interactive-defaults.ks" || true
fi
