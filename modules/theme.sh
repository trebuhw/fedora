#!/usr/bin/env bash
# =============================================================================
# theme.sh — GTK theme, ikony, czcionki, kursor
# Uruchamiany jako zwykły użytkownik (nie root) po stow
# =============================================================================
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# -----------------------------------------------------------------------------
# GTK-3 settings.ini
# -----------------------------------------------------------------------------
GTK3_DIR="$HOME/.config/gtk-3.0"
GTK3_FILE="$GTK3_DIR/settings.ini"

info "Ustawiam GTK-3 settings..."
mkdir -p "$GTK3_DIR"

cat > "$GTK3_FILE" << 'GTK3'
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
# GTK-4 settings.ini (ta sama baza, bez legacy opcji)
# -----------------------------------------------------------------------------
GTK4_DIR="$HOME/.config/gtk-4.0"
GTK4_FILE="$GTK4_DIR/settings.ini"

info "Ustawiam GTK-4 settings..."
mkdir -p "$GTK4_DIR"

cat > "$GTK4_FILE" << 'GTK4'
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
# gsettings (GNOME schema — działa też w środowiskach nie-GNOME z dconf)
# -----------------------------------------------------------------------------
if command -v gsettings &>/dev/null; then
    info "Ustawiam gsettings..."

    gsettings set org.gnome.desktop.interface gtk-theme        'catppuccin-mocha-blue-standard+default'
    gsettings set org.gnome.desktop.interface icon-theme       'Colloid-Grey-Dracula-Dark'
    gsettings set org.gnome.desktop.interface font-name        'Adwaita Sans 11'
    gsettings set org.gnome.desktop.interface cursor-theme     'Yaru'
    gsettings set org.gnome.desktop.interface cursor-size      24
    gsettings set org.gnome.desktop.interface color-scheme     'prefer-dark'

    info "gsettings — OK"
else
    warn "gsettings niedostępne — pomijam (ustawienia w settings.ini wystarczą dla DWM)"
fi

# -----------------------------------------------------------------------------
# Xresources — cursor size dla Xorg
# -----------------------------------------------------------------------------
XRESOURCES="$HOME/.Xresources"
if [[ -f "$XRESOURCES" ]]; then
    if ! grep -q "Xcursor.size" "$XRESOURCES"; then
        echo "Xcursor.size: 24"     >> "$XRESOURCES"
        echo "Xcursor.theme: Yaru"  >> "$XRESOURCES"
        info "Xresources — dodano cursor — OK"
    else
        info "Xresources — cursor już skonfigurowany — pomijam"
    fi
else
    warn "Brak $XRESOURCES — pomijam (stow jeszcze nie uruchomiony?)"
fi

# -----------------------------------------------------------------------------
# Odśwież cache czcionek
# -----------------------------------------------------------------------------
if command -v fc-cache &>/dev/null; then
    info "Odświeżam cache czcionek..."
    fc-cache -fv &>/dev/null
    info "fc-cache — OK"
fi

info "=== theme.sh zakończony ==="
