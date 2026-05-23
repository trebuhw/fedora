#!/usr/bin/env bash
# =============================================================================
# nvidia.sh — Sterowniki Nvidia (wymaga rpmfusion — uruchom po repos.sh)
# =============================================================================
set -euo pipefail

# Sprawdź czy rpmfusion jest aktywny
if ! dnf repolist | grep -q "rpmfusion"; then
    echo "BŁĄD: rpmfusion nie jest aktywny. Uruchom najpierw repos.sh"
    exit 1
fi

dnf install -y \
    akmod-nvidia \
    kmod-nvidia

echo "nvidia — OK (restart wymagany)"
