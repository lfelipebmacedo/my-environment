# bootstrap-dev

Provisiona uma máquina de desenvolvimento **Ubuntu/Debian** (bare metal) do zero
via Ansible.

## Pré-requisitos

```bash
sudo apt install ansible make
```

> `make` é necessário para usar o Makefile. O Ansible instala o restante.

## Uso

```bash
# instalar dependências e rodar tudo
make

# ou manualmente
cd bootstrap
ansible-playbook playbook.yml --ask-become-pass
```

Rode como seu usuário normal (**não** use `sudo`). O `--ask-become-pass` faz com
que o Ansible peça elevação apenas nos passos que realmente precisam (instalação
de pacotes, repositórios, etc.).

### Comandos via Makefile

| Comando | Descrição |
|---------|-----------|
| `make` | roda o playbook completo |
| `make check` | syntax check do playbook |
| `make dry-run` | simula sem instalar nada |
| `make lint` | roda ansible-lint |
| `make roles` | lista as roles disponíveis |
| `make vars` | mostra `vars/main.yml` |
| `make <role>` | instala só uma role (ex: `make docker`, `make kubectl`) |
| `make start-at TASK="..."` | começa a partir de uma task específica |

## O que é instalado

| Role              | O que instala                | Método                          |
|-------------------|------------------------------|---------------------------------|
| `base`            | git, curl, wget, gnupg, etc.  | apt                             |
| `gh`              | GitHub CLI (`gh`)             | repositório apt oficial         |
| `warp`            | Warp Terminal                | repositório apt oficial         |
| `firefox`         | Firefox                      | repositório apt da Mozilla      |
| `docker`          | Docker Engine + Compose      | repositório apt oficial         |
| `vscode`          | Visual Studio Code           | repositório apt da Microsoft    |
| `obsidian`        | Obsidian                     | `.deb` do GitHub releases       |
| `obsidian-backup` | Backup diário do Obsidian p/ Google Drive | rclone + cron                |
| `intellij_toolbox`| JetBrains Toolbox App        | tarball da API JetBrains        |
| `okular`          | Okular (leitor de PDFs)     | apt                             |
| `kubectl`         | kubectl                      | repositório apt `pkgs.k8s.io`   |
| `kind`            | kind                         | binário do GitHub releases      |
| `k9s`             | k9s                          | tarball do GitHub releases      |
| `nvm`             | NVM + Node.js                | script oficial + NVM            |
| `sdkman`          | SDKMAN                       | script oficial                  |

## Configuração

Edite `bootstrap/vars/main.yml` para ajustar versões e comportamentos:

```yaml
node_version: "lts"             # "lts" | "22" | "20.11.0"
nvm_version: "latest"           # "latest" | "v0.40.3"
docker_version: "latest"        # "latest" | "5:27.3.1-1~ubuntu.24.04~noble"

# Backup do Obsidian (rclone + Google Drive)
obsidian_vault_path: "~/Obsidian/Notebook"
obsidian_backup_remote: "gdrive:obsidian-backup"
obsidian_backup_cron_hour: "2"         # hora do backup (0-23)
obsidian_backup_cron_minute: "0"       # minuto do backup

remove_firefox_snap: false      # true = remove o Firefox Snap antes de instalar
```

Para fixar uma versão específica do Docker, liste as disponíveis com:

```bash
apt list --all-versions docker-ce
```

## Rodar apenas uma role

```bash
make docker        # instala só o Docker
make kubectl       # instala só o kubectl
make nvm           # instala só o NVM + Node.js
```

Para começar a partir de uma task específica (ex: pular tasks já executadas):

```bash
make start-at TASK="firefox : garantir que o snap do firefox não está instalado"
```

## Após a instalação

- **Docker sem sudo**: faça logout/login (ou `newgrp docker`), depois: `docker run hello-world`
- **Node/NVM**: abra um novo terminal e rode `node -v`
- **SDKMAN**: abra um novo terminal e rode `sdk version`
- **JetBrains Toolbox**: execute `~/.local/share/JetBrains/Toolbox/bin/jetbrains-toolbox`
- **kubectl**: `kubectl version --client`
- **kind**: `kind create cluster`
- **k9s**: `k9s` (conecte-se a um cluster primeiro)
- **Warp, Firefox, VSCode, Obsidian**: já aparecem no menu de aplicativos
- **Obsidian backup**: configure o rclone (`rclone config`), depois rode `make obsidian-backup`

## Backup do Obsidian (obsidian-backup)

A role `obsidian-backup` configura backup diário automático do seu vault
Obsidian para o Google Drive usando **rclone** + **cron**.

### Pré-requisito

Antes de rodar a role, configure o rclone com sua conta Google:

```bash
rclone config
```

- `n` → new remote
- Nome: `gdrive`
- Tipo: `drive`
- Deixe client_id e client_secret em branco (usa os defaults do rclone)
- Scope: `1` (full access)
- Demais opções: aperte Enter
- `y` para auto config (abre o navegador para autenticar)

### Configuração

Edite `bootstrap/vars/main.yml` para ajustar o vault e horário:

```yaml
obsidian_vault_path: "~/Obsidian/Notebook"   # caminho do vault
obsidian_backup_remote: "gdrive:obsidian-backup"  # destino no Google Drive
obsidian_backup_cron_hour: "2"              # hora da execução (0-23)
obsidian_backup_cron_minute: "0"            # minuto da execução
```

### Uso

```bash
# Instalar rclone + script + cron
make obsidian-backup

# Executar o backup manualmente
~/backup-obsidian.sh

# Ver log
cat ~/backup-obsidian.log
```

O cron roda diariamente. O script usa `rclone sync`, mantendo o Google Drive
como espelho do vault local (arquivos deletados localmente são removidos do backup).

## Estrutura

```
├── Makefile                # comandos rápidos (make, make docker, make check, ...)
└── bootstrap/
    ├── ansible.cfg         # configuração do Ansible
    ├── inventory.ini       # localhost com conexão local
    ├── playbook.yml        # orquestrador principal
    ├── vars/main.yml       # versões e flags (single source of truth)
    └── roles/
        ├── base/            ├── firefox/        ├── intellij_toolbox/
        ├── warp/            ├── docker/         ├── kubectl/
                             ├── vscode/         ├── kind/
                             ├── obsidian/       ├── k9s/
                             ├── obsidian-backup/├── nvm/
                                                 └── sdkman/
```

Cada role segue a convenção `roles/<nome>/tasks/main.yml`. O Docker tem também
`handlers/main.yml` para habilitar o serviço após a instalação.
