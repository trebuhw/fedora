#!/usr/bin/env bash
# =============================================================================
# dotfiles.sh — Klonowanie / aktualizacja repozytorium .dotdwm
# =============================================================================
set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'
info() { echo -e "${GREEN}[INFO]${NC}  $*"; }
step() { echo -e "${BLUE}[STEP]${NC}  $*"; }
error() {
  echo -e "${RED}[ERROR]${NC} $*"
  exit 1
}

DOTFILES_REPO="https://github.com/trebuhw/.dotdwm.git"
DOTFILES_DIR="$HOME/.dotdwm"

step "Sprawdzanie zależności"
command -v git &>/dev/null || error "git nie jest zainstalowany"

info "Użytkownik: $USER"
info "HOME: $HOME"
info "Repo: $DOTFILES_REPO"

step "Sprawdzanie dostępu do repozytorium"
if ! git ls-remote "$DOTFILES_REPO" &>/dev/null; then
  error "Repozytorium niedostępne: $DOTFILES_REPO"
fi
info "Repozytorium dostępne"

if [[ -d "$DOTFILES_DIR/.git" ]]; then
  step "Aktualizacja istniejącego repozytorium"

  cd "$DOTFILES_DIR"

  # Jeśli są uncommitted changes — schowaj je, pull, przywróć
  if ! git diff --quiet || ! git diff --cached --quiet; then
    info "Wykryto lokalne zmiany — chowam do stash..."
    git stash push -m "auto-stash przed pull $(date +%Y%m%d-%H%M%S)"
    STASHED=true
  else
    STASHED=false
  fi

  git pull --rebase origin "$(git rev-parse --abbrev-ref HEAD)"

  if $STASHED; then
    info "Przywracam lokalne zmiany ze stash..."
    if git stash pop; then
      info "Stash przywrócony pomyślnie"
    else
      info "Konflikty przy przywracaniu stash — zmiany zostały w git stash list"
    fi
  fi
else
  step "Klonowanie repozytorium"
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi
