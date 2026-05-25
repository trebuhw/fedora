#!/usr/bin/env bash
# =============================================================================
# xorg.sh — Xorg + sterowniki + narzędzia graficzne
# =============================================================================
set -euo pipefail

sudo dnf install -y \
  xorg-x11-server-Xorg \
  xorg-x11-drv-intel \
  xrandr \
  xsetroot \
  xset \
  xclip
