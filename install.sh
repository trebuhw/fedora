#!/usr/bin/env bash
# =============================================================================
# Fedora post-install — główny skrypt
# Uruchom jako zwykły user: bash install.sh
# Tryb podglądu:             bash install.sh --dry-run
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Kolory i helpery
# -----------------------------------------------------------------------------
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

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
# NIE uruchamiaj jako root
# -----------------------------------------------------------------------------
if [[ $EUID -eq 0 ]]; then
  echo -e "${RED}[ERROR]${NC} Nie uruchamiaj jako root. Uruchom: bash install.sh"
  echo -e "${RED}[ERROR]${NC} Skrypt sam poprosi o hasło sudo gdy będzie potrzebne."
  exit 1
fi

# -----------------------------------------------------------------------------
# Tryb dry-run
# -----------------------------------------------------------------------------
DRY_RUN=false
for arg in "$@"; do
  [[ "$arg" == "--dry-run" ]] && DRY_RUN=true
done

# -----------------------------------------------------------------------------
# Katalogi i log
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$HOME/.local/log/fedora-install"
LOG_FILE="$LOG_DIR/install-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$LOG_DIR"

# Eksportuj zmienne potrzebne modułom
export ACTUAL_USER="$USER"
export USER_HOME="$HOME"
export SCRIPT_DIR
export LOG_FILE
export DRY_RUN

# -----------------------------------------------------------------------------
# Jednorazowe sudo — poproś o hasło raz na początku, odświeżaj w tle
# Wszystkie moduły które potrzebują roota wywołują: sudo <komenda>
# -----------------------------------------------------------------------------
if ! $DRY_RUN; then
  echo -e "${CYAN}Instalacja wymaga uprawnień administratora dla niektórych kroków.${NC}"
  echo -e "${CYAN}Podaj hasło sudo raz — będzie ważne przez całą instalację.${NC}"
  echo ""

  # Sprawdź czy sudo w ogóle działa
  if ! sudo -v; then
    echo -e "${RED}[ERROR]${NC} Nie można uzyskać uprawnień sudo. Sprawdź czy użytkownik jest w grupie wheel."
    exit 1
  fi

  # Odświeżaj token sudo co 50 sekund w tle (domyślny timeout to 5 min)
  # żeby hasło nie wygasło w trakcie długiej instalacji
  (
    while true; do
      sleep 50
      sudo -n true 2>/dev/null || exit
    done
  ) &
  SUDO_REFRESH_PID=$!

  # Zatrzymaj odświeżanie przy wyjściu
  trap '
    kill "$SUDO_REFRESH_PID" 2>/dev/null || true
    echo ""
    error "Przerwano przez użytkownika lub sygnał. Log: $LOG_FILE"
    exit 130
  ' INT TERM
else
  trap '
    echo ""
    error "Przerwano. Log: $LOG_FILE"
    exit 130
  ' INT TERM
fi

# -----------------------------------------------------------------------------
# Banner startowy
# -----------------------------------------------------------------------------
section "Fedora post-install $(date +%Y-%m-%d\ %H:%M:%S)"
if $DRY_RUN; then
  echo -e "${YELLOW}  *** TRYB DRY-RUN — żadne zmiany nie zostaną wprowadzone ***${NC}" | tee -a "$LOG_FILE"
fi
info "Log: $LOG_FILE"
info "Użytkownik: $ACTUAL_USER"
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

    is_critical=false
    for c in "${CRITICAL[@]}"; do
      [[ "$mod" == "$c" ]] && is_critical=true && break
    done
    label=$($is_critical && echo " ${RED}[KRYTYCZNY]${NC}" || echo "")

    if [[ -f "$file" ]]; then
      dryrun "  ✓ modules/${mod}.sh${label}"
      echo -e "${GRAY}  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${NC}" | tee -a "$LOG_FILE"
      while IFS= read -r line; do
        echo -e "${GRAY}  │ ${line}${NC}" | tee -a "$LOG_FILE"
      done <"$file"
      echo -e "${GRAY}  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${NC}" | tee -a "$LOG_FILE"
    else
      dryrun "  ✗ modules/${mod}.sh — BRAK PLIKU${label}"
    fi
    echo "" | tee -a "$LOG_FILE"
  done

  echo -e "${YELLOW}Dry-run zakończony — żadne zmiany nie zostały wprowadzone.${NC}" | tee -a "$LOG_FILE"
  echo -e "${YELLOW}Aby uruchomić instalację: bash install.sh${NC}" | tee -a "$LOG_FILE"
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

# Zatrzymaj odświeżanie sudo
kill "$SUDO_REFRESH_PID" 2>/dev/null || true

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
