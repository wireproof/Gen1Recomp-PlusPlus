#!/usr/bin/env bash
# Add owner-supplied ROM backups and local mod checkouts to an existing
# game.love archive. Nothing is copied into the source tree.
set -euo pipefail

[ $# -eq 1 ] || { echo "usage: $0 GAME.LOVE" >&2; exit 2; }
ARCHIVE="$1"
[ -f "$ARCHIVE" ] || { echo "missing archive: $ARCHIVE" >&2; exit 1; }
ARCHIVE_ABS="$(cd "$(dirname "$ARCHIVE")" && pwd)/$(basename "$ARCHIVE")"
STAGE="$(mktemp -d "$(dirname "$ARCHIVE_ABS")/private-payload.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT

added=0
add_rom() {
  local env_name="$1" rel="$2" expected="$3" source="${!1:-}"
  [ -n "$source" ] || return 0
  [ -f "$source" ] || { echo "$env_name not found: $source" >&2; exit 1; }
  local actual
  actual="$(shasum -a 1 "$source" | awk '{print $1}')"
  [ "$actual" = "$expected" ] || {
    echo "$env_name has unsupported SHA-1 $actual (expected $expected)" >&2
    exit 1
  }
  mkdir -p "$STAGE/$(dirname "$rel")"
  cp "$source" "$STAGE/$rel"
  added=1
  echo "included verified private ROM: $rel"
}

add_mod() {
  local env_name="$1" rel="$2" source="${!1:-}"
  [ -n "$source" ] || return 0
  [ -d "$source" ] || { echo "$env_name not found: $source" >&2; exit 1; }
  [ -f "$source/manifest.json" ] || {
    echo "$env_name is not a mod root (manifest.json missing): $source" >&2
    exit 1
  }
  mkdir -p "$STAGE/$rel"
  # Copy the complete mod while excluding repository administration and local
  # test/cache debris. This staging directory is removed on exit.
  (cd "$source" && find . -type f \
    ! -path './.git/*' ! -path './.git' ! -name '.DS_Store' \
    ! -path './.scratchpad/*' \
    ! -path './mod_option_schemas.json' \
    ! -path './options.lua' ! -path './options.lua.bak' \
    ! -path './options.lua.tmp' -print0) \
    | (cd "$source" && tar --null -T - -cf -) \
    | (cd "$STAGE/$rel" && tar -xf -)
  added=1
  echo "included bundled mod: $rel"
}

# Backward compatibility with the first private FireRed-only packager.
if [ -z "${GEN1RECOMP_BUNDLED_FIRERED_ROM:-}" ] \
    && [ -n "${GEN1RECOMP_BUNDLED_ROM:-}" ]; then
  GEN1RECOMP_BUNDLED_FIRERED_ROM="$GEN1RECOMP_BUNDLED_ROM"
fi

add_rom GEN1RECOMP_BUNDLED_GOLD_ROM private/gold.gbc \
  d8b8a3600a465308c9953dfa04f0081c05bdcb94
add_rom GEN1RECOMP_BUNDLED_CRYSTAL_ROM private/crystal.gbc \
  f4cd194bdee0d04ca4eac29e09b8e4e9d818c133
add_rom GEN1RECOMP_BUNDLED_RED_ROM private/red.gb \
  ea9bcae617fdf159b045185467ae58b2e4a48b9a
add_rom GEN1RECOMP_BUNDLED_BLUE_ROM private/blue.gb \
  d7037c83e1ae5b39bde3c30787637ba1d4c48ce2
add_rom GEN1RECOMP_BUNDLED_YELLOW_ROM private/yellow.gb \
  cc7d03262ebfaf2f06772c1a480c7d9d5f4a38e1
add_rom GEN1RECOMP_BUNDLED_SILVER_ROM private/silver.gbc \
  49b163f7e57702bc939d642a18f591de55d92dae
add_rom GEN1RECOMP_BUNDLED_FIRERED_ROM private/firered.gba \
  41cb23d8dccc8ebd7c649cd8fbb58eeace6e2fdc
add_rom GEN1RECOMP_BUNDLED_STADIUM_ROM baseroms/baserom.z64 \
  ed7bef5a306f88c0a6e96b15e71fee2ef32058f3
add_mod GEN1RECOMP_BUNDLED_GEAR_MOD mods/kanto_johto_gear
add_mod GEN1RECOMP_BUNDLED_DRAMATIC_MOD mods/DRAMATIC_SHAPE

if [ "$added" -eq 1 ]; then
  (cd "$STAGE" && zip -q -9 -r "$ARCHIVE_ABS" .)
fi
