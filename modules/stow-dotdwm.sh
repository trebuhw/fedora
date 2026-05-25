#!/usr/bin/env bash
# =============================================================================
# stow-dotdwm.sh — Linkowanie dotfiles przez GNU Stow (uruchamiany jako user)
# =============================================================================
set -Eeuo pipefail

DOTDIR="$HOME/.dotdwm"
TARGET="$HOME"

info() { echo "[INFO] $*"; }
error() { echo "[ERROR] $*"; exit 1; }
trap 'error "Błąd w linii ${LINENO}"' ERR

# =============================================================================
# CHECKS
# =============================================================================
command -v stow >/dev/null 2>&1 || error "GNU Stow nie jest zainstalowany"
[[ -d "${DOTDIR}" ]]      || error "Nie istnieje katalog: ${DOTDIR}"
[[ -d "${DOTDIR}/.git" ]] || error "${DOTDIR} nie wygląda jak repo git"

# =============================================================================
# STOW PACKAGES
# =============================================================================
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
  "themes"
  "Thunar"
  "wallpaper"
  "xfce4"
  "xinitrc"
  "Xresources"
  "yazi"
  "zathura"
)

# =============================================================================
# CLEAN OLD CONFIG — bez sudo, jesteśmy userem
# =============================================================================
info "Usuwanie starej konfiguracji"

rm -rf \
  "${TARGET}/.bash_logout" \
  "${TARGET}/.bash_profile" \
  "${TARGET}/.bashrc" \
  "${TARGET}/.xinitrc" \
  "${TARGET}/.Xresources" \
  "${TARGET}/.fonts" \
  "${TARGET}/.icons" \
  "${TARGET}/.themes" \
  "${TARGET}/Obrazy" \
  "${TARGET}/.config/bash" \
  "${TARGET}/.config/bat" \
  "${TARGET}/.config/btop" \
  "${TARGET}/.config/dunst" \
  "${TARGET}/.config/fastfetch" \
  "${TARGET}/.config/fish" \
  "${TARGET}/.config/ghostty" \
  "${TARGET}/.config/nvim" \
  "${TARGET}/.config/rofi" \
  "${TARGET}/.config/suckless" \
  "${TARGET}/.config/sxiv" \
  "${TARGET}/.config/Thunar" \
  "${TARGET}/.config/xfce4" \
  "${TARGET}/.config/yazi" \
  "${TARGET}/.config/zathura" \
  "${TARGET}/.config/starship.toml"

# =============================================================================
# STOW — bez sudo, jesteśmy userem, symlinki będą należeć do usera
# =============================================================================
info "Linkowanie przez GNU Stow"

for pkg in "${STOW_PACKAGES[@]}"; do
  info "stow -> ${pkg}"
  stow \
    --dir="${DOTDIR}" \
    --target="${TARGET}" \
    --restow \
    "${pkg}"
done

info "Gotowe"
