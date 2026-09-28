#!/bin/bash

# Script completo para configuração do ambiente de desenvolvimento Ubuntu LTS
# Autor: Guilherme Celso (adaptado)
# Descrição: Automatiza a instalação e a validação de ferramentas essenciais
#            no Ubuntu LTS. Somente Ubuntu LTS é aceito (nenhuma outra distro).

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

# ====================================
# VALIDAÇÃO ITEM A ITEM
# Cada programa da lista registra aqui a função que prova que ele
# está instalado; ao final tudo é verificado e reportado.
# ====================================
VALIDATION_NAMES=()
VALIDATION_CHECKS=()
VALIDATION_FAILURES=0

register_validation() {
    VALIDATION_NAMES+=("$1")
    VALIDATION_CHECKS+=("$2")
}

run_validations() {
    local index name check
    VALIDATION_FAILURES=0

    echo ""
    print_status "Validando item a item se cada programa está instalado..."
    echo ""

    for index in "${!VALIDATION_NAMES[@]}"; do
        name="${VALIDATION_NAMES[$index]}"
        check="${VALIDATION_CHECKS[$index]}"
        if "$check"; then
            print_success "$(printf '%-30s' "$name") INSTALADO"
        else
            print_error "$(printf '%-30s' "$name") NÃO INSTALADO"
            VALIDATION_FAILURES=$((VALIDATION_FAILURES + 1))
        fi
    done

    echo ""
    if [ "$VALIDATION_FAILURES" -eq 0 ]; then
        print_success "Validação concluída: todos os ${#VALIDATION_NAMES[@]} itens estão instalados!"
    else
        print_error "Validação concluída: $VALIDATION_FAILURES item(ns) não instalado(s)."
        print_warning "Corrija o erro acima e execute o script novamente; o que já foi instalado será mantido."
        exit 1
    fi
}

