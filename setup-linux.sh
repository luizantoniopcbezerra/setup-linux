#!/bin/bash
set -e

print_status() { echo "[...] $1"; }
print_success() { echo "[OK] $1"; }
print_warning() { echo "[WARN] $1"; }

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

package_installed() {
    local pkg="$1"

    if command_exists dnf; then
        rpm -q "$pkg" >/dev/null 2>&1
    elif command_exists apt; then
        dpkg -s "$pkg" >/dev/null 2>&1
    else
        return 1
    fi
}

# =========================================================
# DETECÇÃO DA DISTRO
# =========================================================

if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "❌ Não foi possível detectar a distribuição Linux."
    exit 1
fi

echo "🚀 Iniciando configuração do ambiente de desenvolvimento..."
echo "🐧 Distribuição detectada: $DISTRO"
echo ""

# =========================================================
# HELPERS DE PACOTE
# =========================================================

install_packages() {
    if command_exists dnf; then
        sudo dnf install -y "$@"
    elif command_exists apt; then
        sudo apt install -y "$@"
    else
        echo "❌ Gerenciador de pacotes não suportado."
        exit 1
    fi
}

update_system() {
    if command_exists dnf; then
        sudo dnf upgrade --refresh -y
    elif command_exists apt; then
        sudo apt update && sudo apt upgrade -y
    fi
}

# =========================================================
# 1 — ATUALIZAÇÃO DO SISTEMA
# =========================================================

print_status "Atualizando sistema..."
update_system
print_success "Sistema atualizado"

# =========================================================
# 2 — DEPENDÊNCIAS BASE
# =========================================================

print_status "Instalando dependências básicas..."

install_packages \
    curl \
    wget \
    git \
    ca-certificates \
    ImageMagick \
    unzip

if command_exists dnf; then
    install_packages dnf-plugins-core
fi

print_success "Dependências instaladas"

# =========================================================
# 3 — CONFIGURAÇÃO DO GIT
# =========================================================

print_status "Configurando Git"

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
# 4 — DOCKER
# =========================================================

print_status "Instalando Docker..."

if ! command_exists docker; then

    if command_exists dnf; then
        sudo dnf remove -y \
            docker \
            docker-client \
            docker-client-latest \
            docker-common \
            docker-latest \
            docker-latest-logrotate \
            docker-logrotate \
            docker-selinux \
            docker-engine-selinux \
            docker-engine \
            podman-docker || true

        sudo dnf config-manager addrepo \
            --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo

        install_packages \
            docker-ce \
            docker-ce-cli \
            containerd.io \
            docker-buildx-plugin \
            docker-compose-plugin

    elif command_exists apt; then
        sudo apt remove -y docker docker-engine docker.io containerd runc || true

        sudo install -m 0755 -d /etc/apt/keyrings

        curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
            | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

        sudo chmod a+r /etc/apt/keyrings/docker.gpg

        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
          https://download.docker.com/linux/ubuntu \
          $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
          | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        sudo apt update

        install_packages \
            docker-ce \
            docker-ce-cli \
            containerd.io \
            docker-buildx-plugin \
            docker-compose-plugin
    fi

    sudo systemctl enable --now docker
    sudo usermod -aG docker "$USER"

    print_success "Docker instalado"
    print_warning "Faça logout/login para usar Docker sem sudo"

else
    print_success "Docker já instalado"
fi

# =========================================================
# 5 — NODE.JS E NPM
# =========================================================

print_status "Instalando Node.js e npm..."

if ! command_exists node; then
    install_packages nodejs npm
    print_success "Node.js instalado"
else
    print_success "Node.js já instalado"
fi

# =========================================================
# 6 — JAVA 21
# =========================================================

print_status "Instalando Java 21..."

if ! command_exists java; then

    if command_exists dnf; then
        install_packages java-21-openjdk java-21-openjdk-devel
    elif command_exists apt; then
        install_packages openjdk-21-jdk
    fi

    print_success "Java 21 instalado"

