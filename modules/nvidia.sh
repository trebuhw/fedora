#!/usr/bin/env bash
# Sterowniki Nvidia (wymaga rpmfusion)
set -euo pipefail

sudo dnf install -y \
    akmod-nvidia \
    kmod-nvidia
