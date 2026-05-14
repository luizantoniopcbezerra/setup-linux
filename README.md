# setup-linux

[![Shell](https://img.shields.io/badge/Shell-Bash-89e051)]()
[![Linux](https://img.shields.io/badge/Linux-Fedora%20%7C%20Ubuntu-blue)]()
[![License](https://img.shields.io/badge/License-MIT-green)]()

Script para configuração automatizada de ambiente de desenvolvimento Linux.

## Compatibilidade

Distribuições suportadas atualmente:

- Fedora
- Ubuntu

O script detecta automaticamente a distribuição utilizando:

```bash
/etc/os-release
```

---

## Instalações realizadas

### Dependências base

- curl
- wget
- git
- zsh
- ca-certificates

### Docker

Instala:

- docker-ce
- docker compose
- buildx
- containerd

Também:

- habilita o serviço
- adiciona o usuário ao grupo docker

### Node.js

Instala:

- node
- npm

### Java 21

Instala OpenJDK 21.

### Maven

Instala Maven para projetos Java.

### Fastfetch

Ferramenta de informações do sistema.

### Diodon

Gerenciador de clipboard.

### Zed

Instala automaticamente o editor Zed.

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

---

## Configuração do Git

Durante a execução serão solicitados:

```text
Nome Git:
Email Git:
```

As informações serão configuradas globalmente:

```bash
git config --global user.name
git config --global user.email
```

---

## Pós-instalação

Após instalação do Docker:

```text
Faça logout/login para usar Docker sem sudo
```

---

## Estrutura

```text
setup-linux/
├── LICENSE
├── README.md
└── setup-linux.sh
```

---

## Licença

MIT
