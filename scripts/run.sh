#!/usr/bin/env bash
# Run the LÖVE2D Pokémon Red port (macOS-friendly).
#
# Assumes scripts/setup.sh has been run once for at least one game (generated
# data present and LÖVE installed). Extra arguments are passed through to LÖVE.
#
# Link play is peer-to-peer (lua-enet, bundled with LÖVE): one player
# picks HOST A GAME in START > LINK and reads out the address shown;
# the other picks JOIN A GAME and types it in.  UDP port 7777 by
# default (override with POKEPORT_LINK_PORT on both sides).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

fail() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

have_game_data() {
  for generated in \
    "$ROOT/data/generated/maps.lua" \
    "$ROOT/blue/data/generated/maps.lua" \
    "$ROOT/yellow/data/generated/maps.lua" \
    "$ROOT/gold/data/generated/maps.lua" \
    "$ROOT/silver/data/generated/maps.lua" \
    "$ROOT/crystal/data/generated/maps.lua"; do
    [ -f "$generated" ] && return 0
  done

  local identity="${POKEPORT_IDENTITY:-pokemon-love2d}"
  local marker
  for marker in \
    "$HOME/Library/Application Support/LOVE/$identity"/*/rom-cache.complete \
    "$HOME/.local/share/love/$identity"/*/rom-cache.complete; do
    [ -f "$marker" ] && return 0
  done
  return 1
}

if ! have_game_data; then
  fail "generated data missing,  run scripts/setup.sh first"
fi

find_love() {
  command -v love >/dev/null 2>&1 && { echo "love"; return; }
  for app in "/Applications/love.app" "$HOME/Applications/love.app"; do
    if [ -x "$app/Contents/MacOS/love" ]; then
      echo "$app/Contents/MacOS/love"
      return
    fi
  done
  return 1
}

LOVE_BIN="$(find_love)" \
  || fail "LÖVE not found,  run scripts/setup.sh (or install from https://love2d.org)"

# SDL2 on Wayland crashes during desktop drag-and-drop in certain compositors;
# default to X11/XWayland when available to ensure rock-solid drag-drop stability.
if [ -n "${WAYLAND_DISPLAY:-}" ] && [ -z "${SDL_VIDEODRIVER:-}" ]; then
  export SDL_VIDEODRIVER=x11
fi

exec "$LOVE_BIN" "$ROOT" "$@"
