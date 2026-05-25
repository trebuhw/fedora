#!/usr/bin/env bash
# =============================================================================
# desktop.sh — Środowisko DWM (compositor, notyfikacje, launcher)
# =============================================================================
set -euo pipefail

sudo dnf install -y \
  rofi \
  dunst \
  picom \
  feh \
  numlockx \
  brightnessctl
