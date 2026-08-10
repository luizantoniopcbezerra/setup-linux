#!/bin/bash

# Script completo para configuração do ambiente de desenvolvimento Linux Mint
# Autor: Guilherme Celso (adaptado)
# Descrição: Automatiza a instalação de ferramentas essenciais no Linux Mint

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
package_installed() { dpkg -s "$1" >/dev/null 2>&1; }

echo "🚀 Iniciando configuração completa do ambiente de desenvolvimento Linux Mint..."
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

if [ "${ID:-}" != "linuxmint" ]; then
    print_error "Este script foi feito exclusivamente para Linux Mint."
    print_warning "Sistema detectado: ${PRETTY_NAME:-desconhecido}"
    exit 1
fi

print_success "Linux Mint detectado! (${PRETTY_NAME})"
echo ""

# ====================================
# 1. ATUALIZAÇÃO DO SISTEMA
# ====================================
print_status "Atualizando índice de pacotes..."
sudo apt update -y

print_status "Atualizando pacotes instalados..."
sudo apt upgrade -y
print_success "Sistema atualizado!"

# ====================================
# 2. DEPENDÊNCIAS BÁSICAS
# ====================================
print_status "Instalando dependências básicas..."
sudo apt install -y ca-certificates curl gnupg lsb-release software-properties-common
print_success "Dependências básicas instaladas!"

# ====================================
# 3. GIT
# ====================================
print_status "Verificando/Instalando Git..."
if ! command_exists git; then
    sudo apt install -y git
    print_success "Git instalado!"
else
    print_success "Git já está instalado!"
fi

print_status "Configurando Git..."
echo ""
echo "🔧 Configuração do Git:"
read -r -p "Digite seu nome de usuário Git: " git_username
read -r -p "Digite seu email Git: " git_email

if [ -n "$git_username" ] && [ -n "$git_email" ]; then
    git config --global user.name "$git_username"
    git config --global user.email "$git_email"
    print_success "Git configurado com usuário: $git_username ($git_email)"
else
    print_warning "Nome ou email não informados. Configure manualmente depois com:"
    echo "  git config --global user.name 'Seu Nome'"
    echo "  git config --global user.email 'seu.email@exemplo.com'"
fi
echo ""

# ====================================
# 4. DOCKER (repositório oficial)
# ====================================
print_status "Verificando/Instalando Docker..."
if ! command_exists docker; then
    # Remove versões antigas, se houver
    sudo apt remove -y docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc || true

    # Adiciona chave e repositório oficial Docker (Ubuntu base, compatível com Mint)
    sudo install -m 0755 -d /etc/apt/keyrings
    if [ ! -f /etc/apt/keyrings/docker.asc ]; then
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc
    fi

    UBUNTU_CODENAME="${UBUNTU_CODENAME:-}"
    if [ -z "$UBUNTU_CODENAME" ]; then
        print_error "Não foi possível detectar UBUNTU_CODENAME no Linux Mint."
        print_warning "Defina manualmente no /etc/os-release ou ajuste o script."
        exit 1
    fi

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      ${UBUNTU_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update -y
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    sudo systemctl enable --now docker
    sudo usermod -aG docker "$USER"

    print_success "Docker instalado!"
else
    print_success "Docker já está instalado!"
fi

# ====================================
# 5. NODE.JS LTS (NodeSource 24.x)
# ====================================
print_status "Verificando/Instalando Node.js 24..."
if ! command_exists node || [[ "$(node --version)" != v24* ]]; then
    curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
    sudo apt install -y nodejs
    print_success "Node.js instalado!"

    if command_exists node; then
        if [[ "$(node --version)" != v24* ]]; then
            print_warning "Versão instalada não é 24.x ($(node --version))."
            print_warning "Verifique compatibilidade do repositório NodeSource com sua versão do Mint."
        fi
    fi
else
    print_success "Node.js 24 já está instalado!"
fi

# ====================================
# 6. GERENCIADOR DE ÁREA DE TRANSFERÊNCIA
# (Linux Mint/Cinnamon: clipit/parcellite/copyq)
# ====================================
print_status "Verificando ferramenta de clipboard..."
if package_installed copyq; then
    print_success "CopyQ já está instalado!"
else
    print_warning "Instalando CopyQ..."
    sudo apt install -y copyq
    print_success "CopyQ instalado!"
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
