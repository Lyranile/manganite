#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

rm -rf /var/lib/dnf /var/lib/rpm-state /var/lib/xkb \
	/var/lib/power-profiles-daemon /var/lib/greetd 2>/dev/null || true

rm -rf /run/* /run/.[!.]* /tmp/* /tmp/.[!.]* /var/tmp/* /var/tmp/.[!.]* 2>/dev/null || true

dnf5 clean all || true

rm -rf /run/* /run/.[!.]* /tmp/* /tmp/.[!.]* /var/tmp/* /var/tmp/.[!.]* 2>/dev/null || true

echo "::endgroup::"
