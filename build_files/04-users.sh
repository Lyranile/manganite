#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

id user >/dev/null 2>&1 || useradd -m -s /usr/bin/zsh -G wheel user

# greetd runs the Noctalia Greeter session as the `greeter` user.
for group in video input; do
    getent group "$group" >/dev/null || groupadd -r "$group"
done

id greeter >/dev/null 2>&1 || useradd -r -s /usr/sbin/nologin -G video,input greeter

echo "::endgroup::"
