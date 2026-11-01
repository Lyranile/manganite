#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

id user >/dev/null 2>&1 || useradd -m -s /usr/bin/zsh -G wheel user

# greetd runs the Noctalia Greeter session as the `greeter` user.
id greeter >/dev/null 2>&1 || useradd -r -s /usr/sbin/nologin -G video,input greeter

echo "::endgroup::"
