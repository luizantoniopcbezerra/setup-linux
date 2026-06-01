#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status()  { echo -e "${BLUE}[...] $1${NC}"; }
print_success() { echo -e "${GREEN}[OK]  $1${NC}"; }
print_warning() { echo -e "${YELLOW}[!!]  $1${NC}"; }
print_error()   { echo -e "${RED}[ERR] $1${NC}"; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =========================================================
# VERIFICAÇÃO — ARCH LINUX
# =========================================================

if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$ID" != "arch" ]; then
        print_error "Este script é exclusivo para Arch Linux. Distro detectada: $ID"
        exit 1
    fi
else
    print_error "Não foi possível detectar a distribuição Linux."
    exit 1
fi

echo ""
echo "  Iniciando configuração do ambiente de desenvolvimento..."
echo "  Arch Linux detectado."
echo ""

# =========================================================
# 1 — ATUALIZAÇÃO DO SISTEMA
# =========================================================

print_status "Atualizando sistema..."
sudo pacman -Syu --noconfirm
print_success "Sistema atualizado"

# =========================================================
# 2 — PACOTES BASE
# =========================================================

print_status "Instalando pacotes base..."

sudo pacman -S --noconfirm --needed \
    curl wget git nano unzip openssh ca-certificates imagemagick \
    base-devel make gcc

print_success "Pacotes base instalados"

# =========================================================
# 3 — XORG
# =========================================================

print_status "Instalando Xorg..."

sudo pacman -S --noconfirm --needed \
    xorg-server xorg-xinit xorg-xrandr xorg-setxkbmap xorg-xrdb \
    xorg-xset xorg-xsetroot xf86-video-vesa

print_success "Xorg instalado"

# =========================================================
# 4 — WINDOW MANAGER (i3)
# =========================================================

print_status "Instalando i3 e utilitários..."

sudo pacman -S --noconfirm --needed \
    i3-wm i3status dmenu picom feh \
    xss-lock i3lock dex

print_success "i3 instalado"

# =========================================================
# 5 — TERMINAL (Alacritty)
# =========================================================

print_status "Instalando Alacritty..."

sudo pacman -S --noconfirm --needed alacritty

print_success "Alacritty instalado"

# =========================================================
# 6 — REDE
# =========================================================

print_status "Instalando NetworkManager..."

sudo pacman -S --noconfirm --needed networkmanager network-manager-applet

sudo systemctl enable --now NetworkManager

print_success "NetworkManager instalado e habilitado"

# =========================================================
# 7 — ÁUDIO (PipeWire)
# =========================================================

print_status "Instalando PipeWire..."

sudo pacman -S --noconfirm --needed \
    pipewire pipewire-pulse wireplumber

print_success "PipeWire instalado"

# =========================================================
# 8 — FONTES
# =========================================================

print_status "Instalando fontes..."

sudo pacman -S --noconfirm --needed ttf-dejavu

print_success "Fontes instaladas"

# =========================================================
# 9 — NAVEGADOR
# =========================================================

print_status "Instalando Firefox..."

sudo pacman -S --noconfirm --needed firefox

print_success "Firefox instalado"

# =========================================================
# 10 — NODE.JS E NPM
# =========================================================

print_status "Instalando Node.js e npm..."

sudo pacman -S --noconfirm --needed nodejs npm

print_success "Node.js $(node --version) instalado"

# =========================================================
# 11 — JAVA 21
# =========================================================

print_status "Instalando Java 21..."

sudo pacman -S --noconfirm --needed jdk21-openjdk

print_success "Java 21 instalado"

# =========================================================
# 12 — MAVEN
# =========================================================

print_status "Instalando Maven..."

sudo pacman -S --noconfirm --needed maven

print_success "Maven instalado"

# =========================================================
# 13 — NEOVIM
# =========================================================

print_status "Instalando Neovim..."

sudo pacman -S --noconfirm --needed neovim

print_success "Neovim instalado"

# =========================================================
# 14 — DOCKER
# =========================================================

print_status "Instalando Docker..."

if ! command_exists docker; then
    sudo pacman -S --noconfirm --needed docker docker-buildx docker-compose
    sudo systemctl enable --now docker
    sudo usermod -aG docker "$USER"
    print_success "Docker instalado"
    print_warning "Faça logout/login para usar Docker sem sudo"
else
    print_success "Docker já instalado"
fi

# =========================================================
# 15 — FLATPAK
# =========================================================

print_status "Configurando Flatpak..."

sudo pacman -S --noconfirm --needed flatpak

if ! flatpak remote-list | grep -q flathub; then
    sudo flatpak remote-add --if-not-exists flathub \
        https://flathub.org/repo/flathub.flatpakrepo
fi

print_success "Flatpak configurado"

# Obsidian
print_status "Instalando Obsidian..."
if ! flatpak list | grep -q md.obsidian.Obsidian; then
    flatpak install -y flathub md.obsidian.Obsidian
    print_success "Obsidian instalado"
else
    print_success "Obsidian já instalado"
fi

# IntelliJ IDEA Community
print_status "Instalando IntelliJ IDEA Community..."
if ! flatpak list | grep -q com.jetbrains.IntelliJ-IDEA-Community; then
    flatpak install -y flathub com.jetbrains.IntelliJ-IDEA-Community
    print_success "IntelliJ IDEA Community instalado"
else
    print_success "IntelliJ IDEA Community já instalado"
fi

# =========================================================
# 16 — GIT
# =========================================================

print_status "Configurando Git..."

read -rp "Nome Git: " git_username
read -rp "Email Git: " git_email

if [ -n "$git_username" ] && [ -n "$git_email" ]; then
    git config --global user.name "$git_username"
    git config --global user.email "$git_email"
    print_success "Git configurado"
else
    print_warning "Git não configurado"
fi

# =========================================================
# 17 — WALLPAPER
# =========================================================

print_status "Configurando wallpaper..."

mkdir -p "$HOME/wallpaper"
cp "$SCRIPT_DIR/wallpaper_desktop.png" "$HOME/wallpaper/arch.png"

print_success "Wallpaper copiado para ~/wallpaper/arch.png"

# =========================================================
# 18 — DOTFILES E CONFIGURAÇÕES
# =========================================================

print_status "Aplicando configurações..."

# ~/.xinitrc
cat > "$HOME/.xinitrc" << 'EOF'
export MOZ_USE_XINPUT2=1

exec i3
EOF

# ~/.config/i3/config
mkdir -p "$HOME/.config/i3"
# Heredoc sem aspas para que $HOME expanda; variáveis do i3 são escapadas com \$
cat > "$HOME/.config/i3/config" << EOF
set \$mod Mod4

font pango:monospace 8

exec --no-startup-id dex --autostart --environment i3
exec --no-startup-id picom -b
exec --no-startup-id feh --bg-fill $HOME/wallpaper/arch.png
exec --no-startup-id xss-lock --transfer-sleep-lock -- i3lock --nofork
exec --no-startup-id nm-applet

set \$refresh_i3status killall -SIGUSR1 i3status
bindsym XF86AudioRaiseVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +10% && \$refresh_i3status
bindsym XF86AudioLowerVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -10% && \$refresh_i3status
bindsym XF86AudioMute        exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle && \$refresh_i3status
bindsym XF86AudioMicMute     exec --no-startup-id pactl set-source-mute @DEFAULT_SOURCE@ toggle && \$refresh_i3status

floating_modifier \$mod
tiling_drag modifier titlebar

bindsym \$mod+Return exec i3-sensible-terminal
bindsym \$mod+Shift+q kill
bindsym \$mod+d exec --no-startup-id dmenu_run

bindsym \$mod+j focus left
bindsym \$mod+k focus down
bindsym \$mod+l focus up
bindsym \$mod+semicolon focus right
bindsym \$mod+Left  focus left
bindsym \$mod+Down  focus down
bindsym \$mod+Up    focus up
bindsym \$mod+Right focus right

bindsym \$mod+Shift+j         move left
bindsym \$mod+Shift+k         move down
bindsym \$mod+Shift+l         move up
bindsym \$mod+Shift+semicolon move right
bindsym \$mod+Shift+Left      move left
bindsym \$mod+Shift+Down      move down
bindsym \$mod+Shift+Up        move up
bindsym \$mod+Shift+Right     move right

bindsym \$mod+h split h
bindsym \$mod+v split v
bindsym \$mod+f fullscreen toggle

bindsym \$mod+s layout stacking
bindsym \$mod+w layout tabbed
bindsym \$mod+e layout toggle split

bindsym \$mod+Shift+space floating toggle
bindsym \$mod+space focus mode_toggle
bindsym \$mod+a focus parent

set \$ws1  "1"
set \$ws2  "2"
set \$ws3  "3"
set \$ws4  "4"
set \$ws5  "5"
set \$ws6  "6"
set \$ws7  "7"
set \$ws8  "8"
set \$ws9  "9"
set \$ws10 "10"

bindsym \$mod+1 workspace number \$ws1
bindsym \$mod+2 workspace number \$ws2
bindsym \$mod+3 workspace number \$ws3
bindsym \$mod+4 workspace number \$ws4
bindsym \$mod+5 workspace number \$ws5
bindsym \$mod+6 workspace number \$ws6
bindsym \$mod+7 workspace number \$ws7
bindsym \$mod+8 workspace number \$ws8
bindsym \$mod+9 workspace number \$ws9
bindsym \$mod+0 workspace number \$ws10

bindsym \$mod+Shift+1 move container to workspace number \$ws1
bindsym \$mod+Shift+2 move container to workspace number \$ws2
bindsym \$mod+Shift+3 move container to workspace number \$ws3
bindsym \$mod+Shift+4 move container to workspace number \$ws4
bindsym \$mod+Shift+5 move container to workspace number \$ws5
bindsym \$mod+Shift+6 move container to workspace number \$ws6
bindsym \$mod+Shift+7 move container to workspace number \$ws7
bindsym \$mod+Shift+8 move container to workspace number \$ws8
bindsym \$mod+Shift+9 move container to workspace number \$ws9
bindsym \$mod+Shift+0 move container to workspace number \$ws10

bindsym \$mod+Shift+c reload
bindsym \$mod+Shift+r restart
bindsym \$mod+Shift+e exec "i3-nagbar -t warning -m 'Sair do i3?' -B 'Sim' 'i3-msg exit'"

mode "resize" {
    bindsym j         resize shrink width  10 px or 10 ppt
    bindsym k         resize grow   height 10 px or 10 ppt
    bindsym l         resize shrink height 10 px or 10 ppt
    bindsym semicolon resize grow   width  10 px or 10 ppt
    bindsym Left      resize shrink width  10 px or 10 ppt
    bindsym Down      resize grow   height 10 px or 10 ppt
    bindsym Up        resize shrink height 10 px or 10 ppt
    bindsym Right     resize grow   width  10 px or 10 ppt
    bindsym Return mode "default"
    bindsym Escape mode "default"
    bindsym \$mod+r mode "default"
}
bindsym \$mod+r mode "resize"

exec_always --no-startup-id setxkbmap br abnt2

client.focused          #ffffff #ffffff #000000 #ffffff #ffffff
client.unfocused        #333333 #333333 #888888 #333333 #333333
client.focused_inactive #333333 #333333 #888888 #333333 #333333

bar {
    position top
    status_command i3status
    colors {
        background          #000000
        statusline          #ffffff
        separator           #555555
        focused_workspace   #ffffff #ffffff #000000
        active_workspace    #333333 #333333 #ffffff
        inactive_workspace  #000000 #000000 #888888
        urgent_workspace    #ffffff #ffffff #000000
    }
}
EOF

# ~/.config/i3status/config
# Detecta interfaces de rede do sistema atual
WIFI_IFACE=$(iw dev 2>/dev/null | awk '$1=="Interface"{print $2}' | head -1)
ETH_IFACE=$(ip -o link show 2>/dev/null | awk -F': ' '$2 ~ /^en/{print $2}' | head -1)
WIFI_IFACE=${WIFI_IFACE:-wlp4s0}
ETH_IFACE=${ETH_IFACE:-enp3s0}

print_status "Interfaces detectadas: wifi=$WIFI_IFACE ethernet=$ETH_IFACE"

mkdir -p "$HOME/.config/i3status"
cat > "$HOME/.config/i3status/config" << EOF
general {
    colors = true
    interval = 5
    color_good     = "#aaffaa"
    color_degraded = "#ffdd00"
    color_bad      = "#ff6666"
}

order += "wireless $WIFI_IFACE"
order += "ethernet $ETH_IFACE"
order += "volume master"
order += "battery all"
order += "disk /"
order += "cpu_usage"
order += "memory"
order += "tztime local"

wireless $WIFI_IFACE {
    format_up   = "  %essid %ip"
    format_down = "  desconectado"
}

ethernet $ETH_IFACE {
    format_up   = "  %ip"
    format_down = ""
}

volume master {
    format        = "  %volume"
    format_muted  = "  mudo"
    device        = "pulse"
    mixer         = "Master"
    mixer_idx     = 0
}

battery all {
    format                    = "%status %percentage %remaining"
    format_down               = "sem bateria"
    status_chr                = " "
    status_bat                = " "
    status_unk                = "? "
    status_full               = " "
    low_threshold             = 15
    threshold_type            = percentage
    integer_battery_capacity  = true
    last_full_capacity        = true
}

disk "/" {
    format          = "  %avail livre"
    low_threshold   = 10
    threshold_type  = gbytes_avail
}

cpu_usage {
    format             = "  %usage"
    degraded_threshold = 60
    max_threshold      = 90
}

memory {
    format          = "  %used / %total"
    threshold_degraded = "2G"
    format_degraded = "  MEM BAIXA %available"
}

tztime local {
    format = "  %d/%m/%Y   %H:%M"
}
EOF

# ~/.config/alacritty/alacritty.toml
mkdir -p "$HOME/.config/alacritty"
cat > "$HOME/.config/alacritty/alacritty.toml" << 'EOF'
[window]
opacity = 0.85

[colors.primary]
background = "#000000"
foreground = "#ffffff"

[colors.normal]
black   = "#000000"
red     = "#ffffff"
green   = "#ffffff"
yellow  = "#ffffff"
blue    = "#ffffff"
magenta = "#ffffff"
cyan    = "#ffffff"
white   = "#ffffff"

[colors.bright]
black   = "#555555"
red     = "#ffffff"
green   = "#ffffff"
yellow  = "#ffffff"
blue    = "#ffffff"
magenta = "#ffffff"
cyan    = "#ffffff"
white   = "#ffffff"

[[keyboard.bindings]]
key   = "Return"
mods  = "Shift"
chars = "\u001B\r"
EOF

print_success "Configurações aplicadas"

# =========================================================
# 19 — CONFIGURAÇÃO DO NEOVIM
# =========================================================

print_status "Configurando Neovim..."

NVIM_CONFIG="$HOME/.config/nvim"

if [ -d "$NVIM_CONFIG" ] && [ "$(ls -A "$NVIM_CONFIG")" ]; then
    print_warning "~/.config/nvim já existe, pulando clone"
else
    rm -rf "$NVIM_CONFIG"
    git clone https://github.com/bezerraluiz/setup-neovim.git "$NVIM_CONFIG"
    print_success "Neovim configurado via https://github.com/bezerraluiz/setup-neovim"
fi

# =========================================================
# 20 — TOUCHPAD
# =========================================================

print_status "Configurando touchpad..."

sudo tee /etc/X11/xorg.conf.d/30-touchpad.conf > /dev/null << 'EOF'
Section "InputClass"
    Identifier "touchpad"
    Driver "libinput"
    MatchIsTouchpad "on"
    Option "Tapping" "on"
    Option "NaturalScrolling" "true"
    Option "GesturesEnabled" "on"
EndSection
EOF


print_success "Touchpad configurado (tap + scroll natural + pinch-to-zoom)"

# =========================================================
# 21 — FIREFOX DARK THEME
# =========================================================

print_status "Configurando Firefox dark theme..."

# GTK-3: faz o Firefox (e todos os apps GTK) usarem o dark theme
# Necessário em ambientes sem DE (i3 puro no Xorg)
mkdir -p "$HOME/.config/gtk-3.0"
cat > "$HOME/.config/gtk-3.0/settings.ini" << 'EOF'
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=Adwaita
EOF

# Firefox policies: força ui.systemUsesDarkTheme para dark mode nos sites
sudo mkdir -p /etc/firefox/policies
sudo tee /etc/firefox/policies/policies.json > /dev/null << 'EOF'
{
  "policies": {
    "Preferences": {
      "ui.systemUsesDarkTheme": {
        "Value": 1,
        "Status": "default"
      }
    }
  }
}
EOF

print_success "Firefox dark theme configurado"

# =========================================================
# FINALIZAÇÃO
# =========================================================

echo ""
echo "  Ambiente configurado com sucesso!"
echo ""
echo "  Versões instaladas:"
echo ""

git     --version 2>/dev/null || true
node    --version 2>/dev/null || true
npm     --version 2>/dev/null || true
java    --version 2>/dev/null || true
mvn     --version 2>/dev/null | head -1 || true
docker  --version 2>/dev/null || true
docker compose version 2>/dev/null || true
flatpak --version 2>/dev/null || true
nvim    --version 2>/dev/null | head -1 || true

echo ""
print_warning "Execute 'startx' para iniciar o i3."
print_warning "Faça logout/login para aplicar o grupo docker."
