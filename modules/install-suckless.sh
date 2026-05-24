#!/usr/bin/env bash
# =============================================================================
# install-suckless.sh — Kompilacja i instalacja: dwm, st, slstatus, dmenu
# =============================================================================
set -euo pipefail

ACTUAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)

SUCKLESS_DIR="${USER_HOME}/.config/suckless"
TOOLS=("dwm" "st" "slstatus" "dmenu")

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
info() { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() {
  echo -e "${RED}[ERROR]${NC} $*"
  exit 1
}

[[ -d "${SUCKLESS_DIR}" ]] || error "${SUCKLESS_DIR} nie istnieje. Uruchom najpierw stow-dotdwm.sh"

command -v make &>/dev/null || error "make nie jest zainstalowany. Uruchom najpierw build.sh"
command -v gcc &>/dev/null || error "gcc nie jest zainstalowany. Uruchom najpierw build.sh"

FAILED_TOOLS=()

for tool in "${TOOLS[@]}"; do
  tool_dir="${SUCKLESS_DIR}/${tool}"
  echo ""
  info "=== ${tool} ==="

  if [[ ! -d "${tool_dir}" ]]; then
    warn "Katalog ${tool_dir} nie istnieje — pomijam"
    FAILED_TOOLS+=("${tool}")
    continue
  fi

  if [[ ! -f "${tool_dir}/Makefile" ]]; then
    warn "Brak Makefile w ${tool_dir} — pomijam"
    FAILED_TOOLS+=("${tool}")
    continue
  fi

  cd "${tool_dir}"

  # Usuń config.h — make wygeneruje go z config.def.h
  # Usuń też jeśli jest symlinkiem (po stow)
  if [[ -f "config.h" || -L "config.h" ]]; then
    info "Usuwam config.h"
    rm -f config.h
  fi

  # Kompilacja jako ACTUAL_USER — pliki .o i binarka należą do usera, nie roota
  info "make (jako ${ACTUAL_USER})..."
  if ! sudo -u "${ACTUAL_USER}" make; then
    warn "make failed dla ${tool}"
    FAILED_TOOLS+=("${tool}")
    continue
  fi

  # make install wymaga roota (kopiuje do /usr/local/bin)
  info "make install (jako root)..."
  if ! make install; then
    warn "make install failed dla ${tool}"
    FAILED_TOOLS+=("${tool}")
    continue
  fi

  # Po instalacji przywróć własność plików w katalogu usera
  chown -R "${ACTUAL_USER}:${ACTUAL_USER}" "${tool_dir}"

  info "✓ ${tool} zainstalowany"
done

echo ""
if [[ ${#FAILED_TOOLS[@]} -gt 0 ]]; then
  warn "Nieudane: ${FAILED_TOOLS[*]}"
  exit 1
else
  info "=== Wszystkie narzędzia suckless zainstalowane ==="
fi
