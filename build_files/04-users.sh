#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

id user >/dev/null 2>&1 || useradd -m -s /usr/bin/zsh -G wheel user

systemd-sysusers

echo "::endgroup::"
