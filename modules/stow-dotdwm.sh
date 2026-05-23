#!/usr/bin/env bash
# =============================================================================
# stow-dotdwm.sh — Backup istniejących plików i linkowanie przez stow
# =============================================================================
set -euo pipefail

DOTDIR="${HOME}/.dotdwm"
TARGET="${HOME}"
SKIP_PACKAGES=("etc" "usr")

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# Sprawdź zależności
command -v stow &>/dev/null || error "stow nie jest zainstalowany: sudo dnf install stow"

# Sprawdź czy repo istnieje
[[ -d "${DOTDIR}/.git" ]] || error "Katalog ${DOTDIR} nie jest repozytorium git. Uruchom najpierw dotfiles.sh"

# Zbierz pakiety
mapfile -t ALL_PACKAGES < <(
    find "${DOTDIR}" -mindepth 1 -maxdepth 1 -type d \
        ! -name '.git' \
        | xargs -I{} basename {} \
        | sort
)

STOW_PACKAGES=()
for pkg in "${ALL_PACKAGES[@]}"; do
    skip=false
    for s in "${SKIP_PACKAGES[@]}"; do
        [[ "${pkg}" == "${s}" ]] && skip=true && break
    done
    if $skip; then
        warn "Pomijam (ref): ${pkg}"
    else
        STOW_PACKAGES+=("${pkg}")
    fi
done

# -----------------------------------------------------------------------------
# Faza 1: Backup
# -----------------------------------------------------------------------------
info "=== Faza 1: Backup ==="

for pkg in "${STOW_PACKAGES[@]}"; do
    pkg_dir="${DOTDIR}/${pkg}"

    while IFS= read -r -d '' src_file; do
        rel_path="${src_file#${pkg_dir}/}"
        target_path="${TARGET}/${rel_path}"

        if [[ -e "${target_path}" && ! -L "${target_path}" ]]; then
            bak_path="${target_path}.bak"
            # Jeśli .bak już istnieje — dodaj timestamp żeby nie nadpisać
            [[ -e "${bak_path}" ]] && bak_path="${target_path}.bak.$(date +%s)"
            warn "Backup: ${target_path} → ${bak_path}"
            mv "${target_path}" "${bak_path}"
        fi
    done < <(find "${pkg_dir}" -mindepth 1 -not -type d -print0)
done

# -----------------------------------------------------------------------------
# Faza 2: Stow
# -----------------------------------------------------------------------------
info "=== Faza 2: Stow ==="

cd "${DOTDIR}"

for pkg in "${STOW_PACKAGES[@]}"; do
    info "stow: ${pkg}"
    stow --target="${TARGET}" --restow "${pkg}"
done

info "=== Gotowe ==="
info "Zalinkowane: ${STOW_PACKAGES[*]}"
warn "Pominięte:   ${SKIP_PACKAGES[*]}"
info "Sprawdź: ls -la ~/.config | grep ' -> '"
