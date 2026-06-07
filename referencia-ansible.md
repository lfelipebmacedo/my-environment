# Referência Ansible — my-environment

Documento de referência dos módulos, keywords, filtros e comandos Ansible utilizados neste projeto, com links para a documentação oficial.

---

## 1. Módulos

### Visão geral

| Módulo | Documentação oficial |
|--------|----------------------|
| `ansible.builtin.apt` | [docs.ansible.com/.../apt_module.html](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/apt_module.html) |
| `ansible.builtin.apt_repository` | [docs.ansible.com/.../apt_repository_module.html](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/apt_repository_module.html) |
| `ansible.builtin.shell` | [docs.ansible.com/.../shell_module.html](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/shell_module.html) |
| `ansible.builtin.command` | [docs.ansible.com/.../command_module.html](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/command_module.html) |
| `ansible.builtin.uri` | [docs.ansible.com/.../uri_module.html](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/uri_module.html) |
| `ansible.builtin.get_url` | [docs.ansible.com/.../get_url_module.html](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/get_url_module.html) |
| `ansible.builtin.unarchive` | [docs.ansible.com/.../unarchive_module.html](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/unarchive_module.html) |
| `ansible.builtin.stat` | [docs.ansible.com/.../stat_module.html](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/stat_module.html) |
| `ansible.builtin.file` | [docs.ansible.com/.../file_module.html](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/file_module.html) |
| `ansible.builtin.copy` | [docs.ansible.com/.../copy_module.html](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/copy_module.html) |
| `ansible.builtin.systemd` | [docs.ansible.com/.../systemd_service_module.html](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/systemd_service_module.html) |
| `ansible.builtin.group` | [docs.ansible.com/.../group_module.html](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/group_module.html) |
| `ansible.builtin.user` | [docs.ansible.com/.../user_module.html](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/user_module.html) |
| `ansible.builtin.assert` | [docs.ansible.com/.../assert_module.html](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/assert_module.html) |
| `ansible.builtin.set_fact` | [docs.ansible.com/.../set_fact_module.html](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/set_fact_module.html) |
| `ansible.builtin.debug` | [docs.ansible.com/.../debug_module.html](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/debug_module.html) |

---

### `apt` — Gerenciamento de pacotes Debian/Ubuntu

Instala, remove ou atualiza pacotes `.deb`.

**Exemplo do projeto** (`roles/base/tasks/main.yml`):

```yaml
- name: Instalar pacotes base
  become: true
  ansible.builtin.apt:
    name:
      - ca-certificates
      - curl
      - wget
      - gnupg
      - apt-transport-https
      - zip
      - unzip
    state: present
    update_cache: true
```

**Exemplo com `.deb` local** (`roles/obsidian/tasks/main.yml`):

```yaml
- name: Instalar Obsidian
  become: true
  ansible.builtin.apt:
    deb: /tmp/obsidian.deb
    state: present
```

**Parâmetros usados no projeto:** `name`, `state`, `update_cache`, `deb`, `ignore_errors`

---

### `apt_repository` — Repositórios APT

Adiciona ou remove repositórios APT (arquivos `.list` em `/etc/apt/sources.list.d/`).

**Exemplo do projeto** (`roles/docker/tasks/main.yml`):

```yaml
- name: Adicionar repositório Docker
  become: true
  ansible.builtin.apt_repository:
    repo: "deb [arch={{ dpkg_arch }} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/{{ ansible_distribution | lower }} {{ ansible_distribution_release }} stable"
    state: present
    filename: docker
```

**Parâmetros usados no projeto:** `repo`, `state`, `filename`

---

### `shell` — Execução de comandos via shell

Executa comandos com pipe (`|`), redirecionamento e expansão do shell. Prefira `command` quando não precisar dessas funcionalidades.

**Exemplo do projeto** (`roles/warp/tasks/main.yml`):

```yaml
- name: Adicionar chave GPG do Warp
  become: true
  ansible.builtin.shell: |
    curl -fsSL https://releases.warp.dev/linux/keys/warp.asc | \
    gpg --dearmor -o /etc/apt/keyrings/warp.gpg
  args:
    creates: /etc/apt/keyrings/warp.gpg
```

**Exemplo com `register` + `changed_when`** (`roles/nvm/tasks/main.yml`):

