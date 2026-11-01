#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

/ctx/build_files/check-build.sh

echo "::endgroup::"
