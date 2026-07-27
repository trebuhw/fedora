#!/usr/bin/env bash
# =============================================================================
# xorg.sh — Xorg + sterowniki + narzędzia graficzne
# =============================================================================
set -euo pipefail

sudo dnf install -y \
  xorg-x11-server-Xorg \
  xrandr \
  xsetroot \
  xset \
  xclip

# -----------------------------------------------------------------------------
# Sterownik Intel — tylko jeśli faktycznie wykryto GPU Intela.
# Zabezpieczenie przed sytuacją, gdyby ten skrypt uruchomiono kiedyś na innym
# sprzęcie (AMD/Nvidia) — wtedy instalacja xorg-x11-drv-intel jest bezcelowa.
# -----------------------------------------------------------------------------
GPU_INFO=$(command -v lspci &>/dev/null && lspci -nn 2>/dev/null | grep -Ei 'vga compatible controller|3d controller' || true)

if echo "$GPU_INFO" | grep -qi intel; then
  echo "GPU: wykryto Intel — instaluję xorg-x11-drv-intel."
  sudo dnf install -y xorg-x11-drv-intel
else
  echo "GPU: nie wykryto Intela (${GPU_INFO:-brak danych z lspci}) — pomijam xorg-x11-drv-intel."
  echo "Xorg użyje domyślnego sterownika 'modesetting' dla wykrytego GPU."
fi