```yaml
- name: Instalar NVM
  ansible.builtin.shell: |
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/{{ nvm_tag }}/install.sh | bash
  args:
    creates: "{{ ansible_env.HOME }}/.nvm/nvm.sh"
    executable: /bin/bash
```

**Parâmetros usados no projeto:** `args: creates`, `args: executable`, `register`, `changed_when`

---

### `command` — Execução de comandos

Executa comandos sem interpretação do shell (sem pipes ou redirecionamentos). É o módulo mais seguro para comandos simples.

**Exemplo do projeto** (`roles/warp/tasks/main.yml`):

```yaml
- name: Verificar se Warp está instalado
  ansible.builtin.command: which warp-terminal
  register: warp_check
  failed_when: false
  changed_when: false
```

**Comportamento padrão:** o módulo falha se o comando retornar código não-zero. Use `failed_when: false` para comandos de verificação onde código de saída 1 é esperado (ex: `which` não encontra o binário).

**Parâmetros usados no projeto:** `register`, `failed_when`, `changed_when`

---

### `uri` — Requisições HTTP

Interage com endpoints HTTP/HTTPS, útil para consultar APIs REST (ex: GitHub API, endpoints de versão).

**Exemplo do projeto** (`roles/obsidian/tasks/main.yml`):

```yaml
- name: Obter última release do Obsidian
  ansible.builtin.uri:
    url: https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest
    headers:
      Accept: application/vnd.github+json
    return_content: true
  register: obsidian_release
  failed_when: false
```

**Exemplo com Kubernetes** (`roles/kubectl/tasks/main.yml`):

```yaml
- name: Buscar versão estável do Kubernetes
  ansible.builtin.uri:
    url: https://dl.k8s.io/release/stable.txt
    return_content: true
  register: k8s_stable
```

**Parâmetros usados no projeto:** `url`, `headers`, `return_content`, `register`, `failed_when`

---

### `get_url` — Download de arquivos

Baixa arquivos da internet para o sistema de arquivos local.

**Exemplo do projeto** (`roles/obsidian/tasks/main.yml`):

```yaml
- name: Baixar pacote .deb do Obsidian
  ansible.builtin.get_url:
    url: "https://github.com/obsidianmd/obsidian-releases/releases/download/{{ obsidian_tag }}/obsidian_{{ obsidian_tag | regex_replace('^v', '') }}_amd64.deb"
    dest: /tmp/obsidian.deb
    mode: '0644'
```

**Exemplo com binário** (`roles/kind/tasks/main.yml`):

```yaml
- name: Baixar kind
  ansible.builtin.get_url:
    url: "https://github.com/kubernetes-sigs/kind/releases/download/{{ kind_tag }}/kind-linux-{{ dpkg_arch }}"
    dest: /usr/local/bin/kind
    mode: '0755'
```

**Parâmetros usados no projeto:** `url`, `dest`, `mode`

---

### `unarchive` — Extração de arquivos compactados

Extrai arquivos `.tar.gz`, `.tar.bz2`, `.zip` etc., localmente ou a partir de URL remota.

**Exemplo do projeto** (`roles/intellij_toolbox/tasks/main.yml`):

```yaml
- name: Baixar e extrair JetBrains Toolbox
  ansible.builtin.unarchive:
    src: "{{ toolbox_url }}"
    dest: /opt/jetbrains-toolbox
    remote_src: true
    extra_opts:
      - --strip-components=1
    creates: /opt/jetbrains-toolbox/jetbrains-toolbox
```

**Exemplo com tarball** (`roles/k9s/tasks/main.yml`):

```yaml
- name: Baixar e extrair k9s
  become: true
  ansible.builtin.unarchive:
    src: "https://github.com/derailed/k9s/releases/download/{{ k9s_tag }}/k9s_Linux_{{ dpkg_arch }}.tar.gz"
    dest: /usr/local/bin
    remote_src: true
    include:
      - k9s
    mode: '0755'
```

**Parâmetros usados no projeto:** `src`, `dest`, `remote_src`, `extra_opts`, `creates`, `include`, `mode`

---

### `stat` — Verificação de arquivos/diretórios

Obtém informações sobre arquivos ou diretórios (existência, permissões, tamanho etc.). Usado como guarda condicional.

