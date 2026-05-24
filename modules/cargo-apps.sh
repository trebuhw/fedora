#!/usr/bin/env bash
# =============================================================================
# cargo-apps.sh — Pakiety instalowane przez cargo
# =============================================================================
set -euo pipefail

# POPRAWKA: użyj katalogu domowego rzeczywistego użytkownika, nie /root
ACTUAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)

CARGO_ENV="$USER_HOME/.cargo/env"
RUN_AS="runuser -l $ACTUAL_USER -s /bin/bash -c"

# Sprawdź czy Rust jest zainstalowany
if [[ ! -f "$CARGO_ENV" ]]; then
  echo "BŁĄD: Rust nie jest zainstalowany. Uruchom najpierw build.sh"
  exit 1
fi

# Weryfikacja
$RUN_AS "source $CARGO_ENV && cargo --version" \
  || { echo "BŁĄD: cargo nie dostępne"; exit 1; }

# POPRAWKA: bash + jawne załadowanie env (domyślny shell to fish)
$RUN_AS "source $CARGO_ENV && cargo install bluetui cargo-update wlctl"

echo "cargo-apps — OK"
