#!/bin/bash
set -e

print_status() { echo "[...] $1"; }
print_success() { echo "[OK] $1"; }
print_warning() { echo "[WARN] $1"; }

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

package_installed() {
    rpm -q "$1" >/dev/null 2>&1
}

echo "🚀 Iniciando configuração do ambiente de desenvolvimento..."
echo ""

# =========================================================
# 1 — ATUALIZAÇÃO DO SISTEMA
# =========================================================

print_status "Atualizando sistema..."
sudo dnf upgrade --refresh -y
print_success "Sistema atualizado"

# =========================================================
# 2 — DEPENDÊNCIAS BASE
# =========================================================

print_status "Instalando dependências básicas..."

sudo dnf install -y \
    curl \
    wget \
    git \
    ca-certificates \
    dnf-plugins-core \
    zsh

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
    sudo dnf remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine podman-docker || true

    sudo dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo

    sudo dnf install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin

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
    sudo dnf install -y nodejs
    print_success "Node.js instalado"
else
    print_success "Node já instalado"
fi

# =========================================================
# 6 — DIODON
# =========================================================

print_status "Instalando Diodon..."

if ! package_installed diodon; then
    sudo dnf install -y diodon || print_warning "Diodon não encontrado nos repositórios habilitados"
else
    print_success "Diodon já instalado"
fi

# =========================================================
# FINALIZAÇÃO
# =========================================================

echo ""
echo "✅ Ambiente configurado."
echo ""
echo "Versões instaladas:"
git --version || true
node --version || true
npm --version || true
docker --version || true
docker compose version || true
zsh --version || true
echo ""
print_warning "Faça logout/login para aplicar o grupo docker"
