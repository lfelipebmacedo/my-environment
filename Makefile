BOOTSTRAP_DIR := bootstrap
PLAYBOOK      := $(BOOTSTRAP_DIR)/playbook.yml
ANSIBLE_OPTS  := --ask-become-pass
ROLES         := base gh warp firefox docker vscode obsidian obsidian-backup intellij_toolbox kubectl kind k9s nvm sdkman

.PHONY: bootstrap check dry-run lint roles vars

## Full bootstrap (default)
bootstrap:
	@cd $(BOOTSTRAP_DIR) && ansible-playbook playbook.yml $(ANSIBLE_OPTS)

## Syntax check
check:
	@ansible-playbook $(PLAYBOOK) --syntax-check

## Dry-run (check mode — não instala nada)
dry-run:
	@cd $(BOOTSTRAP_DIR) && ansible-playbook playbook.yml $(ANSIBLE_OPTS) --check

## Lint playbooks (requer ansible-lint)
lint:
	@ansible-lint $(PLAYBOOK) $(BOOTSTRAP_DIR)/roles/*/tasks/main.yml

## Listar roles disponíveis
roles:
	@for r in $(ROLES); do echo "  $$r"; done

## Mostrar configuração atual
vars:
	@cat $(BOOTSTRAP_DIR)/vars/main.yml

## Instalar role específica (ex: make docker)
$(ROLES):
	@cd $(BOOTSTRAP_DIR) && ansible-playbook playbook.yml $(ANSIBLE_OPTS) --tags $@

## Rodar a partir de uma task específica
# uso: make start-at TASK="firefox : garantir que o snap do firefox não está instalado"
start-at:
	@cd $(BOOTSTRAP_DIR) && ansible-playbook playbook.yml $(ANSIBLE_OPTS) --start-at-task="$(TASK)"

help: Makefile
	@echo "Comandos:"
	@echo "  make                roda o playbook completo (mesmo que make bootstrap)"
	@echo "  make check          syntax check do playbook"
	@echo "  make dry-run        simula a execução sem instalar nada"
	@echo "  make lint           roda ansible-lint (se instalado)"
	@echo "  make roles          lista as roles disponíveis"
	@echo "  make vars           mostra vars/main.yml"
	@echo "  make <role>         instala só uma role (ex: make docker, make kubectl)"
	@echo "  make start-at TASK=\"...\"   começa a partir de uma task específica"