else
    print_success "Java já instalado"
fi

# =========================================================
# 7 — MAVEN
# =========================================================

print_status "Instalando Maven..."

if ! command_exists mvn; then
    install_packages maven
    print_success "Maven instalado"
else
    print_success "Maven já instalado"
fi

# =========================================================
# 8 — FLATPAK + APPS
# =========================================================

print_status "Configurando Flatpak..."

if ! command_exists flatpak; then
    install_packages flatpak
fi

# Flathub
if ! flatpak remote-list | grep -q flathub; then
    sudo flatpak remote-add --if-not-exists flathub \
        https://flathub.org/repo/flathub.flatpakrepo
fi

print_success "Flatpak configurado"

# ---------------------------------------------------------
# Obsidian
# ---------------------------------------------------------

print_status "Instalando Obsidian..."

if ! flatpak list | grep -q md.obsidian.Obsidian; then
    flatpak install -y flathub md.obsidian.Obsidian
    print_success "Obsidian instalado"
else
    print_success "Obsidian já instalado"
fi

# ---------------------------------------------------------
# IntelliJ IDEA Community (Open)
# ---------------------------------------------------------

print_status "Instalando IntelliJ IDEA Community..."

if ! flatpak list | grep -q com.jetbrains.IntelliJ-IDEA-Community; then
    flatpak install -y flathub com.jetbrains.IntelliJ-IDEA-Community
    print_success "IntelliJ IDEA Community instalado"
else
    print_success "IntelliJ IDEA Community já instalado"
fi

# =========================================================
# 9 — I3 + DEPENDÊNCIAS
# =========================================================

print_status "Instalando i3 e dependências..."

if command_exists dnf; then
    install_packages \
        i3 \
        i3status \
        rofi \
        feh \
        picom \
        xss-lock \
        network-manager-applet \
        brightnessctl \
        dex \
        fontconfig \
        maim \
        slop
elif command_exists apt; then
    install_packages \
        i3 \
        i3status \
        rofi \
        feh \
        picom \
        xss-lock \
        network-manager-gnome \
        brightnessctl \
        dex \
        fontconfig \
        maim \
        slop
fi

print_success "i3 instalado"

# =========================================================
# 10 — JETBRAINS MONO NERD FONT
# =========================================================

print_status "Instalando JetBrainsMono Nerd Font..."

NERD_FONT_VERSION="3.4.0"
FONT_DIR="$HOME/.local/share/fonts/JetBrainsMonoNF"

if ! fc-list | grep -q "JetBrainsMono Nerd Font"; then
    mkdir -p "$FONT_DIR"
    curl -fsSL \
        "https://github.com/ryanoasis/nerd-fonts/releases/download/v${NERD_FONT_VERSION}/JetBrainsMono.zip" \
        -o /tmp/JetBrainsMono.zip
    unzip -o /tmp/JetBrainsMono.zip -d "$FONT_DIR"
    rm /tmp/JetBrainsMono.zip
    fc-cache -fv
    print_success "JetBrainsMono Nerd Font instalada"
else
    print_success "JetBrainsMono Nerd Font já instalada"
fi

# =========================================================
# 11 — CONFIGURAÇÃO DO I3
# =========================================================

print_status "Aplicando configuração do i3..."

mkdir -p "$HOME/.config/i3"
mkdir -p "$HOME/.config/i3status"

# ---------------------------------------------------------
# ~/.config/i3/config
# ---------------------------------------------------------

cat > "$HOME/.config/i3/config" << 'EOF'
# i3 config file (v4)

set $mod Mod4

default_border pixel 1
default_floating_border pixel 1
for_window [class=".*"] border pixel 1

gaps inner 10
gaps outer 4

font pango:JetBrainsMono Nerd Font Mono 10

