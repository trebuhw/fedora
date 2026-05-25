#!/usr/bin/env bash
# =============================================================================
# build.sh — Narzędzia kompilacji + Rust
# =============================================================================
set -euo pipefail

sudo dnf install -y @development-tools

sudo dnf install -y \
  gettext \
  git \
  patch \
  subversion \
  diffstat \
  doxygen \
  patchutils \
  systemtap

sudo dnf install -y \
  dbus-devel \
  fontconfig-devel \
  fuse-libs \
  libX11-devel \
  libXft-devel \
  libXinerama-devel

# Rust — instalacja lub aktualizacja jako user (nie root)
if command -v rustup &>/dev/null; then
  echo "Rust już zainstalowany — aktualizuję..."
  rustup update stable
else
  echo "Instaluję Rust..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
  source "$HOME/.cargo/env"
fi

rustc --version
cargo --version
