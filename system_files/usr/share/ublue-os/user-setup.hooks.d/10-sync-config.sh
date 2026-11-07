#!/usr/bin/env bash
# Sync missing skel configs to user home (non-destructive)
# Runs once per image version (tracked via version file)

VERSION_FILE="${HOME}/.local/share/ublue/sync-version"
CURRENT_VERSION="$(grep '^VERSION_ID=' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')"
CURRENT_VERSION="${CURRENT_VERSION:-unknown}"

# Check if already synced for this version
if [ -f "$VERSION_FILE" ] && [ "$(cat "$VERSION_FILE" 2>/dev/null)" = "$CURRENT_VERSION" ]; then
	echo "Config sync already done for version $CURRENT_VERSION, skipping."
	exit 0
fi

echo "Syncing missing skel configs to $HOME (version $CURRENT_VERSION)..."
mkdir -p "$(dirname "$VERSION_FILE")"

if [ -d /etc/skel ]; then
	(cd /etc/skel && find . -type f 2>/dev/null) | while IFS= read -r f; do
		f="${f#./}"
		if [ ! -f "$HOME/$f" ]; then
			mkdir -p "$(dirname "$HOME/$f")" 2>/dev/null
			cp "/etc/skel/$f" "$HOME/$f" 2>/dev/null || true
		fi
	done
fi

# Mark as synced
echo "$CURRENT_VERSION" >"$VERSION_FILE"
echo "Config sync complete."