exec --no-startup-id dex --autostart --environment i3
exec --no-startup-id picom -b
exec --no-startup-id xss-lock --transfer-sleep-lock -- i3lock --nofork
exec --no-startup-id nm-applet

set $refresh_i3status killall -SIGUSR1 i3status
bindsym XF86AudioRaiseVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +10% && $refresh_i3status
bindsym XF86AudioLowerVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -10% && $refresh_i3status
bindsym XF86AudioMute exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle && $refresh_i3status
bindsym XF86AudioMicMute exec --no-startup-id pactl set-source-mute @DEFAULT_SOURCE@ toggle && $refresh_i3status

floating_modifier $mod
tiling_drag modifier titlebar

bindsym $mod+Return exec i3-sensible-terminal
bindsym $mod+Shift+q kill
bindsym $mod+d exec --no-startup-id rofi -show drun

bindsym $mod+j focus left
bindsym $mod+k focus down
bindsym $mod+l focus up
bindsym $mod+semicolon focus right
bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right

bindsym $mod+Shift+j move left
bindsym $mod+Shift+k move down
bindsym $mod+Shift+l move up
bindsym $mod+Shift+semicolon move right
bindsym $mod+Shift+Left move left
bindsym $mod+Shift+Down move down
bindsym $mod+Shift+Up move up
bindsym $mod+Shift+Right move right

bindsym $mod+h split h
bindsym $mod+v split v
bindsym $mod+f fullscreen toggle
bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+e layout toggle split
bindsym $mod+Shift+space floating toggle
bindsym $mod+space focus mode_toggle
bindsym $mod+a focus parent

set $ws1 "1: 󰆍"
set $ws2 "2: 󰈹"
set $ws3 "3: 󰨞"
set $ws4 "4: 󰭹"
set $ws5 "5: 󰝚"
set $ws6 "6"
set $ws7 "7"
set $ws8 "8"
set $ws9 "9"
set $ws10 "10"

bindsym $mod+1 workspace number $ws1
bindsym $mod+2 workspace number $ws2
bindsym $mod+3 workspace number $ws3
bindsym $mod+4 workspace number $ws4
bindsym $mod+5 workspace number $ws5
bindsym $mod+6 workspace number $ws6
bindsym $mod+7 workspace number $ws7
bindsym $mod+8 workspace number $ws8
bindsym $mod+9 workspace number $ws9
bindsym $mod+0 workspace number $ws10

bindsym $mod+Shift+1 move container to workspace number $ws1
bindsym $mod+Shift+2 move container to workspace number $ws2
bindsym $mod+Shift+3 move container to workspace number $ws3
bindsym $mod+Shift+4 move container to workspace number $ws4
bindsym $mod+Shift+5 move container to workspace number $ws5
bindsym $mod+Shift+6 move container to workspace number $ws6
bindsym $mod+Shift+7 move container to workspace number $ws7
bindsym $mod+Shift+8 move container to workspace number $ws8
bindsym $mod+Shift+9 move container to workspace number $ws9
bindsym $mod+Shift+0 move container to workspace number $ws10

bindsym $mod+Shift+c reload
bindsym $mod+Shift+r restart
bindsym $mod+Shift+e exec "i3-nagbar -t warning -m 'Sair do i3?' -B 'Sim' 'i3-msg exit'"

mode "resize" {
    bindsym j resize shrink width 10 px or 10 ppt
    bindsym k resize grow height 10 px or 10 ppt
    bindsym l resize shrink height 10 px or 10 ppt
    bindsym semicolon resize grow width 10 px or 10 ppt
    bindsym Left resize shrink width 10 px or 10 ppt
    bindsym Down resize grow height 10 px or 10 ppt
    bindsym Up resize shrink height 10 px or 10 ppt
    bindsym Right resize grow width 10 px or 10 ppt
    bindsym Return mode "default"
    bindsym Escape mode "default"
    bindsym $mod+r mode "default"
}

bindsym $mod+r mode "resize"

exec_always --no-startup-id setxkbmap br abnt2

