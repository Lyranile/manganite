#!/usr/bin/env bash

if ! command -v starship >/dev/null 2>&1; then
	exit 0
fi

STARSHIP_CONFIG="${HOME}/.config/starship.toml"
if [ -f "$STARSHIP_CONFIG" ]; then
	exit 0
fi

mkdir -p "$(dirname "$STARSHIP_CONFIG")"
starship preset tokyo-night -o "$STARSHIP_CONFIG" 2>/dev/null || true
