# setup-linux

[![Shell](https://img.shields.io/badge/Shell-Bash-89e051)]()
[![Linux](https://img.shields.io/badge/Linux-Mint-87CF3E)]()
[![License](https://img.shields.io/badge/License-MIT-green)]()

Script para configuração automatizada de ambiente de desenvolvimento no **Linux Mint**.

## Compatibilidade

Distribuição suportada:

- **Linux Mint** (o script verifica `/etc/os-release` e recusa rodar em outra distribuição)

O script utiliza `apt` e resolve automaticamente o codename Ubuntu subjacente (via `UBUNTU_CODENAME` em `/etc/os-release`, com fallback para `lsb_release -cs`) para configurar os repositórios de terceiros (Docker, Adoptium), portanto **não é compatível com Fedora** ou outras distribuições não baseadas em Ubuntu/Debian.

---

## Instalações realizadas

### Dependências base

- **curl** - para downloads e APIs
- **git** - controle de versão

### Docker

Instala o Docker Engine completo via repositório oficial:

- `docker-ce` (Docker Engine)
- `docker-ce-cli` (CLI)
- `containerd.io` (container runtime)
- `docker-buildx-plugin` (Buildx)
- `docker-compose-plugin` (Docker Compose v2)

Também:
- Habilita e inicia o serviço Docker
- Adiciona o usuário ao grupo `docker` (requer logout/login para efeito)

### Node.js 24 LTS (Krypton)

Instala via NodeSource:
- `node` (v24.x LTS)
- `npm` (incluído)

### Java 21 LTS (Eclipse Temurin)

Instala via repositório Adoptium:
- `temurin-21-jdk` (JDK 21 LTS)

### Maven

Instala via repositório Ubuntu:
- `maven` (build tool para projetos Java)

### Diodon

Gerenciador de área de transferência (clipboard manager):
- `diodon` - interface GTK + indicador de painel

---

## Execução

### Clone o repositório

```bash
git clone https://github.com/bezerraluiz/setup-linux.git
```

### Entre na pasta

```bash
cd setup-linux
```

### Permissão de execução

```bash
chmod +x setup-linux.sh
```

### Execute o script

```bash
./setup-linux.sh
```

> **Nota:** O script deve ser executado como usuário comum (não root), pois usa `sudo` internamente quando necessário.

---

## Configuração do Git

Durante a execução, serão solicitados interativamente:

```text
Digite seu nome de usuário Git:
Digite seu email Git:
```

As informações serão configuradas globalmente:

```bash
git config --global user.name "Seu Nome"
git config --global user.email "seu.email@exemplo.com"
```

Se deixados em branco, configure manualmente depois:

```bash
git config --global user.name 'Seu Nome'
git config --global user.email 'seu.email@exemplo.com'
```

---

## Pós-instalação

Após a execução completa:

1. **Docker**: Faça **logout/login** (ou reinicie) para usar Docker sem `sudo`
2. **Diodon**: Configure o atalho de teclado:
   - Vá em: *Configurações > Teclado > Atalhos > Atalhos personalizados*
   - Nome: `Diodon`
   - Comando: `/usr/bin/diodon`
   - Atalho: `Super + V` (tecla Windows + V)

---

## Verificação das versões

Ao final, o script exibe as versões instaladas:

```text
Git:     git version 2.x.x
Curl:    curl 8.x.x
Docker:  Docker version 27.x.x
Node.js: v24.x.x
NPM:     10.x.x
Java:    openjdk version "21.x.x" (Eclipse Temurin)
Maven:   Apache Maven 3.x.x
```

---

## Estrutura do repositório

```text
setup-linux/
├── LICENSE
├── README.md
└── setup-linux.sh
```

---

## Licença

MIT © [Luiz Bezerra](https://github.com/bezerraluiz)