bindsym F3 exec --no-startup-id brightnessctl set 5%-
bindsym F4 exec --no-startup-id brightnessctl set +5%

bindsym Print exec maim -s ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png

client.focused          #7aab7a #0d1a0d #e0f0e0 #7aab7a #7aab7a
client.unfocused        #0d0d0d #0d0d0d #3a4a3a #0d0d0d #0d0d0d
client.focused_inactive #1a2a1a #1a2a1a #5a7a5a #1a2a1a #1a2a1a
client.urgent           #cc4444 #cc4444 #080808 #cc4444 #cc4444

bar {
    position top
    height 26
    tray_padding 4
    separator_symbol "  "
    font pango:JetBrainsMono Nerd Font Mono 10
    status_command i3status
    colors {
        background #080808
        statusline #c0d8c0
        separator  #2a3a2a
        focused_workspace  #7aab7a #0d1a0d  #e0f0e0
        active_workspace   #3a5a3a #0d1a0d  #8aaa8a
        inactive_workspace #080808 #080808  #3a4a3a
        urgent_workspace   #cc4444 #cc4444  #080808
    }
}
EOF

# ---------------------------------------------------------
# ~/.config/i3status/config
# ---------------------------------------------------------

cat > "$HOME/.config/i3status/config" << 'EOF'
general {
    colors = true
    interval = 5
    color_good     = "#a8d8a8"
    color_degraded = "#f0c060"
    color_bad      = "#f07070"
}

order += "wireless _first_"
order += "ethernet _first_"
order += "volume master"
order += "battery all"
order += "disk /"
order += "cpu_usage"
order += "memory"
order += "tztime local"

wireless _first_ {
    format_up   = "󰤨  %essid %ip"
    format_down = "󰤭  desconectado"
}

ethernet _first_ {
    format_up   = "󰈀  %ip"
    format_down = ""
}

volume master {
    format        = "󰕾  %volume"
    format_muted  = "󰗁  mudo"
    device        = "pulse"
    mixer         = "Master"
    mixer_idx     = 0
}

battery all {
    format          = "%status %percentage %remaining"
    format_down     = "sem bateria"
    status_chr      = "󰂄 "
    status_bat      = "󰁹 "
    status_unk      = "? "
    status_full     = "󰁹 "
    low_threshold   = 15
    threshold_type  = percentage
    integer_battery_capacity = true
    last_full_capacity = true
}

disk "/" {
    format          = "󰋊  %avail livre"
    low_threshold   = 10
    threshold_type  = gbytes_avail
}

cpu_usage {
    format          = "󰍛  %usage"
    degraded_threshold = 60
    max_threshold   = 90
}

memory {
    format          = "󰘙  %used / %total"
    threshold_degraded = "2G"
    format_degraded = "󰘙  MEM BAIXA %available"
}

tztime local {
    format = "󰥔  %d/%m/%Y  %H:%M"
}
EOF

# ---------------------------------------------------------
# ~/.config/picom.conf
# ---------------------------------------------------------

cat > "$HOME/.config/picom.conf" << 'EOF'
backend = "glx";
vsync = true;

opacity-rule = [
    "75:class_g = 'Alacritty'",
    "100:class_g != 'Alacritty'"
];

fading = true;
fade-in-step = 0.05;
fade-out-step = 0.05;
fade-delta = 8;

shadow = false;
EOF

# ---------------------------------------------------------
# ~/.config/alacritty/alacritty.toml
# ---------------------------------------------------------

mkdir -p "$HOME/.config/alacritty"

cat > "$HOME/.config/alacritty/alacritty.toml" << 'EOF'
[window]
opacity = 1.0
padding = { x = 12, y = 12 }

[cursor]
style = { shape = "Beam", blinking = "On" }
blink_interval = 500

[font]
size = 11.0

[font.normal]
family = "JetBrainsMono Nerd Font Mono"
style = "Regular"

