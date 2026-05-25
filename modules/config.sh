#!/usr/bin/env bash
# =============================================================================
# config.sh — Konfiguracja systemu (wymaga sudo)
# =============================================================================
set -euo pipefail

# -----------------------------------------------------------------------------
# Sudoers
# -----------------------------------------------------------------------------
echo "Konfiguracja sudoers..."

sudo sed -i 's/^#\s*%wheel\s*ALL=(ALL)\s*ALL/%wheel  ALL=(ALL)       ALL/' /etc/sudoers

sudo usermod -aG wheel "$USER"

SUDOERS_TMP=$(mktemp)
sudo cp /etc/sudoers "$SUDOERS_TMP"

if ! sudo grep -q "^$USER" "$SUDOERS_TMP"; then
  echo "$USER  ALL=(ALL)       ALL" | sudo tee -a "$SUDOERS_TMP" > /dev/null
  echo "$USER  ALL=(ALL)       NOPASSWD: ALL" | sudo tee -a "$SUDOERS_TMP" > /dev/null
fi

if sudo visudo -c -f "$SUDOERS_TMP"; then
  sudo cp "$SUDOERS_TMP" /etc/sudoers
  echo "sudoers — OK"
else
  echo "BŁĄD: nieprawidłowa składnia sudoers — plik NIE został zmieniony"
  sudo rm -f "$SUDOERS_TMP"
  exit 1
fi
sudo rm -f "$SUDOERS_TMP"

# -----------------------------------------------------------------------------
# DNF
# -----------------------------------------------------------------------------
echo "Konfiguracja DNF..."
sudo grep -q "fastestmirror"        /etc/dnf/dnf.conf || echo "fastestmirror=True"        | sudo tee -a /etc/dnf/dnf.conf > /dev/null
sudo grep -q "max_parallel_downloads" /etc/dnf/dnf.conf || echo "max_parallel_downloads=10" | sudo tee -a /etc/dnf/dnf.conf > /dev/null
sudo grep -q "defaultyes"           /etc/dnf/dnf.conf || echo "defaultyes=True"           | sudo tee -a /etc/dnf/dnf.conf > /dev/null
sudo grep -q "keepcache"            /etc/dnf/dnf.conf || echo "keepcache=True"            | sudo tee -a /etc/dnf/dnf.conf > /dev/null

# -----------------------------------------------------------------------------
# Hostname
# -----------------------------------------------------------------------------
echo "Ustawiam hostname..."
sudo hostnamectl set-hostname fedora
sudo grep -q "127.0.1.1" /etc/hosts || echo "127.0.1.1   fedora" | sudo tee -a /etc/hosts > /dev/null

# -----------------------------------------------------------------------------
# Xorg
# -----------------------------------------------------------------------------
echo "Kopiuję konfigurację Xorg..."
sudo mkdir -p /etc/X11/xorg.conf.d

sudo tee /etc/X11/xorg.conf.d/00-keyboard.conf > /dev/null << 'XKBD'
Section "InputClass"
        Identifier "system-keyboard"
        MatchIsKeyboard "on"
        Option "XkbLayout" "pl"
        Option "XkbModel" "pc105"
EndSection
XKBD

sudo tee /etc/X11/xorg.conf.d/20-intel.conf > /dev/null << 'XINTEL'
Section "Device"
    Identifier "Intel Graphics"
    Driver "modesetting"
    Option "TearFree" "true"
EndSection
XINTEL

sudo tee /etc/X11/xorg.conf.d/90-touchpad.conf > /dev/null << 'XTOUCH'
Section "InputClass"
    Identifier "touchpad"
    MatchIsTouchpad "on"
    Driver "libinput"
    Option "Tapping" "on"
    Option "TappingButtonMap" "lmr"
    Option "NaturalScrolling" "on"
    Option "ScrollMethod" "twofinger"
EndSection
XTOUCH

# -----------------------------------------------------------------------------
# DWM — xsession + start wrapper
# -----------------------------------------------------------------------------
echo "Instaluję dwm.desktop..."
sudo mkdir -p /usr/share/xsessions
sudo tee /usr/share/xsessions/dwm.desktop > /dev/null << 'DWMDESKTOP'
[Desktop Entry]
Encoding=UTF-8
Name=dwm
Comment=Dynamic window manager
Exec=/usr/local/bin/start-dwm.sh
Type=Application
Icon=dwm
Type=XSession
X-LightDM-DesktopName=dwm
DWMDESKTOP

echo "Instaluję start-dwm.sh..."
sudo tee /usr/local/bin/start-dwm.sh > /dev/null << 'STARTDWM'
#!/bin/sh
# GDM przy sesjach Xorg nie sourcuje profilu użytkownika automatycznie.
# Bez tego $PATH jest niekompletny — ghostty, st i inne binarki z
# ~/.local/bin, ~/.cargo/bin nie są widoczne.
[ -f /etc/profile ] && . /etc/profile
[ -f "$HOME/.profile" ] && . "$HOME/.profile"

slstatus &
exec /usr/local/bin/dwm
STARTDWM
sudo chmod +x /usr/local/bin/start-dwm.sh

echo "config.sh — zakończony"
