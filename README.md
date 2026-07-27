# Fedora Post-Install

Modularny skrypt post-instalacyjny dla Fedory z środowiskiem DWM (suckless).  
Automatyzuje wszystko od świeżej instalacji Fedora Gnome do gotowego, skonfigurowanego DWM.

---

## Wymagania

- Świeża instalacja **Fedora Workstation (Gnome)**
- Dostęp do internetu
- Konto użytkownika `$USER` z możliwością `sudo`

---

## Szybki start

```bash
# 1. Sklonuj repozytorium
git clone https://github.com/trebuhw/Fedora-Install.git
cd Fedora-Install

# 2. Podejrzyj plan (nic nie zmienia)
bash install.sh --dry-run

# 3. Uruchom instalację (jako zwykły user — skrypt sam poprosi o sudo)
bash install.sh
```

---

## Struktura

```
Fedora-Install/
├── install.sh          # Główny runner
└── modules/
    ├── repos.sh        # Repozytoria i kodeki
    ├── xorg.sh         # Xorg + sterowniki
    ├── build.sh        # Narzędzia kompilacji + Rust
    ├── config.sh       # Konfiguracja systemu
    ├── desktop.sh      # Środowisko DWM
    ├── apps.sh         # Programy użytkowe
    ├── dotfiles.sh     # Dotfiles z GitHub
    ├── stow-dotdwm.sh  # Linkowanie dotfiles przez stow
    ├── theme.sh        # GTK theme, czcionki, kursor
    ├── install-suckless.sh  # Kompilacja suckless
    ├── cargo-apps.sh   # Aplikacje Rust/Cargo
    └── nvidia.sh       # Sterowniki Nvidia (opcjonalny)
```

---

## Moduły — szczegóły

### `repos.sh`
Dodaje repozytoria:
- RPM Fusion free + nonfree + tainted
- Terra (ghostty, nwg-look i inne)
- Flathub (Flatpak)
- Kodeki multimedialne (GStreamer, lame)

### `xorg.sh`
Instaluje Xorg, sterowniki Intel oraz narzędzia:
`xrandr`, `xsetroot`, `xset`, `xclip`

### `build.sh`
Instaluje narzędzia do kompilacji suckless:
- `development-tools`, `gcc`, `make`
- biblioteki: `libX11-devel`, `libXft-devel`, `libXinerama-devel`, `fontconfig-devel`, `dbus-devel`
- **Rust + Cargo** (oficjalny instalator rustup, aktualizuje jeśli już zainstalowany)

### `config.sh`
Konfiguruje system:
- **sudoers** — odkomentowuje `%wheel`, dodaje użytkownika `hubert` z `NOPASSWD` (walidacja przez `visudo -c`)
- **DNF** — `fastestmirror`, `max_parallel_downloads=10`, `defaultyes`, `keepcache`
- **hostname** — ustawia `fedora`
- **Xorg** — konfiguracja klawiatury (PL), Intel TearFree, touchpad (tap, natural scroll)
- **DWM session** — `dwm.desktop` → `/usr/share/xsessions/`, `start-dwm.sh` → `/usr/local/bin/`

### `desktop.sh`
Instaluje komponenty środowiska DWM:
`rofi`, `dunst`, `picom`, `feh`, `numlockx`, `brightnessctl`

### `apps.sh`
Instaluje programy użytkowe:
`bat`, `btop`, `chromium`, `codium`, `eza`, `fastfetch`, `fish`, `flameshot`,
`ghostty`, `gparted`, `htop`, `i3lock`, `neovim`, `pamixer`, `papirus-icon-theme`,
`pavucontrol`, `starship`, `stow`, `Thunar`, `thunderbird`, `trash-cli`,
`ueberzugpp`, `yazi`, `zathura` i inne.

Na końcu uruchamia dodatkowo każdy skrypt z `apps.d/` (programy wymagające
własnej logiki instalacyjnej, np. `github-desktop.sh` instalujący GitHub Desktop
z pliku `.rpm`). Błąd w jednym skrypcie z `apps.d/` nie przerywa instalacji
pozostałych — jest tylko odnotowany w logu.

### `dotfiles.sh`
Klonuje repozytorium dotfiles z GitHub:
```
https://github.com/trebuhw/.dotdwm.git → ~/.dotdwm
```
Jeśli repo już istnieje — wykonuje `git pull --rebase`.

### `stow-dotdwm.sh`
Linkuje dotfiles przez GNU stow:
1. **Backup** — istniejące pliki przenosi do `.bak` (z timestampem jeśli `.bak` już istnieje)
2. **Stow** — linkuje wszystkie pakiety z `~/.dotdwm` do `~`
3. Pomija katalogi `etc/` i `usr/` (tylko kopia referencyjna, nie do stow)

### `theme.sh`
Ustawia wygląd systemu po stow:
- **GTK-3** `~/.config/gtk-3.0/settings.ini`
- **GTK-4** `~/.config/gtk-4.0/settings.ini`
- **gsettings** — theme, ikony, czcionka, kursor (jeśli dostępne)
- **Xresources** — cursor theme + size
- **fc-cache** — odświeża cache czcionek

