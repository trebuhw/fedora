#!/usr/bin/env bash
# =============================================================================
# stow-dotdwm.sh
#
# Bezpieczne czyszczenie starej konfiguracji + linkowanie GNU Stow
# =============================================================================

set -Eeuo pipefail

# =============================================================================
# USER / PATHS
# =============================================================================

ACTUAL_USER="${SUDO_USER:-$USER}"
USER_HOME="$(getent passwd "$ACTUAL_USER" | cut -d: -f6)"

DOTDIR="${USER_HOME}/.dotdwm"
TARGET="${USER_HOME}"

SKIP_PACKAGES=(
  "etc"
  "usr"
)

# =============================================================================
# COLORS / LOGGING
# =============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() {
  echo -e "${RED}[ERROR]${NC} $*"
  exit 1
}
step() { echo -e "${BLUE}[STEP]${NC}  $*"; }

# =============================================================================
# ERROR HANDLER
# =============================================================================

trap 'error "Błąd w linii ${LINENO}"' ERR

# =============================================================================
# CHECKS
# =============================================================================

step "Sprawdzanie zależności"

command -v stow >/dev/null 2>&1 ||
  error "GNU Stow nie jest zainstalowany"

[[ -d "${DOTDIR}" ]] ||
  error "Nie istnieje katalog: ${DOTDIR}"

[[ -d "${DOTDIR}/.git" ]] ||
  error "${DOTDIR} nie wygląda jak repozytorium git"

info "Użytkownik: ${ACTUAL_USER}"
info "HOME: ${USER_HOME}"
info "DOTDIR: ${DOTDIR}"

# =============================================================================
# STOW PACKAGE DISCOVERY
# =============================================================================

step "Wyszukiwanie pakietów stow"

mapfile -t ALL_PACKAGES < <(
  find "${DOTDIR}" \
    -mindepth 1 \
    -maxdepth 1 \
    -type d \
    ! -name '.git' \
    -printf '%f\n' |
    sort
)

STOW_PACKAGES=()

for pkg in "${ALL_PACKAGES[@]}"; do

  skip=false

  for s in "${SKIP_PACKAGES[@]}"; do
    if [[ "${pkg}" == "${s}" ]]; then
      skip=true
      break
    fi
  done

  if $skip; then
    warn "Pomijam pakiet: ${pkg}"
  else
    STOW_PACKAGES+=("${pkg}")
    info "Dodano pakiet: ${pkg}"
  fi
done

[[ ${#STOW_PACKAGES[@]} -gt 0 ]] ||
  error "Brak pakietów do stow"

# =============================================================================
# CLEANUP
# =============================================================================

step "Usuwanie starej konfiguracji"

REMOVE_PATHS=(

  # shell
  "${TARGET}/.bash_logout"
  "${TARGET}/.bash_profile"
  "${TARGET}/.bashrc"

  # xorg
  "${TARGET}/.xinitrc"
  "${TARGET}/.Xresources"

  # assets
  "${TARGET}/.fonts"
  "${TARGET}/.icons"

  # config dirs
  "${TARGET}/.config/bash"
  "${TARGET}/.config/bat"
  "${TARGET}/.config/btop"
  "${TARGET}/.config/dunst"
  "${TARGET}/.config/fastfetch"
  "${TARGET}/.config/fish"
  "${TARGET}/.config/geany"
  "${TARGET}/.config/ghostty"
  "${TARGET}/.config/nvim"
  "${TARGET}/.config/rofi"
  "${TARGET}/.config/suckless"
  "${TARGET}/.config/sxiv"
  "${TARGET}/.config/Thunar"
  "${TARGET}/.config/xfce4"
  "${TARGET}/.config/yazi"
  "${TARGET}/.config/zathura"

  # files
  "${TARGET}/.config/starship.toml"
)

REMOVED_COUNT=0
SKIPPED_COUNT=0

for path in "${REMOVE_PATHS[@]}"; do

  if [[ -e "${path}" || -L "${path}" ]]; then

    warn "Usuwam: ${path}"

    rm -rf "${path}"

    ((REMOVED_COUNT++))

  else

    info "Nie istnieje: ${path}"

    ((SKIPPED_COUNT++))

  fi
done

info "Usunięto: ${REMOVED_COUNT}"
info "Pominięto: ${SKIPPED_COUNT}"

# =============================================================================
# STOW
# =============================================================================

step "Linkowanie przez GNU Stow"

cd "${DOTDIR}"

STOW_OK=()
STOW_FAIL=()

for pkg in "${STOW_PACKAGES[@]}"; do

  info "stow -> ${pkg}"

  if stow \
    --target="${TARGET}" \
    --restow \
    "${pkg}"; then
    STOW_OK+=("${pkg}")
    info "OK -> ${pkg}"
  else
    STOW_FAIL+=("${pkg}")
    warn "FAIL -> ${pkg}"
  fi
done

# =============================================================================
# SUMMARY
# =============================================================================

echo
step "Podsumowanie"

info "Zalinkowane pakiety:"
for pkg in "${STOW_OK[@]}"; do
  echo "  • ${pkg}"
done

if [[ ${#STOW_FAIL[@]} -gt 0 ]]; then
  echo
  warn "Pakiety z błędami:"
  for pkg in "${STOW_FAIL[@]}"; do
    echo "  • ${pkg}"
  done
fi

echo
info "Sprawdzenie symlinków:"
echo "ls -la ${TARGET}/.config | grep ' -> '"

echo
info "Gotowe"
