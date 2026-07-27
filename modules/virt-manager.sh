#!/usr/bin/env bash
# =============================================================================
# Moduł: virt-manager
# Instalacja i konfiguracja KVM/QEMU/virt-manager na Fedorze 44
# Można uruchomić przez install.sh ALBO samodzielnie: bash modules/virt-manager.sh
# =============================================================================
set -euo pipefail

# Jeśli moduł jest uruchamiany samodzielnie (bez install.sh), funkcje info/warn/error
# i zmienna ACTUAL_USER nie istnieją — definiujemy fallback.
if ! declare -f info >/dev/null 2>&1; then
  GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
  info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
  warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
  error() { echo -e "${RED}[ERROR]${NC} $*"; }
fi
: "${ACTUAL_USER:=$USER}"

# --- Krok 1: Sprawdzenie wsparcia CPU ---
info "virt-manager: sprawdzanie wsparcia CPU..."

CPU_FLAGS=$(grep -Ec '(vmx|svm)' /proc/cpuinfo || true)
if [[ "$CPU_FLAGS" -eq 0 ]]; then
  error "CPU nie obsługuje wirtualizacji (vmx/svm). Włącz VT-x lub AMD-V w BIOS."
  exit 1
fi
info "virt-manager: CPU OK ($CPU_FLAGS wątków z flagą vmx/svm)."

# --- Krok 2: Instalacja pakietów ---
info "virt-manager: instalacja grupy @virtualization..."
sudo dnf install -y @virtualization
sudo dnf install -y virt-manager

# --- Krok 3: Aktywacja modułowych socketów libvirt ---
info "virt-manager: aktywacja socketów libvirt..."

SOCKETS=(
  virtqemud.socket
  virtnetworkd.socket
  virtstoraged.socket
  virtnodedevd.socket
  virtsecretd.socket
  virtnwfilterd.socket
  virtinterfaced.socket
)

for SOCK in "${SOCKETS[@]}"; do
  sudo systemctl enable --now "$SOCK"
done

# Weryfikacja kluczowych socketów
for SOCK in virtqemud.socket virtnetworkd.socket virtstoraged.socket; do
  STATUS=$(systemctl is-active "$SOCK" 2>/dev/null || true)
  if [[ "$STATUS" != "active" ]]; then
    error "virt-manager: $SOCK nie jest aktywny (status: $STATUS)."
    exit 1
  fi
done
info "virt-manager: sockety aktywne."

# --- Krok 4: Walidacja hosta ---
info "virt-manager: walidacja hosta..."
sudo virt-host-validate qemu || warn "virt-manager: virt-host-validate zwrócił ostrzeżenia — sprawdź log."

# --- Krok 5: Dodanie użytkownika do grupy libvirt ---
info "virt-manager: dodawanie '$ACTUAL_USER' do grupy libvirt..."

if id -nG "$ACTUAL_USER" | grep -qw libvirt; then
  info "virt-manager: '$ACTUAL_USER' już jest w grupie libvirt."
else
  sudo usermod -aG libvirt "$ACTUAL_USER"
  warn "virt-manager: '$ACTUAL_USER' dodany do grupy libvirt — wyloguj się i zaloguj ponownie."
fi

# --- Krok 6: Sieć NAT ---
info "virt-manager: konfiguracja sieci NAT..."

NET_STATUS=$(sudo virsh net-list --all | awk '/default/ {print $2}')
if [[ "$NET_STATUS" != "aktywne" && "$NET_STATUS" != "active" ]]; then
  sudo virsh net-start default
fi
sudo virsh net-autostart default
info "virt-manager: sieć default aktywna z autostarter."
