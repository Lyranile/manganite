#!/usr/bin/env bash

set -eoux pipefail

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
mkdir -p /etc/anaconda/profile.d
tee /etc/anaconda/profile.d/manganite.conf <<'EOF'
[Profile]
profile_id = manganite

[Profile Detection]
os_id = manganite

[User Interface]
webui_web_engine = slitherer
hidden_webui_pages =
    network
EOF

# Interactive Kickstart: install the bootc container image
tee /usr/share/anaconda/interactive-defaults.ks <<EOF
ostreecontainer --url=$IMAGE_REF:$IMAGE_TAG --transport=containers-storage --no-signature-verification
%include /usr/share/anaconda/post-scripts/install-configure-upgrade.ks
%include /usr/share/anaconda/post-scripts/install-flatpaks.ks
EOF

# Post-install: switch to the published image
mkdir -p /usr/share/anaconda/post-scripts
tee /usr/share/anaconda/post-scripts/install-configure-upgrade.ks <<EOF
%post --erroronfail
bootc switch --mutate-in-place --enforce-container-sigpolicy --transport registry $IMAGE_REF:$IMAGE_TAG
%end
EOF

# Post-install: copy flatpaks into the deployed system
tee /usr/share/anaconda/post-scripts/install-flatpaks.ks <<'EOF'
%post --erroronfail --nochroot
set -eou
deployment="$(ostree rev-parse --repo=/mnt/sysimage/ostree/repo ostree/0/1/0)"
target="/mnt/sysimage/ostree/deploy/default/deploy/$deployment.0/var/lib/"
mkdir -p "$target"
rsync -aAXUHKP /var/lib/flatpak "$target" 2>/dev/null || true
sync
%end
EOF

# Validate kickstart if tools are available
if command -v ksflatten >/dev/null 2>&1; then
    ksflatten -c /usr/share/anaconda/interactive-defaults.ks || true
fi
if command -v ksvalidator >/dev/null 2>&1; then
    ksvalidator /usr/share/anaconda/interactive-defaults.ks || true
fi
