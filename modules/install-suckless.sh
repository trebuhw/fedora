#!/usr/bin/env bash
# =============================================================================
# install-suckless.sh — Kompilacja i instalacja: dwm, st, slstatus, dmenu
# =============================================================================
set -euo pipefail

SUCKLESS_DIR="${HOME}/.config/suckless"
TOOLS=("dwm" "st" "slstatus" "dmenu")

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# Sprawdź czy katalog suckless istnieje (musi być po stow)
[[ -d "${SUCKLESS_DIR}" ]] || error "${SUCKLESS_DIR} nie istnieje. Uruchom najpierw stow-dotdwm.sh"

# Sprawdź narzędzia kompilacji
command -v make &>/dev/null || error "make nie jest zainstalowany. Uruchom najpierw build.sh"
command -v gcc  &>/dev/null || error "gcc nie jest zainstalowany. Uruchom najpierw build.sh"

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
    [[ -f "config.h" ]] && { info "Usuwam config.h"; rm -f config.h; }

    info "make..."
    if ! make; then
        error "make failed dla ${tool}"
        FAILED_TOOLS+=("${tool}")
        continue
    fi

    info "sudo make clean install..."
    if ! sudo make clean install; then
        error "make install failed dla ${tool}"
        FAILED_TOOLS+=("${tool}")
        continue
    fi

    info "✓ ${tool} zainstalowany"
done

echo ""
if [[ ${#FAILED_TOOLS[@]} -gt 0 ]]; then
    warn "Nieudane: ${FAILED_TOOLS[*]}"
    exit 1
else
    info "=== Wszystkie narzędzia suckless zainstalowane ==="
fi
