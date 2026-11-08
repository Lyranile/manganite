#!/usr/bin/env bash

set -eoux pipefail

# Basic smoke test: ensure the Anaconda WebUI is present
test -d /usr/share/cockpit/anaconda-webui

# Ensure the installer profile exists
test -f /etc/anaconda/profile.d/manganite.conf
