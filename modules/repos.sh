#!/usr/bin/env bash
# =============================================================================
# repos.sh — Dodatkowe repozytoria i kodeki
# =============================================================================
set -euo pipefail

# RPM Fusion free + nonfree
dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

# RPM Fusion tainted (libdvdcss i firmware)
dnf install -y \
    rpmfusion-free-release-tainted \
    rpmfusion-nonfree-release-tainted

# Kodeki multimedialne
dnf install -y \
    gstreamer1-plugins-{bad-\*,good-\*,base} \
    gstreamer1-plugin-openh264 \
    gstreamer1-libav \
    lame\* \
    --exclude=gstreamer1-plugins-bad-free-devel

dnf group upgrade -y --with-optional Multimedia

# Terra
# shellcheck disable=SC2016
dnf install -y --nogpgcheck \
    --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' \
    terra-release

# Flathub
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# COPR: onedrive (odkomentuj jeśli potrzebne)
# dnf copr enable -y jstaf/onedriver
