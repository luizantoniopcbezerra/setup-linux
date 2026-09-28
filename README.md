# setup-linux

[![Shell](https://img.shields.io/badge/Shell-Bash-89e051)]()
[![Linux](https://img.shields.io/badge/Linux-Ubuntu%20LTS-E95420)]()
[![License](https://img.shields.io/badge/License-MIT-green)]()

Script para configuração automatizada de ambiente de desenvolvimento no **Ubuntu LTS**.

## Compatibilidade

Distribuição suportada:

- **Ubuntu LTS somente** (o script verifica `/etc/os-release`, exige `ID=ubuntu` e uma versão LTS — ano par com `.04`, como 24.04 e 26.04 — e recusa rodar em qualquer outra distribuição ou em versões não LTS)

Nenhuma outra distro é aceita: **Linux Mint, Debian, Fedora** etc. são recusados com uma mensagem explicando o motivo.

O script utiliza `apt` e resolve o codename do Ubuntu diretamente de `VERSION_CODENAME` em `/etc/os-release` (com fallback para `lsb_release -cs`), portanto os repositórios de terceiros (Docker, NodeSource) sempre apontam para a sua versão LTS.

---

## Instalações realizadas

### Dependências base

- **ca-certificates**, **gnupg**, **lsb-release**, **software-properties-common** - suporte aos repositórios
- **curl** - para downloads e APIs
- Habilita o repositório `universe`

### Git

- **git** - controle de versão
- Configuração interativa de `user.name` e `user.email`

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

### Node.js 24 LTS (NodeSource)

Instala via NodeSource:

- `node` (v24.x LTS)
- `npm` (incluído)

### Zsh + Oh My Zsh (shell principal)

- **zsh** - instalado via `apt`
- **Oh My Zsh** - instalado via instalador oficial em `~/.oh-my-zsh` (modo `--unattended --keep-zshrc`, preservando um `~/.zshrc` já existente)
- **Shell padrão** - o login do usuário é alterado para `zsh` (`chsh`), tornando-o o shell principal

### Diodon

Gerenciador de área de transferência (clipboard manager) do repositório `universe`:

- `diodon` - interface GTK + indicador de painel

---

## Validação item a item

Cada programa da lista registra a própria validação (função que prova que ele está instalado) e, ao final, o script faz a conferência completa:

```text
🔧 Validando item a item se cada programa está instalado...

✅ curl                           INSTALADO
✅ Git                            INSTALADO
✅ Docker Engine + Compose        INSTALADO
✅ Node.js 24 LTS                INSTALADO
✅ npm                            INSTALADO
✅ Zsh                            INSTALADO
✅ Oh My Zsh                      INSTALADO
✅ Zsh como shell padrão          INSTALADO
✅ Diodon (clipboard)             INSTALADO

✅ Validação concluída: todos os 9 itens estão instalados!
```

- **Todos OK**: o script termina com código `0`
- **Falta algum item**: é listado como `NÃO INSTALADO` e o script termina com código `1` (útil em automação/CI)

O que é validado:

| Item | Critério |
| --- | --- |
| curl | comando `curl` disponível |
| Git | comando `git` disponível |
| Docker | comando `docker` + `docker compose version` |
| Node.js 24 LTS | `node` presente e versão `v24.x` |
| npm | comando `npm` disponível |
| Zsh | comando `zsh` disponível |
| Oh My Zsh | `~/.oh-my-zsh/oh-my-zsh.sh` existe |
| Shell padrão | shell de login do usuário em `/etc/passwd` aponta para o `zsh` |
| Diodon | pacote `diodon` instalado (`dpkg`) |

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

1. **Shell**: Faça **logout/login** para entrar no novo shell principal (**zsh + Oh My Zsh**)
2. **Docker**: Faça **logout/login** (ou reinicie) para usar Docker sem `sudo`
3. **Diodon**: Configure o atalho de teclado (Ubuntu/GNOME):
   - Vá em: *Configurações > Teclado > Atalhos > Atalhos personalizados*
   - Nome: `Diodon`
   - Comando: `/usr/bin/diodon`
   - Atalho: `Super + V` (tecla Windows + V)

---

## Verificação das versões

Ao final, o script exibe as versões instaladas e o shell padrão:

```text
Git:        git version 2.x.x
Curl:       curl 8.x.x
Docker:     Docker version 29.x.x
Node.js:    v24.x.x
NPM:        10.x.x
Zsh:        zsh 5.x.x
Oh My Zsh:  master
Diodon:     1.13.0
Shell:      /usr/bin/zsh
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
