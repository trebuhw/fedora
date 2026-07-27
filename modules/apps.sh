#!/bin/bash
# Programy użytkowe
sudo dnf install -y \
  arp-scan \
  bat \
  blueman \
  btop \
  chromium \
  codium \
  curl \
  eza \
  fastfetch \
  file-roller \
  fish \
  ghostty \
  gparted \
  gthumb \
  htop \
  i3lock \
  iwd \
  lm_sensors \
  meld \
  ncdu \
  neovim \
  network-manager-applet \
  nwg-look \
  onedrive \
  pamixer \
  pavucontrol \
  scrot \
  speedtest-cli \
  starship \
  stow \
  sxiv \
  Thunar \
  thunar-archive-plugin \
  thunar-volman \
  thunderbird \
  tldr \
  trash-cli \
  tumbler \
  ueberzugpp \
  wget \
  vim-enhanced \
  xfce-polkit \
  yazi \
  zathura \
  zathura-pdf-poppler \
  zoxide

# Programy wymagające dodatkowej logiki instalacyjnej (patrz: apps.d/)
APPS_D_DIR="$(dirname "$(readlink -f "$0")")/apps.d"

if [ -d "$APPS_D_DIR" ]; then
  for script in "$APPS_D_DIR"/*.sh; do
    [ -f "$script" ] || continue
    echo "==> Instaluję: $(basename "$script")"
    if bash "$script"; then
      echo "==> OK: $(basename "$script")"
    else
      echo "!! Błąd podczas instalacji $(basename "$script") — pomijam i kontynuuję." >&2
    fi
  done
fi
