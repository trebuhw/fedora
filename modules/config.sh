#!/usr/bin/env bash
# =============================================================================
# config.sh — Konfiguracja systemu
# Wymaga: root
# =============================================================================
set -euo pipefail

# Użytkownik który uruchomił sudo (nie root)
ACTUAL_USER="${SUDO_USER:-$USER}"
[[ -z "$ACTUAL_USER" || "$ACTUAL_USER" == "root" ]] && {
  echo "BŁĄD: nie można ustalić użytkownika — uruchom przez sudo, nie jako root bezpośrednio"
  exit 1
}

# -----------------------------------------------------------------------------
# Sudoers
# -----------------------------------------------------------------------------
echo "Konfiguracja sudoers..."

# Odkomentuj %wheel ALL=(ALL) ALL
sed -i 's/^#\s*%wheel\s*ALL=(ALL)\s*ALL/%wheel  ALL=(ALL)       ALL/' /etc/sudoers

# Dodaj użytkownika do grupy wheel
usermod -aG wheel "$ACTUAL_USER"

# Dodaj wpisy przez visudo (bezpieczne — waliduje składnię)
SUDOERS_TMP=$(mktemp)
cp /etc/sudoers "$SUDOERS_TMP"

if ! grep -q "^$ACTUAL_USER" "$SUDOERS_TMP"; then
  echo "$ACTUAL_USER  ALL=(ALL)       ALL" >>"$SUDOERS_TMP"
  echo "$ACTUAL_USER  ALL=(ALL)       NOPASSWD: ALL" >>"$SUDOERS_TMP"
fi

# Waliduj przed nadpisaniem
if visudo -c -f "$SUDOERS_TMP"; then
  cp "$SUDOERS_TMP" /etc/sudoers
  echo "sudoers — OK"
else
  echo "BŁĄD: nieprawidłowa składnia sudoers — plik NIE został zmieniony"
  rm -f "$SUDOERS_TMP"
  exit 1
fi
rm -f "$SUDOERS_TMP"

# -----------------------------------------------------------------------------
# DNF
# -----------------------------------------------------------------------------
echo "Konfiguracja DNF..."

# Dodaj tylko brakujące opcje (nie duplikuj przy ponownym uruchomieniu)
grep -q "fastestmirror" /etc/dnf/dnf.conf || echo "fastestmirror=True" >>/etc/dnf/dnf.conf
grep -q "max_parallel_downloads" /etc/dnf/dnf.conf || echo "max_parallel_downloads=10" >>/etc/dnf/dnf.conf
grep -q "defaultyes" /etc/dnf/dnf.conf || echo "defaultyes=True" >>/etc/dnf/dnf.conf
grep -q "keepcache" /etc/dnf/dnf.conf || echo "keepcache=True" >>/etc/dnf/dnf.conf

# -----------------------------------------------------------------------------
# Hostname
# -----------------------------------------------------------------------------
echo "Ustawiam hostname..."
hostnamectl set-hostname fedora
grep -q "127.0.1.1" /etc/hosts || echo "127.0.1.1   fedora" >>/etc/hosts

# -----------------------------------------------------------------------------
# Xorg
# -----------------------------------------------------------------------------
echo "Kopiuję konfigurację Xorg..."
mkdir -p /etc/X11/xorg.conf.d

cat >/etc/X11/xorg.conf.d/00-keyboard.conf <<'XKBD'
Section "InputClass"
        Identifier "system-keyboard"
        MatchIsKeyboard "on"
        Option "XkbLayout" "pl"
        Option "XkbModel" "pc105"
EndSection
XKBD

cat >/etc/X11/xorg.conf.d/20-intel.conf <<'XINTEL'
Section "Device"
    Identifier "Intel Graphics"
    Driver "modesetting"
    Option "TearFree" "true"
EndSection
XINTEL

cat >/etc/X11/xorg.conf.d/90-touchpad.conf <<'XTOUCH'
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
mkdir -p /usr/share/xsessions
cat >/usr/share/xsessions/dwm.desktop <<'DWMDESKTOP'
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
cat >/usr/local/bin/start-dwm.sh <<'STARTDWM'
#!/bin/sh
slstatus &
exec /usr/local/bin/dwm
STARTDWM
chmod +x /usr/local/bin/start-dwm.sh

echo "config.sh — zakończony"
