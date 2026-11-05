#!/usr/bin/env bash
# Read the shutter count of a Canon EOS camera over USB with gphoto2 on macOS.
#
# Usage:
#   ./shutter-count.sh            # print the camera model and shutter count
#   ./shutter-count.sh --raw      # print only the number (for scripts)
#   ./shutter-count.sh --install  # install gphoto2 with Homebrew if missing

set -euo pipefail

RAW=0
INSTALL=0
for arg in "$@"; do
  case "$arg" in
    --raw) RAW=1 ;;
    --install) INSTALL=1 ;;
    -h|--help)
      sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

log() { [[ $RAW -eq 1 ]] || echo "$@"; }

# 1) Check for gphoto2
if ! command -v gphoto2 >/dev/null 2>&1; then
  if [[ $INSTALL -eq 1 ]]; then
    command -v brew >/dev/null 2>&1 || { echo "Homebrew is not installed (https://brew.sh)." >&2; exit 1; }
    log "Installing gphoto2..."
    brew install gphoto2
  else
    echo "gphoto2 is not installed. Run: brew install gphoto2  (or: $0 --install)" >&2
    exit 1
  fi
fi

export LANG=C   # English error messages so the output can be parsed reliably

# The macOS camera services (ptpcamerad, mscamerad-xpc) claim the camera.
release_camera() {
  killall -9 ptpcamerad mscamerad-xpc >/dev/null 2>&1 || true
}

# 2) Find the camera
release_camera
MODEL=$(gphoto2 --auto-detect 2>/dev/null | awk 'NR>2 && NF { sub(/[[:space:]]+usb:.*/, ""); print; exit }')
if [[ -z "$MODEL" ]]; then
  echo "No USB camera found. Turn the camera on and check the cable." >&2
  exit 1
fi
log "Camera: $MODEL"

# 3) Read the counter – ptpcamerad restarts on its own, so retry a few times
OUT=""
for _ in 1 2 3 4 5 6 7 8; do
  release_camera
  OUT=$(gphoto2 --get-config /main/status/shuttercounter 2>&1) || true
  grep -q "Could not claim" <<<"$OUT" || break
  sleep 0.3
done

COUNT=$(awk -F': ' '/^Current:/ { print $2; exit }' <<<"$OUT")
if [[ -z "$COUNT" ]]; then
  echo "Could not read the shutter count. gphoto2 output:" >&2
  echo "$OUT" >&2
  echo "This camera model may not expose the counter over PTP." >&2
  exit 1
fi

if [[ $RAW -eq 1 ]]; then
  echo "$COUNT"
else
  echo "Shutter count: $COUNT"
fi