**Exemplo do projeto** (`playbook.yml`):

```yaml
- name: Verificar se /etc/apt/keyrings existe
  ansible.builtin.stat:
    path: /etc/apt/keyrings
  register: keyrings_stat
```

**Exemplo em role** (`roles/nvm/tasks/main.yml`):

```yaml
- name: Verificar se NVM está instalado
  ansible.builtin.stat:
    path: "{{ ansible_env.HOME }}/.nvm/nvm.sh"
  register: nvm_stat
```

**Parâmetros usados no projeto:** `path`, `register`

---

### `file` — Gerenciamento de arquivos e diretórios

Cria, remove diretórios, arquivos ou links simbólicos; define permissões.

**Exemplo do projeto** (`playbook.yml`):

```yaml
- name: Criar diretório /etc/apt/keyrings
  become: true
  ansible.builtin.file:
    path: /etc/apt/keyrings
    state: directory
    mode: '0755'
  when: not keyrings_stat.stat.exists
```

**Exemplo de remoção** (`roles/obsidian/tasks/main.yml`):

```yaml
- name: Remover .deb temporário
  ansible.builtin.file:
    path: /tmp/obsidian.deb
    state: absent
```

**Parâmetros usados no projeto:** `path`, `state`, `mode`

---

### `copy` — Cópia de arquivos e conteúdo inline

Copia arquivos ou escreve conteúdo inline em arquivos no host alvo.

**Exemplo com conteúdo inline** (`roles/firefox/tasks/main.yml`):

```yaml
- name: Criar arquivo de preferências do APT para Firefox
  become: true
  ansible.builtin.copy:
    dest: /etc/apt/preferences.d/mozilla
    content: |
      Package: *
      Pin: origin packages.mozilla.org
      Pin-Priority: 1000
    mode: '0644'
```

**Exemplo com cópia de arquivo** (`bootstrap/roles/intellij_toolbox/tasks/main.yml`):

```yaml
- name: Mover binário do JetBrains Toolbox
  become: true
  ansible.builtin.copy:
    src: /tmp/jetbrains-toolbox
    dest: /usr/local/bin/jetbrains-toolbox
    remote_src: true
    mode: '0755'
```

**Parâmetros usados no projeto:** `dest`, `content`, `mode`, `src`, `remote_src`

---

### `systemd` — Gerenciamento de serviços

Gerencia serviços do systemd (start, stop, enable, disable, restart).

**Exemplo do projeto** (`roles/docker/handlers/main.yml`):

```yaml
- name: Habilitar e iniciar Docker
  become: true
  ansible.builtin.systemd:
    name: docker
    enabled: true
    state: started
```

> Documentação: o módulo chama-se `systemd_service` desde Ansible 2.11, mas o nome `systemd` permanece como alias compatível.

**Parâmetros usados no projeto:** `name`, `enabled`, `state`

---

### `group` — Grupos Unix

Cria ou remove grupos de usuários Unix.

**Exemplo do projeto** (`roles/docker/tasks/main.yml`):

```yaml
- name: Garantir que o grupo docker existe
  become: true
  ansible.builtin.group:
    name: docker
    state: present
```

**Parâmetros usados no projeto:** `name`, `state`

---

### `user` — Usuários Unix

Gerencia contas de usuário e suas propriedades (grupos, shell, home etc.).

**Exemplo do projeto** (`roles/docker/tasks/main.yml`):

```yaml
- name: Adicionar usuário ao grupo docker
  become: true
  ansible.builtin.user:
    name: "{{ ansible_user_id }}"
    groups: docker
    append: true
```

**Parâmetros usados no projeto:** `name`, `groups`, `append`

---

### `assert` — Validação de condições

Falha a execução se uma condição não for satisfeita. Usado como guarda no início do playbook.

**Exemplo do projeto** (`playbook.yml`):

```yaml
- name: Validar sistema operacional
  ansible.builtin.assert:
    that:
      - ansible_distribution in ['Ubuntu', 'Debian']
    fail_msg: "Este playbook só suporta Ubuntu e Debian."
```

**Parâmetros usados no projeto:** `that`, `fail_msg`

---

### `set_fact` — Definição dinâmica de variáveis

Define ou modifica variáveis durante a execução do playbook.

