# bootstrap

Playbook Ansible para configurar uma máquina de desenvolvimento Debian/Ubuntu do zero.

## Pré-requisitos

```bash
sudo apt install ansible
```

## Como usar

```bash
ansible-playbook playbook.yml --ask-become-pass
```

O `--ask-become-pass` é necessário para os passos que precisam de sudo (instalação de pacotes, repositórios, etc.).

## O que é instalado

| Role | O que instala | Método |
|---|---|---|
| `base` | curl, wget, gnupg, apt-transport-https | apt |
| `warp` | Warp Terminal | repositório apt oficial |
| `firefox` | Firefox | repositório apt da Mozilla (sem Snap) |
| `docker` | Docker Engine + Compose plugin | repositório apt oficial |
| `vscode` | Visual Studio Code | repositório apt da Microsoft |
| `obsidian` | Obsidian | `.deb` do GitHub releases |
| `intellij_toolbox` | JetBrains Toolbox App | tarball da API JetBrains |
| `kubectl` | kubectl | repositório apt `pkgs.k8s.io` |
| `kind` | kind | binário do GitHub releases |
| `k9s` | k9s | tarball do GitHub releases |
| `nvm` | NVM + Node.js | script oficial + NVM |
| `sdkman` | SDKMAN | script oficial |

## Configuração

Edite `vars/main.yml` para ajustar versões ou comportamentos:

```yaml
node_version: "lts"        # "lts" | "22" | "20.11.0"
nvm_version: "latest"      # "latest" | "v0.40.3"
docker_version: "latest"   # "latest" | "5:27.3.1-1~ubuntu.24.04~noble"

remove_firefox_snap: false  # true = remove o Firefox Snap antes de instalar o .deb
```

Para fixar a versão do Docker, liste as disponíveis com:

```bash
apt list --all-versions docker-ce
```

## Rodar apenas uma role

```bash
ansible-playbook playbook.yml --ask-become-pass --tags kubectl
```

> As roles não têm tags por padrão — adicione `tags:` nas roles do `playbook.yml` conforme necessário, ou use `--start-at-task` para pular até uma task específica.

Alternativamente, comente as roles que não quer rodar em `playbook.yml`.

## Após a instalação

- **Docker sem sudo**: faça logout/login (ou `newgrp docker`), depois: `docker run hello-world`
- **Node/NVM**: abra um novo terminal e rode: `node -v`
- **SDKMAN**: abra um novo terminal e rode: `sdk version`
- **JetBrains Toolbox**: execute `~/.local/share/JetBrains/Toolbox/bin/jetbrains-toolbox`
- **kubectl**: `kubectl version --client`
- **kind**: `kind create cluster`
- **k9s**: `k9s` (conecte a um cluster primeiro)

## Estrutura

```
bootstrap/
├── ansible.cfg          # configuração do Ansible (inventory, roles_path)
├── inventory.ini        # localhost com conexão local
├── playbook.yml         # orquestrador principal
├── vars/
│   └── main.yml         # versões e flags (single source of truth)
└── roles/
    ├── base/
    ├── warp/
    ├── firefox/
    ├── docker/
    ├── vscode/
    ├── obsidian/
    ├── intellij_toolbox/
    ├── kubectl/
    ├── kind/
    ├── k9s/
    ├── nvm/
    └── sdkman/
```

Cada role segue a convenção `roles/<nome>/tasks/main.yml`. O Docker tem também `handlers/main.yml` para habilitar o serviço após a instalação.
