#!/usr/bin/env bash
# =============================================================================
# config.sh — Konfiguracja systemu (wymaga sudo)
# =============================================================================
set -euo pipefail

# -----------------------------------------------------------------------------
# Sudoers
# -----------------------------------------------------------------------------
echo "Konfiguracja sudoers..."

sudo usermod -aG wheel "$USER"

# Operacje na /etc/sudoers w całości jako root przez heredoc
# $USER i $CURRENT_USER są rozwijane przez shell usera zanim trafią do sudo
CURRENT_USER="$USER"
sudo bash -s <<SUDOERS_EOF
  set -e
  sed -i 's/^#[[:space:]]*%wheel[[:space:]]*ALL=(ALL)[[:space:]]*ALL/%wheel  ALL=(ALL)       ALL/' /etc/sudoers

  TMP=\$(mktemp /tmp/sudoers.XXXXXX)
  cp /etc/sudoers "\$TMP"

  if ! grep -q "^${CURRENT_USER}" "\$TMP"; then
    echo "${CURRENT_USER}  ALL=(ALL)       ALL"           >> "\$TMP"
    echo "${CURRENT_USER}  ALL=(ALL)       NOPASSWD: ALL" >> "\$TMP"
  fi

  if visudo -c -f "\$TMP"; then
    cp "\$TMP" /etc/sudoers
    echo "sudoers — OK"
  else
    echo "BŁĄD: nieprawidłowa składnia sudoers — plik NIE został zmieniony"
    rm -f "\$TMP"
    exit 1
  fi
  rm -f "\$TMP"
SUDOERS_EOF

# -----------------------------------------------------------------------------
# DNF
# -----------------------------------------------------------------------------
echo "Konfiguracja DNF..."
sudo grep -q "fastestmirror" /etc/dnf/dnf.conf || echo "fastestmirror=True" | sudo tee -a /etc/dnf/dnf.conf >/dev/null
sudo grep -q "max_parallel_downloads" /etc/dnf/dnf.conf || echo "max_parallel_downloads=10" | sudo tee -a /etc/dnf/dnf.conf >/dev/null
sudo grep -q "defaultyes" /etc/dnf/dnf.conf || echo "defaultyes=True" | sudo tee -a /etc/dnf/dnf.conf >/dev/null
sudo grep -q "keepcache" /etc/dnf/dnf.conf || echo "keepcache=True" | sudo tee -a /etc/dnf/dnf.conf >/dev/null

# -----------------------------------------------------------------------------
# Hostname
# -----------------------------------------------------------------------------
echo "Ustawiam hostname..."
sudo hostnamectl set-hostname fedora
sudo grep -q "127.0.1.1" /etc/hosts || echo "127.0.1.1   fedora" | sudo tee -a /etc/hosts >/dev/null

# -----------------------------------------------------------------------------
# Xorg
# -----------------------------------------------------------------------------
echo "Kopiuję konfigurację Xorg..."
sudo mkdir -p /etc/X11/xorg.conf.d

sudo tee /etc/X11/xorg.conf.d/00-keyboard.conf >/dev/null <<'XKBD'
Section "InputClass"
        Identifier "system-keyboard"
        MatchIsKeyboard "on"
        Option "XkbLayout" "pl"
        Option "XkbModel" "pc105"
EndSection
XKBD

sudo tee /etc/X11/xorg.conf.d/20-intel.conf >/dev/null <<'XINTEL'
Section "Device"
    Identifier "Intel Graphics"
    Driver "modesetting"
    Option "TearFree" "true"
EndSection
XINTEL

sudo tee /etc/X11/xorg.conf.d/90-touchpad.conf >/dev/null <<'XTOUCH'
Section "InputClass"
    Identifier "touchpad"
    MatchIsTouchpad "on"
    Driver "libinput"
    Option "Tapping" "on"
    Option "TappingButtonMap" "lrm"
    Option "NaturalScrolling" "on"
    Option "ScrollMethod" "twofinger"
    Option "ClickMethod" "clickfinger"
EndSection
XTOUCH

# -----------------------------------------------------------------------------
# DWM — xsession + start wrapper
# -----------------------------------------------------------------------------
echo "Instaluję dwm.desktop..."
sudo mkdir -p /usr/share/xsessions
sudo tee /usr/share/xsessions/dwm.desktop >/dev/null <<'DWMDESKTOP'
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
sudo tee /usr/local/bin/start-dwm.sh >/dev/null <<'STARTDWM'
#!/bin/sh

[ -f /etc/profile ] && . /etc/profile
[ -f "$HOME/.bash_profile" ] && . "$HOME/.bash_profile"

export XDG_SESSION_TYPE="${XDG_SESSION_TYPE:-x11}"
export XDG_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-DWM}"

# Odblokuj ręczny start i zablokuj auto-stop graphical-session.target
DROPIN_DIR="$HOME/.config/systemd/user/graphical-session.target.d"
DROPIN_FILE="$DROPIN_DIR/override.conf"
if [ ! -f "$DROPIN_FILE" ]; then
    mkdir -p "$DROPIN_DIR"
    cat > "$DROPIN_FILE" <<'EOF'
[Unit]
RefuseManualStart=no
StopWhenUnneeded=no
EOF
    systemctl --user daemon-reload
fi

systemctl --user import-environment DISPLAY XAUTHORITY XDG_SESSION_TYPE XDG_CURRENT_DESKTOP PATH
dbus-update-activation-environment --systemd DISPLAY XAUTHORITY XDG_SESSION_TYPE XDG_CURRENT_DESKTOP PATH
dbus-update-activation-environment --systemd --all

systemctl --user start graphical-session.target
systemctl --user start xdg-desktop-autostart.target

slstatus &
/usr/libexec/xfce-polkit &

(sleep 1 && systemctl --user restart pipewire wireplumber) &

exec /usr/local/bin/dwm

STARTDWM

sudo chmod +x /usr/local/bin/start-dwm.sh

# -----------------------------------------------------------------------------
# GTK theme dla roota (symlinki do użytkownika)
# -----------------------------------------------------------------------------
echo "Konfiguracja GTK theme dla roota..."
sudo mkdir -p /root/.config

sudo ln -sf "/home/${USER}/.fonts" /root/.fonts
sudo ln -sf "/home/${USER}/.icons" /root/.icons
sudo ln -sf "/home/${USER}/.themes" /root/.themes
sudo ln -sf "/home/${USER}/.config/fish" /root/.config/fish
sudo ln -sf "/home/${USER}/.config/gtk-3.0" /root/.config/gtk-3.0
sudo ln -sf "/home/${USER}/.config/gtk-4.0" /root/.config/gtk-4.0
sudo ln -sf "/home/${USER}/.config/nvim" /root/.config/nvim
sudo ln -sf "/home/${USER}/.config/yazi" /root/.config/yazi
sudo ln -sf "/home/${USER}/.bashrc" /root/.bashrc

echo "GTK theme dla roota — OK"

echo "config.sh — zakończony"
