#!/bin/bash

set -e

# =========================================================
# HELPERS
# =========================================================

print_status() {
    echo "[...] $1"
}

print_success() {
    echo "[OK] $1"
}

print_warning() {
    echo "[WARN] $1"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

package_installed() {
    dpkg -l | grep -q "^ii  $1 "
}

echo "🚀 Iniciando configuração do ambiente de desenvolvimento..."
echo ""

# =========================================================
# 1 — ATUALIZAÇÃO DO SISTEMA
# =========================================================

print_status "Atualizando sistema..."

sudo apt update
sudo apt upgrade -y

print_success "Sistema atualizado"

# =========================================================
# 2 — DEPENDÊNCIAS BASE
# =========================================================

print_status "Instalando dependências básicas..."

sudo apt install -y \
    curl \
    wget \
    git \
    ca-certificates \
    gnupg \
    lsb-release

print_success "Dependências instaladas"

# =========================================================
# 3 — CONFIGURAÇÃO DO GIT
# =========================================================

print_status "Configurando Git"

read -p "Nome Git: " git_username
read -p "Email Git: " git_email

if [ -n "$git_username" ] && [ -n "$git_email" ]; then
    git config --global user.name "$git_username"
    git config --global user.email "$git_email"

    print_success "Git configurado"
else
    print_warning "Git não configurado"
fi

# =========================================================
# 4 — ZSH + OH MY ZSH
# =========================================================

print_status "Instalando ZSH..."

if ! command_exists zsh; then
    sudo apt install -y zsh
fi

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    print_status "Instalando Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

print_success "ZSH pronto"

# =========================================================
# 5 — PLUGINS ZSH
# =========================================================

print_status "Instalando plugins ZSH..."

ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

git clone https://github.com/zsh-users/zsh-autosuggestions \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions" 2>/dev/null || true

git clone https://github.com/zsh-users/zsh-syntax-highlighting \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" 2>/dev/null || true

git clone https://github.com/zsh-users/zsh-completions \
    "$ZSH_CUSTOM/plugins/zsh-completions" 2>/dev/null || true

git clone https://github.com/zsh-users/zsh-history-substring-search \
    "$ZSH_CUSTOM/plugins/zsh-history-substring-search" 2>/dev/null || true

sudo apt install -y autojump

if [ -f "$HOME/.zshrc" ]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.bak"

    if grep -q "^plugins=" "$HOME/.zshrc"; then
        sed -i 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-completions autojump zsh-history-substring-search zsh-syntax-highlighting)/' "$HOME/.zshrc"
    else
        echo 'plugins=(git zsh-autosuggestions zsh-completions autojump zsh-history-substring-search zsh-syntax-highlighting)' >> "$HOME/.zshrc"
    fi
fi

print_success "Plugins configurados"

# =========================================================
# 6 — ZSH COMO SHELL PADRÃO
# =========================================================

print_status "Definindo ZSH como shell padrão..."

ZSH_PATH="$(which zsh)"

if [ "$SHELL" != "$ZSH_PATH" ]; then
    chsh -s "$ZSH_PATH" "$USER"
    print_success "ZSH definido como shell padrão (efetivo no próximo login)"
else
    print_success "ZSH já é o shell padrão"
fi

# =========================================================
# 7 — DOCKER
# =========================================================

print_status "Instalando Docker..."

if ! command_exists docker; then

    sudo install -m 0755 -d /etc/apt/keyrings

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update

    sudo apt install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin

    sudo systemctl enable docker
    sudo systemctl start docker

    sudo usermod -aG docker "$USER"

    print_success "Docker instalado"
    print_warning "Reinicie a sessão para usar Docker sem sudo"

else
    print_success "Docker já instalado"
fi

# =========================================================
# 8 — NODE.JS LTS
# =========================================================

print_status "Instalando Node.js LTS..."

if ! command_exists node; then
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt install -y nodejs
    print_success "Node.js LTS instalado"
else
    print_success "Node já instalado"
fi

# =========================================================
# 9 — SUBLIME TEXT
# =========================================================

print_status "Instalando Sublime Text..."

if ! command_exists subl; then

    wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg \
        | sudo tee /etc/apt/keyrings/sublimehq-pub.asc > /dev/null

    echo -e 'Types: deb\nURIs: https://download.sublimetext.com/\nSuites: apt/stable/\nSigned-By: /etc/apt/keyrings/sublimehq-pub.asc' \
        | sudo tee /etc/apt/sources.list.d/sublime-text.sources

    sudo apt update
    sudo apt install -y sublime-text

    print_success "Sublime Text instalado"

else
    print_success "Sublime Text já instalado"
fi

# =========================================================
# 10 — ZED EDITOR
# =========================================================

print_status "Instalando Zed..."

if ! command_exists zed; then
    curl -f https://zed.dev/install.sh | sh

    # Zed instala em ~/.local/bin — garante que está no PATH do zshrc
    if [ -f "$HOME/.zshrc" ] && ! grep -q '\.local/bin' "$HOME/.zshrc"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
    fi

    print_success "Zed instalado"
else
    print_success "Zed já instalado"
fi

# =========================================================
# 11 — DIODON
# =========================================================

print_status "Instalando Diodon..."

if ! package_installed diodon; then
    sudo apt install -y diodon
fi

print_success "Diodon instalado"

# =========================================================
# FINALIZAÇÃO
# =========================================================

echo ""
echo "✅ Ambiente configurado."
echo ""
echo "Versões instaladas:"
git --version   || true
node --version  || true
npm --version   || true
docker --version || true
zsh --version   || true
subl --version  || true
zed --version   || true
echo ""
print_warning "Faça logout/login para aplicar: shell padrão (zsh) e grupo docker"
