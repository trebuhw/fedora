#!/usr/bin/env bash
# =============================================================================
# dotfiles.sh — Klonowanie/aktualizacja repozytorium dotfiles
# =============================================================================
set -euo pipefail

# POPRAWKA: użyj katalogu domowego rzeczywistego użytkownika, nie /root
ACTUAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)

DOTFILES_DIR="$USER_HOME/.dotdwm"
DOTFILES_REPO="https://github.com/trebuhw/.dotdwm.git"

# Sprawdź dostępność git
command -v git &>/dev/null || { echo "BŁĄD: git nie jest zainstalowany"; exit 1; }

# Sprawdź połączenie z repozytorium
if ! git ls-remote "$DOTFILES_REPO" &>/dev/null; then
  echo "BŁĄD: brak dostępu do $DOTFILES_REPO"
  exit 1
fi

if [[ -d "$DOTFILES_DIR/.git" ]]; then
  echo "Dotfiles już istnieją — aktualizuję..."
  git -C "$DOTFILES_DIR" pull --rebase
elif [[ -d "$DOTFILES_DIR" ]]; then
  echo "BŁĄD: $DOTFILES_DIR istnieje ale nie jest repozytorium git"
  exit 1
else
  echo "Klonuję dotfiles..."
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

echo "dotfiles — OK: $DOTFILES_DIR"
