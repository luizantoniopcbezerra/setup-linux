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
    ImageMagick

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
# 9 — ZED EDITOR
# =========================================================

print_status "Instalando Zed..."

if ! command_exists zed; then
    curl -f https://zed.dev/install.sh | sh
    print_success "Zed instalado"
else
    print_success "Zed já instalado"
fi

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

if command_exists zed; then
    zed --version || true
fi

echo ""
print_warning "Faça logout/login para aplicar o grupo docker"
