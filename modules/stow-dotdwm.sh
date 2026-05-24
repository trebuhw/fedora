#!/usr/bin/env bash
# =============================================================================
# stow-dotdwm.sh
#
# Bezpieczny deploy dotfiles:
# - jawna lista pakietów GNU Stow
# - backup starej konfiguracji (.bak.TIMESTAMP)
# - brak rm -rf na configach
# =============================================================================

set -Eeuo pipefail

# =============================================================================
# USER / PATHS
# =============================================================================

ACTUAL_USER="${SUDO_USER:-$USER}"
USER_HOME="$(getent passwd "$ACTUAL_USER" | cut -d: -f6)"

DOTDIR="${USER_HOME}/.dotdwm"
TARGET="${USER_HOME}"

# =============================================================================
# COLORS / LOGGING
# =============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

info() {
  echo -e "${GREEN}[INFO]${NC}  $*"
}

warn() {
  echo -e "${YELLOW}[WARN]${NC}  $*"
}

error() {
  echo -e "${RED}[ERROR]${NC} $*"
  exit 1
}

step() {
  echo -e "${BLUE}[STEP]${NC}  $*"
}

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
# STOW PACKAGES (MANUAL LIST)
# =============================================================================

step "Ładowanie listy pakietów stow"

STOW_PACKAGES=(
  "bash"
  "bat"
  "btop"
  "dunst"
  "fastfetch"
  "fish"
  "fonts"
  "ghostty"
  "icons"
  "nvim"
  "rofi"
  "starship"
  "suckless"
  "sxiv"
  "Thunar"
  "xfce4"
  "xorg"
  "yazi"
  "zathura"
)

VALID_PACKAGES=()

for pkg in "${STOW_PACKAGES[@]}"; do

  if [[ -d "${DOTDIR}/${pkg}" ]]; then
    VALID_PACKAGES+=("${pkg}")
    info "Dodano pakiet: ${pkg}"
  else
    warn "Nie istnieje pakiet: ${pkg}"
  fi
done

STOW_PACKAGES=("${VALID_PACKAGES[@]}")

[[ ${#STOW_PACKAGES[@]} -gt 0 ]] ||
  error "Brak poprawnych pakietów do stow"

# =============================================================================
# BACKUP OLD CONFIG
# =============================================================================

step "Tworzenie backupu starej konfiguracji"

REMOVE_PATHS=(
  "${TARGET}/.bash_logout"
  "${TARGET}/.bash_profile"
  "${TARGET}/.bashrc"
  "${TARGET}/.xinitrc"
  "${TARGET}/.Xresources"
  "${TARGET}/.fonts"
  "${TARGET}/.icons"
  "${TARGET}/.config/bash"
  "${TARGET}/.config/bat"
  "${TARGET}/.config/btop"
  "${TARGET}/.config/dunst"
  "${TARGET}/.config/fastfetch"
  "${TARGET}/.config/fish"
  "${TARGET}/.config/ghostty"
  "${TARGET}/.config/nvim"
  "${TARGET}/.config/rofi"
  "${TARGET}/.config/suckless"
  "${TARGET}/.config/sxiv"
  "${TARGET}/.config/Thunar"
  "${TARGET}/.config/xfce4"
  "${TARGET}/.config/yazi"
  "${TARGET}/.config/zathura"
  "${TARGET}/.config/starship.toml"
)

BACKUP_SUFFIX=".bak.$(date +%Y%m%d-%H%M%S)"

BACKED_UP_COUNT=0
SKIPPED_COUNT=0

for path in "${REMOVE_PATHS[@]}"; do

  if [[ -e "${path}" || -L "${path}" ]]; then

    backup_path="${path}${BACKUP_SUFFIX}"

    warn "Backup: ${path}"
    info " -> ${backup_path}"

    mv "${path}" "${backup_path}"

    ((BACKED_UP_COUNT++))

  else

    info "Nie istnieje: ${path}"
    ((SKIPPED_COUNT++))
  fi
done

info "Zbackupowano: ${BACKED_UP_COUNT}"
info "Pominięto: ${SKIPPED_COUNT}"

# =============================================================================
# GNU STOW
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

if [[ ${#STOW_OK[@]} -gt 0 ]]; then
  for pkg in "${STOW_OK[@]}"; do
    echo "  • ${pkg}"
  done
else
  warn "Brak poprawnie zalinkowanych pakietów"
fi

if [[ ${#STOW_FAIL[@]} -gt 0 ]]; then
  echo
  warn "Pakiety z błędami:"
  for pkg in "${STOW_FAIL[@]}"; do
    echo "  • ${pkg}"
  done
fi

echo
info "Backupy zapisane jako:"
echo "  *.bak.YYYYMMDD-HHMMSS"

echo
info "Sprawdzenie symlinków:"
echo "ls -la ${TARGET}/.config | grep ' -> '"

echo
info "Gotowe"
