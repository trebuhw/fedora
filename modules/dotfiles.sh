#!/usr/bin/env bash
# =============================================================================
# dotfiles.sh — Klonowanie / aktualizacja repozytorium dotfiles
# =============================================================================

set -Eeuo pipefail

# =============================================================================
# USER / PATHS
# =============================================================================

ACTUAL_USER="${SUDO_USER:-$USER}"
USER_HOME="$(getent passwd "$ACTUAL_USER" | cut -d: -f6)"

DOTFILES_DIR="${USER_HOME}/.dotdwm"
DOTFILES_REPO="https://github.com/trebuhw/.dotdwm.git"

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

trap 'error "Błąd w linii ${LINENO}"' ERR

# =============================================================================
# CHECKS
# =============================================================================

step "Sprawdzanie zależności"

command -v git >/dev/null 2>&1 ||
  error "git nie jest zainstalowany"

info "Użytkownik: ${ACTUAL_USER}"
info "HOME: ${USER_HOME}"
info "Repo: ${DOTFILES_REPO}"

# =============================================================================
# TEST REPO ACCESS
# =============================================================================

step "Sprawdzanie dostępu do repozytorium"

if ! sudo -u "${ACTUAL_USER}" git ls-remote "${DOTFILES_REPO}" &>/dev/null; then
  error "Brak dostępu do ${DOTFILES_REPO}"
fi

info "Repozytorium dostępne"

# =============================================================================
# CLONE / UPDATE
# =============================================================================

if [[ -d "${DOTFILES_DIR}/.git" ]]; then

  step "Aktualizacja istniejącego repozytorium"

  sudo -u "${ACTUAL_USER}" \
    git -C "${DOTFILES_DIR}" pull --rebase

  info "Repozytorium zaktualizowane"

elif [[ -d "${DOTFILES_DIR}" ]]; then

  error "${DOTFILES_DIR} istnieje ale nie jest repozytorium git"

else

  step "Klonowanie repozytorium"

  sudo -u "${ACTUAL_USER}" \
    git clone "${DOTFILES_REPO}" "${DOTFILES_DIR}"

  info "Repozytorium sklonowane"

fi

# =============================================================================
# PERMISSIONS SAFETY
# =============================================================================

step "Naprawa właściciela plików"

chown -R "${ACTUAL_USER}:${ACTUAL_USER}" "${DOTFILES_DIR}"

# =============================================================================
# SUMMARY
# =============================================================================

echo
info "dotfiles — OK"
info "Lokalizacja: ${DOTFILES_DIR}"
