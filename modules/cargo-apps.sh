#!/usr/bin/env bash
# =============================================================================
# cargo-apps.sh — Pakiety instalowane przez cargo (uruchamiany jako user)
# =============================================================================
set -euo pipefail

CARGO_ENV="$HOME/.cargo/env"

[[ -f "$CARGO_ENV" ]] || { echo "BŁĄD: Rust nie jest zainstalowany. Uruchom najpierw build.sh"; exit 1; }

# Załaduj cargo env
# shellcheck source=/dev/null
source "$CARGO_ENV"

cargo --version || { echo "BŁĄD: cargo niedostępne"; exit 1; }

cargo install bluetui cargo-update wlctl

echo "cargo-apps — OK"
