#!/usr/bin/env bash
set -euo pipefail

# RPMFusion
sudo dnf install -y \
  "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
  "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

sudo dnf install -y \
  rpmfusion-free-release-tainted \
  rpmfusion-nonfree-release-tainted

sudo dnf install -y \
  gstreamer1-plugins-bad-free \
  gstreamer1-plugins-bad-free-extras \
  gstreamer1-plugins-bad-free-fluidsynth \
  gstreamer1-plugins-bad-free-libs \
  gstreamer1-plugins-bad-free-lv2 \
  gstreamer1-plugins-bad-free-opencv \
  gstreamer1-plugins-bad-free-wildmidi \
  gstreamer1-plugins-bad-free-zbar \
  gstreamer1-plugins-bad-freeworld \
  gstreamer1-plugins-good-extras \
  gstreamer1-plugins-good-gtk \
  gstreamer1-plugins-good-qt \
  gstreamer1-plugins-good-qt6 \
  gstreamer1-plugins-base \
  gstreamer1-plugin-openh264 \
  gstreamer1-plugin-libav \
  lame \
  lame-devel \
  lame-libs

# Terra — --repofrompath pozwala zainstalować terra-release bez wcześniej
# skonfigurowanego repo (działa na świeżej instalacji)
if rpm -q terra-release &>/dev/null; then
  echo "terra-release już zainstalowany — pomijam"
else
  sudo dnf install -y --nogpgcheck \
    --repofrompath "terra,https://repos.fyralabs.com/terra$(rpm -E %fedora)" \
    terra-release
fi