| Ustawienie | Wartość |
|---|---|
| GTK Theme | `catppuccin-mocha-blue-standard+default` |
| Icon Theme | `Colloid-Grey-Dracula-Dark` |
| Font | `Adwaita Sans 11` |
| Cursor | `Yaru` / `24px` |
| Color scheme | `prefer-dark` |

### `install-suckless.sh`
Kompiluje i instaluje narzędzia suckless z `~/.config/suckless/`:
- **dwm** — window manager
- **st** — terminal
- **slstatus** — pasek statusu
- **dmenu** — launcher

Dla każdego narzędzia: usuwa `config.h` → `make` → `sudo make clean install`

### `cargo-apps.sh`
Instaluje aplikacje przez Cargo:
- `bluetui` — TUI dla Bluetooth
- `cargo-update` — aktualizacja pakietów cargo
- `wlctl` — kontrola Wayland (opcjonalnie)

### `nvidia.sh` *(opcjonalny)*
Instaluje sterowniki Nvidia (`akmod-nvidia`, `kmod-nvidia`).  
Domyślnie **wyłączony** — odkomentuj w `install.sh` jeśli potrzebny.

---

## Opcje uruchomienia

### Dry-run — podgląd bez zmian
```bash
sudo bash install.sh --dry-run
```
Wyświetla pełny plan instalacji — listę modułów w kolejności wraz z zawartością każdego skryptu. Nic nie wykonuje.

### Wybiórcze moduły

**Opcja 1 — na trwałe**, zakomentuj niepotrzebne moduły w `install.sh`:
```bash
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
    # nvidia       ← odkomentuj dla Nvidia
)
```

**Opcja 2 — ad-hoc, z linii komend**, bez edytowania pliku:
```bash
# uruchom tylko jeden moduł
bash install.sh apps

# uruchom kilka modułów, w podanej kolejności
bash install.sh apps theme cargo-apps

# podgląd (dry-run) wybranego modułu
bash install.sh --dry-run virt-manager

# lista dostępnych modułów
bash install.sh --list
```
Przydatne np. gdy tylko dodałeś nowy program do `apps.sh` i chcesz doinstalować go bez przechodzenia przez cały setup od nowa.

**Opcja 3 — samodzielne uruchomienie pliku modułu** (bez `install.sh`):
```bash
bash modules/apps.sh
```
Działa dla modułów bez zależności od innych kroków (np. `apps.sh`, `repos.sh`, `nvidia.sh`). Moduły zależne od wcześniejszych etapów (np. `install-suckless.sh` wymaga `stow-dotdwm.sh`, `cargo-apps.sh` wymaga `build.sh`) będą zgłaszać błąd z jasnym komunikatem, jeśli wymagany wcześniejszy krok nie został wykonany.

---

## Logowanie

Każde uruchomienie zapisuje pełny log:
```
~/.local/log/fedora-install/install-YYYYMMDD-HHMMSS.log
```

Przy błędzie:
```bash
cat ~/.local/log/fedora-install/install-*.log | tail -50
```

---

## Moduły krytyczne vs niekrytyczne

| Moduł | Typ | Opis |
|---|---|---|
| `repos` | **krytyczny** | Bez repozytoriów nic się nie zainstaluje |
| `build` | **krytyczny** | Bez gcc/make suckless się nie skompiluje |
| `config` | **krytyczny** | Podstawowa konfiguracja systemu |
| pozostałe | niekrytyczny | Błąd = ostrzeżenie, instalacja kontynuuje |

---

## Dotfiles

Repozytorium dotfiles: [trebuhw/.dotdwm](https://github.com/trebuhw/.dotdwm)

Struktura zgodna z GNU stow — każdy katalog to pakiet:
```
~/.dotdwm/
├── bash/       → ~/.bashrc, ~/.bash_profile
├── fish/       → ~/.config/fish/
├── nvim/       → ~/.config/nvim/
├── dwm/        → ~/.config/suckless/   (przez stow)
└── ...
```

---

## Po instalacji

1. Uruchom ponownie system
2. Na ekranie logowania wybierz sesję **dwm**
3. Zaloguj się — `slstatus` uruchomi się automatycznie z DWM

---

### **GRUB:**

Detection of other systems and update of grub

*Run os-prober to update-grub*

- edit `sudo nvim /etc/default/grub`

- find os-prober 

- delate # `GRUB_DISABLE_OS_PROBER=false`

- run `update-grub`

or

- `sudo grub-mkconfig -o /boot/grub/grub.cfg` 

---

### **Keybindings:**

- `super=win` `ModKey4` - default
- `super + shift + ?` = show `Keybindings`
- `super + enter` = terminal `ghostty`
- `super + shift + return` = web browser `chromium`
- `super + space` = launcher `rofi`
- `super + shift + space` = launcher `dmenu`
- `super + escape` = launcher `rofi - powermenu`
- `alt + escape` = launcher `dmenu - powermenu`
- `super + q` = kill window `pkill`
- `super + shift + q` = reload `dwm`

### **Installed theme:**

`nwg-look` - `set your choise`

- `GTK` - `Adwaita, Catppucin-Mocha`
- `Cursors` - `Adwaita, Yaru`
- `Icons` - `Adwaita, Colloid-Grey-Dracula`
- `Fonts` - `Adwaita Sans, JetBrains Mono Nerd Font`

## Autor

**Hubert** — [github.com/trebuhw](https://github.com/trebuhw)