**Exemplo do projeto** (`playbook.yml`):

```yaml
- name: Definir arquitetura dpkg
  ansible.builtin.set_fact:
    dpkg_arch: "{{ 'amd64' if ansible_architecture == 'x86_64' else ansible_architecture }}"
```

**Exemplo com fallback** (`roles/obsidian/tasks/main.yml`):

```yaml
- name: Definir tag do Obsidian
  ansible.builtin.set_fact:
    obsidian_tag: "{{ obsidian_release.json.tag_name | default(obsidian_version) }}"
```

**Parâmetros usados no projeto:** variáveis definidas via `key: value`

---

### `debug` — Mensagens de saída

Exibe mensagens ou valores de variáveis durante a execução.

**Exemplo do projeto** (`playbook.yml`):

```yaml
- name: Mensagem de conclusão
  ansible.builtin.debug:
    msg: "Playbook concluído"
```

**Parâmetros usados no projeto:** `msg`

---

## 2. Keywords de Playbook

| Keyword | Descrição | Doc oficial |
|---------|-----------|-------------|
| `name` | Nome descritivo do play/task | [Playbook Keywords](https://docs.ansible.com/ansible/latest/reference_appendices/playbooks_keywords.html) |
| `hosts` | Grupo(s) de hosts alvo | idem |
| `become` | Escalar privilégio (sudo) | [Understanding privilege escalation](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_privilege_escalation.html) |
| `vars_files` | Carregar variáveis de arquivo externo | [Playbook Keywords](https://docs.ansible.com/ansible/latest/reference_appendices/playbooks_keywords.html) |
| `pre_tasks` | Tarefas executadas antes das roles | idem |
| `roles` | Lista de roles executadas no play | [Roles](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse_roles.html) |
| `post_tasks` | Tarefas executadas após as roles | [Playbook Keywords](https://docs.ansible.com/ansible/latest/reference_appendices/playbooks_keywords.html) |
| `register` | Armazena o resultado de uma task | [Registering variables](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_variables.html#registering-variables) |
| `when` | Execução condicional de tasks | [Conditionals](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_conditionals.html) |
| `notify` | Dispara handlers | [Handlers](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_handlers.html) |
| `failed_when` | Sobrescreve condição de falha | [Error handling](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_error_handling.html) |
| `changed_when` | Sobrescreve indicação de mudança | idem |
| `ignore_errors` | Continua execução mesmo se a task falhar | idem |
| `args` | Parâmetros extras do módulo (ex: `creates`, `executable`) | [Passing arguments](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_templating.html) |

---

## 3. Filtros Jinja2

| Filtro | Exemplo do projeto | Doc oficial |
|--------|--------------------|-------------|
| `\| lower` | `ansible_distribution \| lower` | [Jinja2 filters](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_filters.html#standard-filters) |
| `\| default()` | `obsidian_release.json.tag_name \| default(obsidian_version)` | [default filter](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/default_filter.html) |
| `\| regex_replace()` | `obsidian_tag \| regex_replace('^v', '')` | [regex_replace](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/regex_replace_filter.html) |
| `\| regex_search()` | `toolbox_response.content \| regex_search('https://download.jetbrains.com/toolbox.*\\.tar\\.gz')` | [regex_search](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/regex_search_filter.html) |
| `\| trim` | `k8s_stable.content \| trim` | [trim filter](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/trim_filter.html) |
| `\| bool` | `remove_firefox_snap \| bool` | [type casting filters](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_filters.html#type-casting-filters) |

---

## 4. Ferramentas CLI

### `ansible-playbook`

| Uso (do Makefile) | Doc oficial |
|-------------------|-------------|
| `ansible-playbook playbook.yml --ask-become-pass` | [ansible-playbook](https://docs.ansible.com/ansible/latest/cli/ansible-playbook.html) |
| `ansible-playbook playbook.yml --syntax-check` | Valida sintaxe YAML sem executar (idem) |
| `ansible-playbook playbook.yml --check` | Modo dry-run / check (idem) |
| `ansible-playbook playbook.yml --tags <tag>` | Executa apenas tasks com a tag especificada (idem) |
| `ansible-playbook playbook.yml --start-at-task="TASK"` | Retoma execução a partir de uma task específica (idem) |

### `ansible-lint`

| Uso (do Makefile) | Doc oficial |
|-------------------|-------------|
| `ansible-lint playbook.yml roles/` | [ansible-lint](https://ansible.readthedocs.io/projects/lint/) |

---

## 5. Diretivas de Configuração (`ansible.cfg`)

| Seção | Diretiva | Valor | Doc oficial |
|-------|----------|-------|-------------|
| `[defaults]` | `inventory` | Caminho do inventário | [ANSIBLE_INVENTORY](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#default-inventory) |
| `[defaults]` | `roles_path` | Caminho das roles | [DEFAULT_ROLES_PATH](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#default-roles-path) |
| `[defaults]` | `host_key_checking` | `False` — desabilita verificação de host key SSH | [HOST_KEY_CHECKING](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#host-key-checking) |
| `[defaults]` | `stdout_callback` | `yaml` — saída formatada em YAML | [DEFAULT_STDOUT_CALLBACK](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#default-stdout-callback) |
| `[callback_default]` | `result_format` | `yaml` (bootstrap) — equivalente via callback | [result_format](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#callback-result-format) |

> **Diferença entre os arquivos:** O `ansible.cfg` principal usa `stdout_callback = yaml` na seção `[defaults]`. O `bootstrap/ansible.cfg` usa `result_format = yaml` na seção `[callback_default]`. Ambos produzem saída formatada em YAML.

---

## 6. Inventário

Arquivo: `inventory.ini` (e `bootstrap/inventory.ini`)

```ini
[local]
localhost ansible_connection=local ansible_python_interpreter=/usr/bin/python3
```

| Parâmetro | Significado | Doc oficial |
|-----------|-------------|-------------|
| `[local]` | Grupo de hosts estático | [Inventory basics](https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html) |
| `ansible_connection=local` | Executa comandos localmente (sem SSH) | [Local connection](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/local_connection.html) |
| `ansible_python_interpreter` | Define o Python a ser usado no host | [Python interpreter](https://docs.ansible.com/ansible/latest/reference_appendices/python_3_support.html) |

O playbook (`playbook.yml`) referencia o grupo `local` via `hosts: local`.

---

## 7. Roles do projeto

| Role | Propósito |
|------|-----------|
| `base` | Pacotes essenciais (curl, wget, gnupg, zip) |
| `gh` | GitHub CLI (apenas bootstrap) |
| `warp` | Warp Terminal |
| `firefox` | Firefox (Mozilla APT, remoção do Snap) |
| `docker` | Docker Engine + grupo docker |
| `vscode` | Visual Studio Code |
| `obsidian` | Obsidian (download da última release) |
| `intellij_toolbox` | JetBrains Toolbox |
| `kubectl` | kubectl (versão estável do Kubernetes) |
| `kind` | kind (Kubernetes in Docker) |
| `k9s` | k9s (TUI para Kubernetes) |
| `nvm` | Node Version Manager + Node.js |
| `sdkman` | SDKMAN |

**Handler:** Apenas a role `docker` possui handler — `roles/docker/handlers/main.yml` — que notifica o `systemd` para habilitar e iniciar o serviço Docker após a instalação.

---

## 8. Variáveis (vars/main.yml)

```yaml
node_version: "20"
nvm_version: "v0.40.3"
docker_version: "5:27.5.1-1~ubuntu.24.04~noble"
remove_firefox_snap: false
kind_version: "v0.27.0"
k9s_version: "v0.40.10"
obsidian_version: "v1.8.9"
```

> Variáveis completas em: [Documentação de variáveis do Ansible](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_variables.html)

---

## 9. Fatos do Ansible referenciados

| Fato (`ansible_facts`) | Uso no projeto |
|-------------------------|----------------|
| `ansible_distribution` | Construção da URL do repositório Docker/Warp |
| `ansible_distribution_release` | Repositório Docker (`noble`, `jammy` etc.) |
| `ansible_architecture` | Derivação de `dpkg_arch` (`x86_64` → `amd64`) |
| `ansible_env.HOME` | Caminho home do usuário para NVM, SDKMAN, Toolbox |
| `ansible_user_id` | Adição do usuário ao grupo docker |

> Lista completa de fatos: [Ansible facts](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_vars_facts.html)
