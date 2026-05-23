#!/usr/bin/env bash
# =============================================================================
# Fedora post-install — główny skrypt
# Uruchom jako root: sudo bash install.sh
# Tryb podglądu:     sudo bash install.sh --dry-run
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Kolory i helpery
# -----------------------------------------------------------------------------
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'
CYAN='\033[0;36m'; GRAY='\033[0;90m'; NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC}  $*" | tee -a "$LOG_FILE"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*" | tee -a "$LOG_FILE"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE"; }
dryrun()  { echo -e "${GRAY}[DRY]${NC}   $*" | tee -a "$LOG_FILE"; }
section() {
    echo -e "\n${CYAN}══════════════════════════════════════${NC}" | tee -a "$LOG_FILE"
    echo -e "${CYAN}  $*${NC}" | tee -a "$LOG_FILE"
    echo -e "${CYAN}══════════════════════════════════════${NC}" | tee -a "$LOG_FILE"
}

# -----------------------------------------------------------------------------
# Tryb dry-run
# -----------------------------------------------------------------------------
DRY_RUN=false
for arg in "$@"; do
    [[ "$arg" == "--dry-run" ]] && DRY_RUN=true
done

# -----------------------------------------------------------------------------
# Sprawdź root
# -----------------------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[ERROR]${NC} Skrypt musi być uruchomiony jako root: sudo bash install.sh"
    exit 1
fi

# -----------------------------------------------------------------------------
# Katalogi i log
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="/var/log/fedora-install"
LOG_FILE="$LOG_DIR/install-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$LOG_DIR"

# -----------------------------------------------------------------------------
# Trap — sprzątanie przy Ctrl+C lub TERM
# -----------------------------------------------------------------------------
trap 'echo ""; error "Przerwano przez użytkownika lub sygnał. Log: $LOG_FILE"; exit 130' INT TERM

# -----------------------------------------------------------------------------
# Banner startowy
# -----------------------------------------------------------------------------
section "Fedora post-install $(date +%Y-%m-%d\ %H:%M:%S)"
if $DRY_RUN; then
    echo -e "${YELLOW}  *** TRYB DRY-RUN — żadne zmiany nie zostaną wprowadzone ***${NC}" | tee -a "$LOG_FILE"
fi
info "Log: $LOG_FILE"
info "SCRIPT_DIR: $SCRIPT_DIR"

# -----------------------------------------------------------------------------
# Moduły do uruchomienia (kolejność ma znaczenie)
# Zakomentuj moduły których nie chcesz uruchamiać
# -----------------------------------------------------------------------------
MODULES=(
    repos
    xorg
    build
    config
    desktop
    apps
    dotfiles
    stow-dotdwm
    theme
    install-suckless
    cargo-apps
    # nvidia
)

# Moduły krytyczne — błąd = stop całej instalacji
CRITICAL=(repos build config)

# -----------------------------------------------------------------------------
# Dry-run: pokaż plan i wyjdź
# -----------------------------------------------------------------------------
if $DRY_RUN; then
    section "Plan instalacji (dry-run)"
    echo "" | tee -a "$LOG_FILE"

    for mod in "${MODULES[@]}"; do
        file="$SCRIPT_DIR/modules/${mod}.sh"

        # Oznacz krytyczne
        is_critical=false
        for c in "${CRITICAL[@]}"; do
            [[ "$mod" == "$c" ]] && is_critical=true && break
        done
        label=$( $is_critical && echo " ${RED}[KRYTYCZNY]${NC}" || echo "" )

        if [[ -f "$file" ]]; then
            dryrun "  ✓ modules/${mod}.sh${label}"
            # Pokaż zawartość z prefiksem DRY
            echo -e "${GRAY}  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${NC}" | tee -a "$LOG_FILE"
            while IFS= read -r line; do
                echo -e "${GRAY}  │ ${line}${NC}" | tee -a "$LOG_FILE"
            done < "$file"
            echo -e "${GRAY}  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${NC}" | tee -a "$LOG_FILE"
        else
            dryrun "  ✗ modules/${mod}.sh — BRAK PLIKU${label}"
        fi
        echo "" | tee -a "$LOG_FILE"
    done

    echo -e "${YELLOW}Dry-run zakończony — żadne zmiany nie zostały wprowadzone.${NC}" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}Aby uruchomić instalację: sudo bash install.sh${NC}" | tee -a "$LOG_FILE"
    exit 0
fi

# -----------------------------------------------------------------------------
# Runner — uruchamia każdy moduł jako osobny proces z obsługą błędów
# -----------------------------------------------------------------------------
FAILED=()
PASSED=()

run_module() {
    local name="$1"
    local file="$SCRIPT_DIR/modules/${name}.sh"

    section "Moduł: $name"

    if [[ ! -f "$file" ]]; then
        error "Plik modułu nie istnieje: $file"
        FAILED+=("$name")
        return 1
    fi

    if bash "$file" 2>&1 | tee -a "$LOG_FILE"; then
        info "✓ $name — OK"
        PASSED+=("$name")
    else
        error "✗ $name — BŁĄD (sprawdź log: $LOG_FILE)"
        FAILED+=("$name")
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Uruchom moduły
# -----------------------------------------------------------------------------
for mod in "${MODULES[@]}"; do
    is_critical=false
    for c in "${CRITICAL[@]}"; do
        [[ "$mod" == "$c" ]] && is_critical=true && break
    done

    if ! run_module "$mod"; then
        if $is_critical; then
            error "Moduł krytyczny '$mod' zakończył się błędem — przerywam instalację."
            break
        else
            warn "Moduł '$mod' zakończył się błędem — kontynuuję (nie krytyczny)."
        fi
    fi
done

# -----------------------------------------------------------------------------
# Podsumowanie
# -----------------------------------------------------------------------------
section "Podsumowanie — $(date +%Y-%m-%d\ %H:%M:%S)"

[[ ${#PASSED[@]} -gt 0 ]] && info "Sukces (${#PASSED[@]}): ${PASSED[*]}"
[[ ${#FAILED[@]} -gt 0 ]] && error "Błędy  (${#FAILED[@]}): ${FAILED[*]}"

echo ""
info "Pełny log: $LOG_FILE"

if [[ ${#FAILED[@]} -gt 0 ]]; then
    exit 1
else
    info "Instalacja zakończona pomyślnie."
fi
