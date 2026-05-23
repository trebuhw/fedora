#!/usr/bin/env bash
# =============================================================================
# build.sh — Narzędzia kompilacji + Rust/Cargo
# =============================================================================
set -euo pipefail

# Narzędzia developerskie i biblioteki do suckless
dnf install -y \
    development-tools \
    dbus-devel \
    fontconfig-devel \
    fuse-libs \
    libX11-devel \
    libXft-devel \
    libXinerama-devel

# Rust + Cargo (oficjalny instalator)
if command -v rustup &>/dev/null; then
    echo "Rust już zainstalowany — aktualizuję..."
    rustup update stable
else
    echo "Instaluję Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
fi

# Załaduj środowisko cargo
# shellcheck source=/dev/null
source "$HOME/.cargo/env"

# Weryfikacja
rustc --version
cargo --version
