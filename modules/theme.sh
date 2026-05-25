#!/usr/bin/env bash
# =============================================================================
# theme.sh — GTK theme, ikony, czcionki, kursor (uruchamiany jako user)
# =============================================================================
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info() { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }

# -----------------------------------------------------------------------------
# GTK-3
# -----------------------------------------------------------------------------
info "Ustawiam GTK-3 settings..."
mkdir -p "$HOME/.config/gtk-3.0"
cat > "$HOME/.config/gtk-3.0/settings.ini" << 'GTK3'
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
info "GTK-3: $HOME/.config/gtk-3.0/settings.ini — OK"

# -----------------------------------------------------------------------------
# GTK-4
# -----------------------------------------------------------------------------
info "Ustawiam GTK-4 settings..."
mkdir -p "$HOME/.config/gtk-4.0"
cat > "$HOME/.config/gtk-4.0/settings.ini" << 'GTK4'
[Settings]
gtk-theme-name=catppuccin-mocha-blue-standard+default
gtk-icon-theme-name=Colloid-Grey-Dracula-Dark
gtk-font-name=Adwaita Sans 11
gtk-cursor-theme-name=Yaru
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
GTK4
info "GTK-4: $HOME/.config/gtk-4.0/settings.ini — OK"

# -----------------------------------------------------------------------------
# gsettings — wymaga działającej sesji dbus (nie działa podczas instalacji)
# -----------------------------------------------------------------------------
if command -v gsettings &>/dev/null; then
  if dbus-launch gsettings set org.gnome.desktop.interface gtk-theme 'catppuccin-mocha-blue-standard+default' 2>/dev/null; then
    dbus-launch gsettings set org.gnome.desktop.interface icon-theme   'Colloid-Grey-Dracula-Dark'
    dbus-launch gsettings set org.gnome.desktop.interface font-name    'Adwaita Sans 11'
    dbus-launch gsettings set org.gnome.desktop.interface cursor-theme 'Yaru'
    dbus-launch gsettings set org.gnome.desktop.interface cursor-size  24
    dbus-launch gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    info "gsettings — OK"
  else
    warn "gsettings niedostępne (brak sesji dbus) — ustawienia w settings.ini wystarczą dla DWM"
  fi
else
  warn "gsettings niedostępne — pomijam"
fi

# -----------------------------------------------------------------------------
# Xresources — cursor
# -----------------------------------------------------------------------------
XRESOURCES="$HOME/.Xresources"
if [[ -f "$XRESOURCES" || -L "$XRESOURCES" ]]; then
  if ! grep -q "Xcursor.size" "$XRESOURCES"; then
    echo 'Xcursor.size: 24'    >> "$XRESOURCES"
    echo 'Xcursor.theme: Yaru' >> "$XRESOURCES"
    info "Xresources — dodano cursor — OK"
  else
    info "Xresources — cursor już skonfigurowany — pomijam"
  fi
else
  warn "Brak $XRESOURCES — pomijam (stow jeszcze nie uruchomiony?)"
fi

# -----------------------------------------------------------------------------
# Cache czcionek
# -----------------------------------------------------------------------------
if command -v fc-cache &>/dev/null; then
  info "Odświeżam cache czcionek..."
  fc-cache -fv &>/dev/null
  info "fc-cache — OK"
fi

info "=== theme.sh zakończony ==="
