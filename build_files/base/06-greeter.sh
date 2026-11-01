#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

systemctl enable greetd.service 2>/dev/null || true

install -d -m 0750 -o greeter -g greeter /var/lib/noctalia-greeter
noctalia-greeter-apply-appearance --setup-system 2>/dev/null || true

echo "::endgroup::"
