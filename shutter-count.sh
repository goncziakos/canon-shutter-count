#!/usr/bin/env bash
# Canon EOS exponálásszámláló (shutter count) kiolvasása USB-n, gphoto2-vel, macOS-en.
#
# Használat:
#   ./shutter-count.sh            # kiírja a gép típusát és a számlálót
#   ./shutter-count.sh --raw      # csak a számot írja ki (scriptekhez)
#   ./shutter-count.sh --install  # gphoto2 telepítése Homebrew-val, ha hiányzik

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
    *) echo "Ismeretlen kapcsoló: $arg" >&2; exit 2 ;;
  esac
done

log() { [[ $RAW -eq 1 ]] || echo "$@"; }

# 1) gphoto2 ellenőrzése
if ! command -v gphoto2 >/dev/null 2>&1; then
  if [[ $INSTALL -eq 1 ]]; then
    command -v brew >/dev/null 2>&1 || { echo "Homebrew nincs telepítve (https://brew.sh)." >&2; exit 1; }
    log "gphoto2 telepítése..."
    brew install gphoto2
  else
    echo "A gphoto2 nincs telepítve. Futtasd: brew install gphoto2  (vagy: $0 --install)" >&2
    exit 1
  fi
fi

export LANG=C   # angol hibaüzenetek, hogy a kimenet megbízhatóan értelmezhető legyen

# A macOS kameraszolgáltatásai (ptpcamerad, mscamerad-xpc) lefoglalják a gépet.
release_camera() {
  killall -9 ptpcamerad mscamerad-xpc >/dev/null 2>&1 || true
}

# 2) Gép keresése
release_camera
MODEL=$(gphoto2 --auto-detect 2>/dev/null | awk 'NR>2 && NF { sub(/[[:space:]]+usb:.*/, ""); print; exit }')
if [[ -z "$MODEL" ]]; then
  echo "Nem található USB-n csatlakoztatott fényképezőgép. Kapcsold be, és ellenőrizd a kábelt." >&2
  exit 1
fi
log "Gép: $MODEL"

# 3) Számláló kiolvasása – a ptpcamerad újraindul, ezért többször próbálkozunk
OUT=""
for _ in 1 2 3 4 5 6 7 8; do
  release_camera
  OUT=$(gphoto2 --get-config /main/status/shuttercounter 2>&1) || true
  grep -q "Could not claim" <<<"$OUT" || break
  sleep 0.3
done

COUNT=$(awk -F': ' '/^Current:/ { print $2; exit }' <<<"$OUT")
if [[ -z "$COUNT" ]]; then
  echo "Nem sikerült kiolvasni a számlálót. gphoto2 kimenete:" >&2
  echo "$OUT" >&2
  echo "Lehet, hogy ez a géptípus nem adja ki a számlálót PTP-n keresztül." >&2
  exit 1
fi

if [[ $RAW -eq 1 ]]; then
  echo "$COUNT"
else
  echo "Exponálásszám: $COUNT"
fi
