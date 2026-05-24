#!/usr/bin/env bash
# =============================================================================
# theme.sh — GTK theme, ikony, czcionki, kursor
# =============================================================================
set -euo pipefail

ACTUAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# Wszystkie operacje na $USER_HOME uruchamiamy jako ACTUAL_USER
# żeby pliki nie lądowały z właścicielem root:root
RUN_AS_USER="sudo -u ${ACTUAL_USER}"

# -----------------------------------------------------------------------------
# GTK-3 settings.ini
# -----------------------------------------------------------------------------
GTK3_DIR="$USER_HOME/.config/gtk-3.0"
GTK3_FILE="$GTK3_DIR/settings.ini"

info "Ustawiam GTK-3 settings..."
$RUN_AS_USER mkdir -p "$GTK3_DIR"

$RUN_AS_USER tee "$GTK3_FILE" > /dev/null << 'GTK3'
[Settings]
gtk-theme-name=catppuccin-mocha-blue-standard+default
gtk-icon-theme-name=Colloid-Grey-Dracula-Dark
gtk-font-name=Adwaita Sans 11
gtk-cursor-theme-name=Yaru
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_ICONS
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
gtk-application-prefer-dark-theme=1
GTK3

info "GTK-3: $GTK3_FILE — OK"

# -----------------------------------------------------------------------------
# GTK-4 settings.ini
# -----------------------------------------------------------------------------
GTK4_DIR="$USER_HOME/.config/gtk-4.0"
GTK4_FILE="$GTK4_DIR/settings.ini"

info "Ustawiam GTK-4 settings..."
$RUN_AS_USER mkdir -p "$GTK4_DIR"

$RUN_AS_USER tee "$GTK4_FILE" > /dev/null << 'GTK4'
[Settings]
gtk-theme-name=catppuccin-mocha-blue-standard+default
gtk-icon-theme-name=Colloid-Grey-Dracula-Dark
gtk-font-name=Adwaita Sans 11
gtk-cursor-theme-name=Yaru
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
GTK4

info "GTK-4: $GTK4_FILE — OK"

# -----------------------------------------------------------------------------
# gsettings — wymaga działającej sesji użytkownika (dbus)
# W trakcie instalacji (przed pierwszym logowaniem) może nie działać
# -----------------------------------------------------------------------------
if command -v gsettings &>/dev/null; then
  if $RUN_AS_USER dbus-launch gsettings set org.gnome.desktop.interface gtk-theme 'catppuccin-mocha-blue-standard+default' 2>/dev/null; then
    $RUN_AS_USER dbus-launch gsettings set org.gnome.desktop.interface icon-theme   'Colloid-Grey-Dracula-Dark'
    $RUN_AS_USER dbus-launch gsettings set org.gnome.desktop.interface font-name    'Adwaita Sans 11'
    $RUN_AS_USER dbus-launch gsettings set org.gnome.desktop.interface cursor-theme 'Yaru'
    $RUN_AS_USER dbus-launch gsettings set org.gnome.desktop.interface cursor-size  24
    $RUN_AS_USER dbus-launch gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    info "gsettings — OK"
  else
    warn "gsettings niedostępne (brak sesji dbus) — ustawienia w settings.ini wystarczą dla DWM"
  fi
else
  warn "gsettings niedostępne — pomijam"
fi

# -----------------------------------------------------------------------------
# Xresources — cursor size dla Xorg
# -----------------------------------------------------------------------------
XRESOURCES="$USER_HOME/.Xresources"
if [[ -f "$XRESOURCES" || -L "$XRESOURCES" ]]; then
  if ! $RUN_AS_USER grep -q "Xcursor.size" "$XRESOURCES"; then
    $RUN_AS_USER bash -c "echo 'Xcursor.size: 24'    >> '$XRESOURCES'"
    $RUN_AS_USER bash -c "echo 'Xcursor.theme: Yaru' >> '$XRESOURCES'"
    info "Xresources — dodano cursor — OK"
  else
    info "Xresources — cursor już skonfigurowany — pomijam"
  fi
else
  warn "Brak $XRESOURCES — pomijam (stow jeszcze nie uruchomiony?)"
fi

# -----------------------------------------------------------------------------
# Odśwież cache czcionek (jako user)
# -----------------------------------------------------------------------------
if command -v fc-cache &>/dev/null; then
  info "Odświeżam cache czcionek..."
  $RUN_AS_USER fc-cache -fv &>/dev/null
  info "fc-cache — OK"
fi

info "=== theme.sh zakończony ==="
