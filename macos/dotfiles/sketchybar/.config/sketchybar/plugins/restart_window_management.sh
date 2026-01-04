#!/usr/bin/env bash

set -euo pipefail

# Restart Yabai (window management)
if command -v yabai >/dev/null 2>&1; then
  yabai --restart-service 2>/dev/null || yabai --start-service 2>/dev/null || true
fi

# Reload Sketchybar
# Prefer the built-in reload if available; otherwise fall back to brew services.
if command -v sketchybar >/dev/null 2>&1; then
  sketchybar --reload
fi