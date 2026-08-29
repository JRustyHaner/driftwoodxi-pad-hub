#!/bin/bash
# Copy addons/dwhub into a local Driftwood Ashita tree for in-game testing.
#
# Usage:
#   ./scripts/sync-to-ashita.sh
#   DRIFTWOOD_ASHITA=~/Downloads/driftwoodxi-installer/Ashita ./scripts/sync-to-ashita.sh
#   ./scripts/sync-to-ashita.sh --no-patch   # skip driftwood-default.txt edits
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${DW_HUB_SRC:-$ROOT/addons/dwhub}"
PATCH_BOOT=1

for arg in "$@"; do
  case "$arg" in
    --no-patch) PATCH_BOOT=0 ;;
    -h|--help)
      sed -n '2,8p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

resolve_ashita() {
  if [ -n "${DRIFTWOOD_ASHITA:-}" ] && [ -f "${DRIFTWOOD_ASHITA}/Ashita-cli.exe" ]; then
    printf '%s' "$DRIFTWOOD_ASHITA"
    return
  fi
  local lumoria="${HOME}/.var/app/net.windower.Lumoria/data/prefixes/prefix-1/pfx/drive_c/users/${USER}/AppData/Local/DriftwoodXI/Ashita"
  local candidate
  for candidate in \
    "$lumoria" \
    "${HOME}/ffxi/Ashita" \
    "${HOME}/Downloads/driftwoodxi-installer/Ashita" \
    "${HOME}/Games/ffxi/Ashita"; do
    if [ -f "${candidate}/Ashita-cli.exe" ]; then
      printf '%s' "$candidate"
      return
    fi
  done
  return 1
}

ASHITA="$(resolve_ashita)" || {
  echo "Ashita not found. Set DRIFTWOOD_ASHITA to your Ashita folder (contains Ashita-cli.exe)." >&2
  exit 1
}

if [ ! -f "$SRC/dwhub.lua" ]; then
  echo "dwhub source not found: $SRC/dwhub.lua" >&2
  exit 1
fi

DEST="${ASHITA}/addons/dwhub"
mkdir -p "${ASHITA}/addons"

echo "==> Sync dwhub"
echo "    from: $SRC"
echo "    to:   $DEST"

if command -v rsync >/dev/null 2>&1; then
  rsync -a --delete --exclude '.git' "$SRC/" "$DEST/"
else
  rm -rf "$DEST"
  cp -a "$SRC" "$DEST"
fi

VERSION="$(grep -E "^addon\.version" "$DEST/dwhub.lua" | head -1 | sed "s/.*= *['\"]\\([^'\"]*\\)['\"].*/\\1/")"
echo "    version: ${VERSION:-unknown}"

patch_boot() {
  local f="$1"
  [ -f "$f" ] || return 0
  cp -a "$f" "${f}.bak.$(date +%Y%m%d%H%M%S)"
  grep -q '/addon load dwhub' "$f" || sed -i '/\/addon load dwreport/a /addon load dwhub' "$f"
  grep -q '/bind F9 /dwhub' "$f" || sed -i '/^\/bind F12/a /bind F9 /dwhub' "$f"
  echo "  patched $f"
}

if [ "$PATCH_BOOT" -eq 1 ]; then
  echo "==> Patch boot scripts (load + F9 bind)"
  patch_boot "${ASHITA}/scripts/driftwood-default.txt"
  patch_boot "$(dirname "$ASHITA")/driftwood-default.txt"
fi

echo "Done. In game: /addon reload dwhub  (or relaunch). Toggle: /dwhub or F9."
