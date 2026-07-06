#!/bin/bash

# Script completo para configuração do ambiente de desenvolvimento Linux Mint
# Autor: Guilherme Celso
# Descrição: Automatiza a instalação de todas as ferramentas essenciais

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
package_installed() { dpkg -l | grep -q "^ii  $1 "; }

# Retorna o codename da versão Ubuntu na qual o Linux Mint é baseado.
# Necessário porque `lsb_release -cs` retorna o codename do Mint (ex: "vera"),
# que não existe nos repositórios de terceiros (Docker, Adoptium), causando falha.
get_ubuntu_base_codename() {
    if [ -r /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        if [ -n "$UBUNTU_CODENAME" ]; then
            echo "$UBUNTU_CODENAME"
            return
        fi
    fi
    lsb_release -cs
}

echo "🚀 Iniciando configuração completa do ambiente de desenvolvimento Linux Mint..."
echo "⏱️  Este processo pode levar alguns minutos..."
echo ""

# ====================================
# 0. VERIFICAÇÃO DO SISTEMA OPERACIONAL
# ====================================
print_status "Verificando distribuição..."
if [ ! -r /etc/os-release ] || ! grep -qi '^ID=linuxmint' /etc/os-release; then
    print_error "Este script foi feito exclusivamente para o Linux Mint."
    exit 1
fi
print_success "Linux Mint detectado! ($(grep '^VERSION=' /etc/os-release | cut -d'"' -f2))"
echo ""

# ====================================
# 1. ATUALIZAÇÃO DO SISTEMA
# ====================================
print_status "Atualizando o sistema..."
sudo apt update && sudo apt upgrade -y
print_success "Sistema atualizado!"

# ====================================
# 2. CURL
# ====================================
print_status "Verificando/Instalando CURL..."
if ! command_exists curl; then
    sudo apt install -y curl
    print_success "CURL instalado!"
else
    print_success "CURL já está instalado!"
fi

# ====================================
# 3. GIT
# ====================================
print_status "Verificando/Instalando GIT..."
if ! command_exists git; then
    sudo apt install -y git
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
    sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(get_ubuntu_base_codename) stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    sudo systemctl start docker && sudo systemctl enable docker
    sudo usermod -aG docker "$USER"
    # Nota: chmod 666 no socket é inseguro; o grupo docker é suficiente após relogin

    print_success "Docker instalado!"
else
    print_success "Docker já está instalado!"
fi

# ====================================
# 5. NODE.JS 24 LTS (Krypton)
# ====================================
print_status "Verificando/Instalando Node.js 24 LTS..."
if ! command_exists node || [[ "$(node --version)" != v24* ]]; then
    curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
    sudo apt-get install -y nodejs
    print_success "Node.js 24 LTS instalado!"
else
    print_success "Node.js 24 LTS já está instalado!"
fi

# ====================================
# 6. JAVA 21 LTS (Temurin)
# ====================================
print_status "Verificando/Instalando Java 21 LTS..."
java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
if ! command_exists java || [[ "$java_version" != "21" ]]; then
    sudo apt install -y wget apt-transport-https gpg

    wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public \
        | sudo gpg --dearmor -o /etc/apt/keyrings/adoptium.gpg
    echo "deb [signed-by=/etc/apt/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb \
$(get_ubuntu_base_codename) main" \
        | sudo tee /etc/apt/sources.list.d/adoptium.list > /dev/null

    sudo apt update
    sudo apt install -y temurin-21-jdk
    print_success "Java 21 instalado!"
else
    print_success "Java 21 já está instalado!"
fi

# ====================================
# 7. MAVEN
# ====================================
print_status "Verificando/Instalando Maven..."
if ! command_exists mvn; then
    sudo apt install -y maven
    print_success "Maven instalado!"
else
    print_success "Maven já está instalado!"
fi

# ====================================
# 8. DIODON
# ====================================
print_status "Verificando/Instalando Diodon..."
if ! package_installed diodon; then
    sudo apt install -y diodon
    print_success "Diodon instalado!"
else
    print_success "Diodon já está instalado!"
fi

# ====================================
# FINALIZAÇÃO
# ====================================
echo ""
echo "🎉 CONFIGURAÇÃO COMPLETA!"
echo ""
print_success "Todas as ferramentas foram instaladas com sucesso!"
echo ""
echo "🔄 Faça logout/login para aplicar as configurações do Docker"
echo "🔧 VERSÕES INSTALADAS:"
if command_exists git;    then echo "   Git:     $(git --version)"; fi
if command_exists curl;   then echo "   Curl:    $(curl --version | head -n1)"; fi
if command_exists docker; then echo "   Docker:  $(docker --version)"; fi
if command_exists node;   then echo "   Node.js: $(node --version)"; fi
if command_exists npm;    then echo "   NPM:     $(npm --version)"; fi
if command_exists java;   then echo "   Java:    $(java -version 2>&1 | head -n1)"; fi
if command_exists mvn;    then echo "   Maven:   $(mvn --version | head -n1)"; fi
echo ""
print_success "Ambiente de desenvolvimento pronto para uso! 🚀"
