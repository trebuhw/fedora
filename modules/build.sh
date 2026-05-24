#!/usr/bin/env bash
# =============================================================================
# build.sh — Narzędzia kompilacji + Rust/Cargo
# =============================================================================
set -euo pipefail

ACTUAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)

# POPRAWKA: development-tools to grupa — musi iść przez dnf group install (DNF5)
dnf group install -y "development-tools"

# Biblioteki do suckless
dnf install -y \
  dbus-devel \
  fontconfig-devel \
  fuse-libs \
  libX11-devel \
  libXft-devel \
  libXinerama-devel

# Rust + Cargo (oficjalny instalator)
# POPRAWKA: wymuszamy bash (domyślny shell to fish, który nie ładuje cargo env)
CARGO_ENV="$USER_HOME/.cargo/env"
RUN_AS="runuser -l $ACTUAL_USER -s /bin/bash -c"

if $RUN_AS 'command -v rustup &>/dev/null'; then
  echo "Rust już zainstalowany — aktualizuję..."
  $RUN_AS 'rustup update stable'
else
  echo "Instaluję Rust..."
  $RUN_AS 'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path'
fi

# Weryfikacja z jawnym załadowaniem env
$RUN_AS "source $CARGO_ENV && rustc --version && cargo --version"
