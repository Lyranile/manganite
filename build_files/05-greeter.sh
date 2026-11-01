#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# greetd runs the greeter as the `greeter` user; initialize its state dir so
# the login screen can store its config, appearance sync state, and wallpapers.
install -d -m 0750 -o greeter -g greeter /var/lib/noctalia-greeter
noctalia-greeter-apply-appearance --setup-system 2>/dev/null || true

echo "::endgroup::"
