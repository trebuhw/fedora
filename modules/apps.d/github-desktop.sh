#!/bin/bash
# GitHub Desktop (fork shiftkey/desktop)
# Instalacja z pliku .rpm bez dodawania stałego repozytorium do systemu.

set -e

ARCH=$(uname -m)
RELEASE_JSON=$(curl -fsSL https://api.github.com/repos/shiftkey/desktop/releases/latest)
RPM_URL=$(printf '%s\n' "$RELEASE_JSON" | grep -oE "\"browser_download_url\": *\"[^\"]+${ARCH}[^\"]*\\.rpm\"" | head -n 1 | cut -d '"' -f4)

if [ -z "$RPM_URL" ]; then
  echo "GitHub Desktop: nie znaleziono pakietu .rpm dla architektury ${ARCH}." >&2
  exit 1
fi

RPM_FILE="/tmp/$(basename "$RPM_URL")"
curl -fL "$RPM_URL" -o "$RPM_FILE"
sudo dnf install -y "$RPM_FILE"
rm -f "$RPM_FILE"