check_curl()      { command_exists curl; }
check_git()       { command_exists git; }
check_docker()    { command_exists docker && docker_compose_exists; }
check_node()      { command_exists node && [[ "$(node --version)" == v24* ]]; }
check_npm()       { command_exists npm; }
check_zsh()       { command_exists zsh; }
check_omz()       { [ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; }
check_zsh_login_shell() {
    local zsh_path current_shell
    zsh_path="$(command -v zsh 2>/dev/null)" || return 1
    current_shell="$(getent passwd "$(id -un)" | cut -d: -f7)"
    [ -n "$current_shell" ] && [ "$current_shell" = "$zsh_path" ]
}
check_diodon()    { package_installed diodon; }

# Somente Ubuntu LTS: releases de abril em ano par (20.04, 22.04, 24.04, 26.04...).
# Interinos como 25.04 e 25.10 caem fora automaticamente.
is_ubuntu_lts() {
    [ "${ID:-}" = "ubuntu" ] || return 1
    [[ "${VERSION_ID:-}" =~ ^[0-9]+\.04$ ]] || return 1
    local major="${VERSION_ID%%.*}"
    (( 10#$major % 2 == 0 ))
}

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

echo "🚀 Iniciando configuração completa do ambiente de desenvolvimento Ubuntu LTS..."
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
# 0. VERIFICAÇÃO DO SISTEMA OPERACIONAL (SOMENTE UBUNTU LTS)
# ====================================
print_status "Verificando distribuição..."
if [ ! -r /etc/os-release ]; then
    print_error "Não foi possível identificar o sistema operacional."
    exit 1
fi

# shellcheck disable=SC1091
. /etc/os-release

if [ "${ID:-}" != "ubuntu" ]; then
    print_error "Este script foi feito exclusivamente para Ubuntu LTS (nenhuma outra distribuição)."
    print_warning "Sistema detectado: ${PRETTY_NAME:-desconhecido}"
    print_warning "Linux Mint, Debian, Fedora e demais distros não são suportadas."
    exit 1
fi

if ! is_ubuntu_lts; then
    print_error "Esta versão do Ubuntu não é LTS (long term support)."
    print_warning "Sistema detectado: ${PRETTY_NAME:-desconhecido} (VERSION_ID=${VERSION_ID:-desconhecido})"
    print_warning "Atualize para a versão LTS mais recente antes de executar este script."
    exit 1
fi

print_success "Ubuntu LTS detectado! (${PRETTY_NAME})"
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
print_status "Verificando/Instalando dependências básicas..."
sudo apt install -y ca-certificates curl gnupg lsb-release software-properties-common
sudo add-apt-repository -y universe
register_validation "curl" check_curl
print_success "Dependências básicas instaladas!"

# ====================================
# 3. GIT
# ====================================
register_validation "Git" check_git
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
register_validation "Docker Engine + Compose" check_docker
print_status "Verificando/Instalando Docker Engine e Docker Compose..."
if ! check_docker; then
    # Remove versões antigas, se houver
    sudo apt remove -y docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc || true

    # Adiciona chave e repositório oficial Docker (repositório Ubuntu)
    sudo install -m 0755 -d /etc/apt/keyrings

    # Atualiza a chave sempre, evitando manter uma chave vazia, corrompida ou antiga.
    docker_key_tmp="$(mktemp)"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o "$docker_key_tmp"
    sudo install -m 0644 "$docker_key_tmp" /etc/apt/keyrings/docker.asc
    rm -f "$docker_key_tmp"

    # Codename do próprio Ubuntu LTS detectado (sem depender de outras distros).
    ubuntu_codename="${VERSION_CODENAME:-}"
    if [ -z "$ubuntu_codename" ] && command_exists lsb_release; then
        ubuntu_codename="$(lsb_release -cs)"
    fi

    if [ -z "$ubuntu_codename" ]; then
        print_error "Não foi possível detectar o codename do Ubuntu LTS."
        print_warning "A variável VERSION_CODENAME não existe em /etc/os-release e o lsb_release não está disponível."
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
register_validation "Node.js 24 LTS" check_node
register_validation "npm" check_npm
print_status "Verificando/Instalando Node.js 24..."
if ! check_node || ! command_exists npm; then
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
# 6. ZSH + OH MY ZSH (shell principal)
# ====================================
register_validation "Zsh" check_zsh
register_validation "Oh My Zsh" check_omz
register_validation "Zsh como shell padrão" check_zsh_login_shell

print_status "Verificando/Instalando Zsh..."
if ! command_exists zsh; then
    sudo apt install -y zsh
    hash -r
    if ! command_exists zsh; then
        print_error "O Zsh não ficou disponível após a instalação."
        exit 1
    fi
    print_success "Zsh instalado! ($(zsh --version))"
else
    print_success "Zsh já está instalado! ($(zsh --version))"
fi

print_status "Verificando/Instalando Oh My Zsh..."
if ! check_omz; then
    omz_installer_tmp="$(mktemp)"
    if ! curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o "$omz_installer_tmp"; then
        rm -f "$omz_installer_tmp"
        print_error "Falha ao baixar o instalador do Oh My Zsh."
        exit 1
    fi

    # --unattended: não pergunta nem troca o shell sozinho (fazemos abaixo).
    # --keep-zshrc: preserva um ~/.zshrc já existente em reexecuções.
    sh "$omz_installer_tmp" --unattended --keep-zshrc
    rm -f "$omz_installer_tmp"

    if ! check_omz; then
        print_error "Oh My Zsh não foi instalado em $HOME/.oh-my-zsh."
        exit 1
    fi
    print_success "Oh My Zsh instalado em $HOME/.oh-my-zsh!"
else
    print_success "Oh My Zsh já está instalado!"
fi

print_status "Definindo Zsh como shell padrão..."
zsh_path="$(command -v zsh)"
if check_zsh_login_shell; then
    print_success "Zsh já é o shell padrão de $(id -un)!"
elif ! grep -qxF "$zsh_path" /etc/shells; then
    print_error "O Zsh ($zsh_path) não está listado em /etc/shells; não é possível defini-lo como shell padrão."
    exit 1
else
    sudo chsh -s "$zsh_path" "$(id -un)"
    if check_zsh_login_shell; then
        print_success "Zsh definido como shell padrão ($zsh_path) para $(id -un)!"
    else
        print_error "Não foi possível definir o Zsh como shell padrão."
        exit 1
    fi
fi

# ====================================
# 7. GERENCIADOR DE ÁREA DE TRANSFERÊNCIA
# ====================================
register_validation "Diodon (clipboard)" check_diodon
print_status "Verificando ferramenta de clipboard..."
if package_installed diodon; then
    print_success "Diodon já está instalado!"
else
    print_warning "Instalando Diodon..."
    sudo apt install -y diodon
    print_success "Diodon instalado!"
fi

# ====================================
# 8. VALIDAÇÃO FINAL (item a item)
# ====================================
run_validations

# ====================================
# FINALIZAÇÃO
# ====================================
echo ""
echo "🎉 CONFIGURAÇÃO COMPLETA!"
echo ""
print_success "Todas as ferramentas foram instaladas e validadas com sucesso!"
echo ""
echo "🔄 Faça logout/login para aplicar as configurações do Docker (grupo docker)"
echo "🔄 Faça logout/login para entrar no seu novo shell padrão (zsh + Oh My Zsh)"
echo "🔧 VERSÕES INSTALADAS:"
if command_exists git;    then echo "   Git:        $(git --version)"; fi
if command_exists curl;   then echo "   Curl:       $(curl --version | head -n1)"; fi
if command_exists docker; then echo "   Docker:     $(docker --version)"; fi
if command_exists node;   then echo "   Node.js:    $(node --version)"; fi
if command_exists npm;    then echo "   NPM:        $(npm --version)"; fi
if command_exists zsh;    then echo "   Zsh:        $(zsh --version)"; fi
if check_omz;             then echo "   Oh My Zsh:  $(git -C "$HOME/.oh-my-zsh" describe --tags 2>/dev/null || echo 'instalado')"; fi
if package_installed diodon; then echo "   Diodon:     $(diodon --version 2>/dev/null || echo instalado)"; fi
echo "   Shell:      $(getent passwd "$(id -un)" | cut -d: -f7)"
echo ""
print_success "Ambiente de desenvolvimento pronto para uso! 🚀"
