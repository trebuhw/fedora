#!/usr/bin/env bash
# =============================================================================
# cargo-apps.sh — Pakiety instalowane przez cargo
# =============================================================================
set -euo pipefail

CARGO_ENV="$HOME/.cargo/env"

# Sprawdź czy Rust jest zainstalowany
if [[ ! -f "$CARGO_ENV" ]]; then
    echo "BŁĄD: Rust nie jest zainstalowany. Uruchom najpierw build.sh"
    exit 1
fi

# shellcheck source=/dev/null
source "$CARGO_ENV"

# Weryfikacja
command -v cargo &>/dev/null || { echo "BŁĄD: cargo nie dostępne po załadowaniu env"; exit 1; }
echo "cargo: $(cargo --version)"

cargo install \
    bluetui \
    cargo-update \
    wlctl

echo "cargo-apps — OK"
