#!/usr/bin/env bash
# =============================================================================
# dotfiles.sh — Klonowanie/aktualizacja repozytorium dotfiles
# =============================================================================
set -euo pipefail

DOTFILES_DIR="$HOME/.dotdwm"
DOTFILES_REPO="https://github.com/trebuhw/.dotdwm.git"

# Sprawdź dostępność git
command -v git &>/dev/null || { echo "BŁĄD: git nie jest zainstalowany"; exit 1; }

# Sprawdź połączenie z internetem
if ! curl -fsS --max-time 5 https://github.com &>/dev/null; then
    echo "BŁĄD: brak połączenia z github.com"
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
