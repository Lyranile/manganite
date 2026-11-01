#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

dnf5 clean all || true
rm -rf /tmp/* /var/tmp/* 2>/dev/null || true

echo "::endgroup::"
