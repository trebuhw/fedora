#!/usr/bin/env bash
# =============================================================================
# stow-dotdwm.sh — Usuwanie istniejących plików i linkowanie przez stow
# =============================================================================
set -euo pipefail

# POPRAWKA: użyj katalogu domowego rzeczywistego użytkownika, nie /root
ACTUAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)

DOTDIR="${USER_HOME}/.dotdwm"
TARGET="${USER_HOME}"
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
    ! -name '.git' -print0 \
    | xargs -0 -I{} basename {} \
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
# Faza 1: Usuń istniejące pliki i katalogi (stow wymaga czystego terenu)
# -----------------------------------------------------------------------------
info "=== Faza 1: Usuwanie istniejących plików i katalogów ==="

for pkg in "${STOW_PACKAGES[@]}"; do
  pkg_dir="${DOTDIR}/${pkg}"

  # Usuń pliki
  while IFS= read -r -d '' src_file; do
    rel_path="${src_file#"${pkg_dir}"/}"
    target_path="${TARGET}/${rel_path}"
    if [[ -e "${target_path}" && ! -L "${target_path}" ]]; then
      warn "Usuwam plik: ${target_path}"
      rm -rf "${target_path}"
    fi
  done < <(find "${pkg_dir}" -mindepth 1 -not -type d -print0)

  # Usuń katalogi które stow chce zlinkować (katalogi najwyższego poziomu w pakiecie)
  while IFS= read -r -d '' src_dir; do
    rel_path="${src_dir#"${pkg_dir}"/}"
    target_path="${TARGET}/${rel_path}"
    if [[ -d "${target_path}" && ! -L "${target_path}" ]]; then
      warn "Usuwam katalog: ${target_path}"
      rm -rf "${target_path}"
    fi
  done < <(find "${pkg_dir}" -mindepth 1 -maxdepth 1 -type d -print0)
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
info "Sprawdź: ls -la ${TARGET}/.config | grep ' -> '"