[font.bold]
family = "JetBrainsMono Nerd Font Mono"
style = "Bold"

[font.italic]
family = "JetBrainsMono Nerd Font Mono"
style = "Italic"

[colors.primary]
background = "#000000"
foreground = "#e0e8e0"

[colors.normal]
black =   "#0d0d0d"
red =     "#ff4444"
green =   "#7aab7a"
yellow =  "#c0d8c0"
blue =    "#6ab0f5"
magenta = "#8aaa8a"
cyan =    "#50c8a0"
white =   "#c0d8c0"

[colors.bright]
black =   "#333333"
red =     "#ff6666"
green =   "#9ac89a"
yellow =  "#e0f0e0"
blue =    "#8acbff"
magenta = "#c0d8c0"
cyan =    "#70e0b0"
white =   "#ffffff"
EOF

# ---------------------------------------------------------
# ~/.config/rofi/config.rasi + theme.rasi
# ---------------------------------------------------------

mkdir -p "$HOME/.config/rofi"

cat > "$HOME/.config/rofi/config.rasi" << 'EOF'
configuration {
    modi: "drun,run";
    show-icons: true;
    icon-theme: "Papirus-Dark";
    font: "JetBrainsMono Nerd Font Mono 11";
    display-drun: "󰍉  apps";
    display-run:  "  run";
}

@theme "~/.config/rofi/theme.rasi"
EOF

cat > "$HOME/.config/rofi/theme.rasi" << 'EOF'
* {
    bg:     #080808;
    bg-alt: #0d1a0d;
    fg:     #c0d8c0;
    fg-dim: #3a5a3a;
    accent: #7aab7a;
    urgent: #cc4444;

    background-color: transparent;
    text-color:       @fg;
    border-color:     transparent;
    outline-color:    transparent;
}

window {
    background-color: @bg;
    border:           1px solid;
    border-color:     @accent;
    border-radius:    6px;
    width:            480px;
    padding:          0;
}

mainbox {
    background-color: transparent;
    padding:          8px;
    spacing:          0;
}

inputbar {
    background-color: @bg-alt;
    border-radius:    4px;
    padding:          8px 12px;
    margin:           0 0 8px 0;
    spacing:          0;
    children:         [ prompt, entry ];
}

prompt {
    background-color: transparent;
    text-color:       @accent;
    padding:          0 8px 0 0;
}

entry {
    background-color: transparent;
    text-color:       @fg;
}

listview {
    background-color: transparent;
    lines:            8;
    columns:          1;
    spacing:          2px;
    scrollbar:        false;
    padding:          0;
}

element {
    background-color: transparent;
    padding:          6px 12px;
    border-radius:    4px;
    spacing:          0;
}

element normal.normal,
element alternate.normal {
    background-color: transparent;
    text-color:       @fg;
}

element selected.normal {
    background-color: @bg-alt;
    text-color:       @accent;
}

element normal.urgent,
element alternate.urgent {
    background-color: transparent;
    text-color:       @urgent;
}

element selected.urgent {
    background-color: @bg-alt;
    text-color:       @urgent;
}

element-icon {
    background-color: transparent;
    size:             18px;
    padding:          0 8px 0 0;
}

element-text {
    background-color: transparent;
    text-color:       inherit;
}
EOF

mkdir -p "$HOME/Pictures"

print_success "Configuração do i3 aplicada"
print_warning "Defina o wallpaper em ~/.config/i3/config (exec feh --bg-scale /caminho/wallpaper.png)"

# =========================================================
# FINALIZAÇÃO
# =========================================================

echo ""
echo "✅ Ambiente configurado."
echo ""
echo "Versões instaladas:"
echo ""

git --version || true
node --version || true
npm --version || true
java --version || true
mvn --version || true
docker --version || true
docker compose version || true
flatpak --version || true

if command_exists zed; then
    zed --version || true
fi

echo ""
print_warning "Faça logout/login para aplicar o grupo docker"
