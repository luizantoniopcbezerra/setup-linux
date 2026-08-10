#!/bin/bash

# Script completo para configuração do ambiente de desenvolvimento Fedora GNOME
# Autor: Guilherme Celso
# Descrição: Automatiza a instalação de ferramentas essenciais no Fedora GNOME

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status()  { echo -e "${BLUE}🔧 $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error()   { echo -e "${RED}❌ $1${NC}"; }

command_exists()    { command -v "$1" >/dev/null 2>&1; }
package_installed() { rpm -q "$1" >/dev/null 2>&1; }

echo "🚀 Iniciando configuração completa do ambiente de desenvolvimento Fedora GNOME..."
echo "⏱️  Este processo pode levar alguns minutos..."
echo ""

# ====================================
# 0. VERIFICAÇÃO DO SISTEMA OPERACIONAL
# ====================================
print_status "Verificando distribuição..."
if [ ! -r /etc/os-release ]; then
    print_error "Não foi possível identificar o sistema operacional."
    exit 1
fi

# shellcheck disable=SC1091
. /etc/os-release

if [ "$ID" != "fedora" ]; then
    print_error "Este script foi feito exclusivamente para Fedora."
    exit 1
fi

if [ "${XDG_CURRENT_DESKTOP:-}" != "" ] && ! echo "$XDG_CURRENT_DESKTOP" | grep -qi "gnome"; then
    print_error "Este script foi feito para Fedora GNOME."
    print_warning "Desktop detectado: ${XDG_CURRENT_DESKTOP}"
    exit 1
fi

print_success "Fedora detectado! (${PRETTY_NAME})"
echo ""

# ====================================
# 1. ATUALIZAÇÃO DO SISTEMA
# ====================================
print_status "Atualizando o sistema..."
sudo dnf upgrade -y --refresh
print_success "Sistema atualizado!"

# ====================================
# 2. CURL
# ====================================
print_status "Verificando/Instalando CURL..."
if ! command_exists curl; then
    sudo dnf install -y curl
    print_success "CURL instalado!"
else
    print_success "CURL já está instalado!"
fi

# ====================================
# 3. GIT
# ====================================
print_status "Verificando/Instalando GIT..."
if ! command_exists git; then
    sudo dnf install -y git
    print_success "GIT instalado!"
else
    print_success "GIT já está instalado!"
fi

print_status "Configurando GIT..."
echo ""
echo "🔧 Configuração do Git:"
read -p "Digite seu nome de usuário Git: " git_username
read -p "Digite seu email Git: " git_email

if [ -n "$git_username" ] && [ -n "$git_email" ]; then
    git config --global user.name "$git_username"
    git config --global user.email "$git_email"
    print_success "GIT configurado com usuário: $git_username ($git_email)"
else
    print_warning "Nome ou email não informados. Configure manualmente depois com:"
    echo "  git config --global user.name 'Seu Nome'"
    echo "  git config --global user.email 'seu.email@exemplo.com'"
fi
echo ""

# ====================================
# 4. DOCKER
# ====================================
print_status "Verificando/Instalando Docker..."
if ! command_exists docker; then
    sudo dnf -y install dnf-plugins-core
    sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    sudo systemctl enable --now docker
    sudo usermod -aG docker "$USER"

    print_success "Docker instalado!"
else
    print_success "Docker já está instalado!"
fi

# ====================================
# 5. NODE.JS 24 LTS
# ====================================
print_status "Verificando/Instalando Node.js 24..."
if ! command_exists node || [[ "$(node --version)" != v24* ]]; then
    # Fedora geralmente possui módulos Node via dnf
    sudo dnf install -y nodejs npm
    print_success "Node.js instalado!"
    if command_exists node; then
        if [[ "$(node --version)" != v24* ]]; then
            print_warning "Versão instalada não é 24.x ($(node --version))."
            print_warning "Se precisar EXATAMENTE 24.x, use nvm ou NodeSource para Fedora."
        fi
    fi
else
    print_success "Node.js 24 já está instalado!"
fi

# ====================================
# 6. DIODON (alternativa no GNOME: GPaste)
# ====================================
print_status "Verificando ferramenta de clipboard..."
if package_installed diodon; then
    print_success "Diodon já está instalado!"
else
    if package_installed gpaste; then
        print_success "GPaste já está instalado!"
    else
        print_warning "Diodon não é padrão no Fedora GNOME. Instalando GPaste..."
        sudo dnf install -y gpaste
        print_success "GPaste instalado!"
    fi
fi

# ====================================
# FINALIZAÇÃO
# ====================================
echo ""
echo "🎉 CONFIGURAÇÃO COMPLETA!"
echo ""
print_success "Todas as ferramentas foram instaladas com sucesso!"
echo ""
echo "🔄 Faça logout/login para aplicar as configurações do Docker (grupo docker)"
echo "🔧 VERSÕES INSTALADAS:"
if command_exists git;    then echo "   Git:     $(git --version)"; fi
if command_exists curl;   then echo "   Curl:    $(curl --version | head -n1)"; fi
if command_exists docker; then echo "   Docker:  $(docker --version)"; fi
if command_exists node;   then echo "   Node.js: $(node --version)"; fi
if command_exists npm;    then echo "   NPM:     $(npm --version)"; fi
echo ""
print_success "Ambiente de desenvolvimento pronto para uso! 🚀"
