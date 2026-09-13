#!/bin/sh
set -eu

ARCH="${1:-amd64}"

case "$ARCH" in
    amd64)
        XRAY_ARCH="64"
        ;;
    arm64)
        XRAY_ARCH="arm64-v8a"
        ;;
    arm)
        XRAY_ARCH="arm32-v7a"
        ;;
    *)
        echo "unsupported architecture: $ARCH" >&2
        exit 1
        ;;
esac

XRAY_TAG="v26.6.22"
BIN_DIR="/app/bin"
mkdir -p "$BIN_DIR"

TMP_ZIP="$(mktemp)"
TMP_DGST="$(mktemp)"
trap 'rm -f "$TMP_ZIP" "$TMP_DGST"' EXIT

BASE="https://github.com/XTLS/Xray-core/releases/download/${XRAY_TAG}/Xray-linux-${XRAY_ARCH}.zip"

curl -fL --retry 5 --retry-delay 3 -o "$TMP_ZIP" "$BASE"
curl -fL --retry 5 --retry-delay 3 -o "$TMP_DGST" "$BASE.dgst"

EXPECTED="$(grep -i '^SHA2-256=' "$TMP_DGST" | head -n1 | cut -d= -f2 | tr -d '[:space:]')"
ACTUAL="$(sha256sum "$TMP_ZIP" | awk '{print $1}')"

if [ -z "$EXPECTED" ] || [ "$EXPECTED" != "$ACTUAL" ]; then
    echo "Xray archive SHA-256 verification failed" >&2
    exit 1
fi

unzip -o -j "$TMP_ZIP" -d "$BIN_DIR"
mv "$BIN_DIR/xray" "$BIN_DIR/xray-linux-${ARCH}"
chmod +x "$BIN_DIR/xray-linux-${ARCH}"

curl -fL --retry 5 --retry-delay 3 -o "$BIN_DIR/geoip.dat" \
    "https://github.com/v2fly/geoip/releases/latest/download/geoip.dat"
curl -fL --retry 5 --retry-delay 3 -o "$BIN_DIR/geosite.dat" \
    "https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat"

echo "Official Xray ${XRAY_TAG} (linux-${ARCH}) installed to ${BIN_DIR}"
