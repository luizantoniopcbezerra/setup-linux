#!/bin/bash

# Script completo para configuração do ambiente de desenvolvimento Linux Mint
# Autor: Guilherme Celso (adaptado)
# Descrição: Automatiza a instalação de ferramentas essenciais no Linux Mint

set -Eeuo pipefail

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
docker_compose_exists() { command_exists docker && docker compose version >/dev/null 2>&1; }

repair_legacy_docker_key() {
    local docker_key_asc=/etc/apt/keyrings/docker.asc
    local docker_key_gpg=/etc/apt/keyrings/docker.gpg
    local docker_source=/etc/apt/sources.list.d/docker.list

    # Versões anteriores deste script salvaram uma chave binária com extensão
    # .asc. O APT usa a extensão para escolher o formato e ignora essa chave,
    # causando NO_PUBKEY antes que o instalador consiga atualizá-la.
    if [ -r "$docker_key_asc" ] && [ -r "$docker_source" ] && \
       ! grep -q '^-----BEGIN PGP PUBLIC KEY BLOCK-----' "$docker_key_asc"; then
        print_warning "Corrigindo formato de uma chave antiga do repositório Docker..."
        sudo install -m 0644 "$docker_key_asc" "$docker_key_gpg"
        sudo sed -i \
            's#/etc/apt/keyrings/docker\.asc#/etc/apt/keyrings/docker.gpg#g' \
            "$docker_source"
        print_success "Chave antiga do Docker reparada para permitir o apt update."
    fi
}

on_error() {
    local exit_code=$?
    print_error "A instalação falhou na linha ${BASH_LINENO[0]} (comando: ${BASH_COMMAND})."
    print_warning "Corrija o erro acima e execute o script novamente; as etapas já concluídas serão preservadas."
    exit "$exit_code"
}

trap on_error ERR

echo "🚀 Iniciando configuração completa do ambiente de desenvolvimento Linux Mint..."
echo "⏱️  Este processo pode levar alguns minutos..."
echo ""

if [ "$(id -u)" -eq 0 ]; then
    print_error "Execute este script como usuário comum, não como root."
    print_warning "O script usa sudo internamente quando necessário."
    exit 1
fi

if ! command_exists sudo; then
    print_error "O comando sudo não está instalado."
    exit 1
fi

print_status "Validando acesso administrativo..."
sudo -v

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

# Precisa ocorrer antes do primeiro apt update, pois um repositório Docker
# deixado por versões anteriores pode bloquear a atualização de todos os pacotes.
repair_legacy_docker_key

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
print_status "Verificando/Instalando Docker Engine e Docker Compose..."
if ! command_exists docker || ! docker_compose_exists; then
    # Remove versões antigas, se houver
    sudo apt remove -y docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc || true

    # Adiciona chave e repositório oficial Docker (Ubuntu base, compatível com Mint)
    sudo install -m 0755 -d /etc/apt/keyrings

    # Atualiza a chave sempre, evitando manter uma chave vazia, corrompida ou antiga.
    docker_key_tmp="$(mktemp)"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o "$docker_key_tmp"
    sudo install -m 0644 "$docker_key_tmp" /etc/apt/keyrings/docker.asc
    rm -f "$docker_key_tmp"

    ubuntu_codename="${UBUNTU_CODENAME:-}"
    if [ -z "$ubuntu_codename" ] && [ -r /etc/upstream-release/lsb-release ]; then
        ubuntu_codename="$(
            # shellcheck disable=SC1091
            . /etc/upstream-release/lsb-release
            printf '%s' "${DISTRIB_CODENAME:-}"
        )"
    fi

    if [ -z "$ubuntu_codename" ]; then
        print_error "Não foi possível detectar o codename Ubuntu base do Linux Mint."
        print_warning "Verifique se UBUNTU_CODENAME existe em /etc/os-release ou se /etc/upstream-release/lsb-release está disponível."
        exit 1
    fi

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      ${ubuntu_codename} stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update -y
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Atualiza o cache de comandos do shell e comprova os executáveis.
    hash -r
    command_exists docker
    docker compose version >/dev/null

    print_success "Docker Engine e Docker Compose instalados!"
else
    print_success "Docker Engine e Docker Compose já estão instalados!"
fi

# Corrige também instalações existentes que estejam com o serviço parado ou
# sem permissão para o usuário atual.
sudo systemctl enable --now docker
sudo usermod -aG docker "$(id -un)"
sudo docker info >/dev/null
print_success "Serviço Docker ativo e usuário adicionado ao grupo docker!"

# ====================================
# 5. NODE.JS LTS (NodeSource 24.x)
# ====================================
print_status "Verificando/Instalando Node.js 24..."
if ! command_exists node || ! command_exists npm || [[ "$(node --version)" != v24* ]]; then
    nodesource_setup_tmp="$(mktemp)"
    curl -fsSL https://deb.nodesource.com/setup_24.x -o "$nodesource_setup_tmp"
    sudo -E bash "$nodesource_setup_tmp"
    rm -f "$nodesource_setup_tmp"
    sudo apt install -y nodejs

    hash -r
    if ! command_exists node || ! command_exists npm; then
        print_error "O pacote nodejs foi processado, mas os comandos node e npm não ficaram disponíveis."
        exit 1
    fi

    if [[ "$(node --version)" != v24* ]]; then
        print_error "Era esperado Node.js 24.x, mas foi instalado $(node --version)."
        exit 1
    fi

    print_success "Node.js $(node --version) e npm $(npm --version) instalados!"
else
    print_success "Node.js 24 e npm já estão instalados!"
fi

# ====================================
# 6. GERENCIADOR DE ÁREA DE TRANSFERÊNCIA
# (Linux Mint/Cinnamon: Diodon)
# ====================================
print_status "Verificando ferramenta de clipboard..."
if package_installed diodon; then
    print_success "Diodon já está instalado!"
else
    print_warning "Instalando Diodon..."
    sudo apt install -y diodon
    print_success "Diodon instalado!"
fi

# ====================================
# FINALIZAÇÃO
# ====================================
echo ""
echo "🎉 CONFIGURAÇÃO COMPLETA!"
echo ""
print_success "Todas as ferramentas obrigatórias foram instaladas e verificadas com sucesso!"
echo ""
echo "🔄 Faça logout/login para aplicar as configurações do Docker (grupo docker)"
echo "🔧 VERSÕES INSTALADAS:"
if command_exists git;    then echo "   Git:     $(git --version)"; fi
if command_exists curl;   then echo "   Curl:    $(curl --version | head -n1)"; fi
if command_exists docker; then echo "   Docker:  $(docker --version)"; fi
if command_exists node;   then echo "   Node.js: $(node --version)"; fi
if command_exists npm;    then echo "   NPM:     $(npm --version)"; fi
if command_exists diodon; then echo "   Diodon:  $(diodon --version 2>/dev/null || echo instalado)"; fi
echo ""
print_success "Ambiente de desenvolvimento pronto para uso! 🚀"
