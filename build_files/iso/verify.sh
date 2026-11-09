#!/usr/bin/env bash

set -eoux pipefail

IMPORTANT_PACKAGES=(
	anaconda-live
	anaconda-webui
	dracut-live
	livesys-scripts
	slitherer
)

for package in "${IMPORTANT_PACKAGES[@]}"; do
	rpm -q "$package" >/dev/null || {
		echo "Missing package: $package... Exiting"
		exit 1
	}
done

test -d /usr/share/cockpit/anaconda-webui
test -f /etc/anaconda/profile.d/manganite.conf
test -f /usr/libexec/livesys/sessions.d/livesys-umbriel
test -f /etc/greetd/config.toml
grep -q 'initial_session' /etc/greetd/config.toml

echo "All installer smoke tests passed."
