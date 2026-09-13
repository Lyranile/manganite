#!/usr/bin/env bash

# Configure podman on the build runner to verify the sigstore signature of
# base images pulled from ghcr.io/ublue-os against the upstream public key
# (https://github.com/ublue-os/main/blob/main/cosign.pub).

set -eoux pipefail

PKI_DIR="/etc/pki/containers"
REGISTRIES="/etc/containers/registries.d"
POLICY="/etc/containers/policy.json"

mkdir -p "${PKI_DIR}" "${REGISTRIES}"

cp .github/ublue-cosign.pub "${PKI_DIR}/ghcr.io-ublue-os.pub"

cat > "${REGISTRIES}/ublue-os.yaml" <<'EOF'
docker:
  ghcr.io/ublue-os:
    use-sigstore-attachments: true
EOF

cat > "${POLICY}" <<EOF
{
  "default": [
    {
      "type": "insecureAcceptAnything"
    }
  ],
  "transports": {
    "docker": {
      "ghcr.io/ublue-os": [
        {
          "type": "sigstoreSigned",
          "keyPath": "/etc/pki/containers/ghcr.io-ublue-os.pub",
          "signedIdentity": {
            "type": "matchRepository"
          }
        }
      ]
    }
  }
}
EOF