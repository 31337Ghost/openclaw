COMPOSE := docker compose
ANDROID_MCP_SCRIPT := ./scripts/install-android-mcp.sh

.PHONY: up up-anytype up-infra update android-mcp-install android-mcp-start android-mcp-stop android-mcp-restart android-mcp-status android-mcp-run

up:
	mkdir -p ./data/.config ./data/.npm
	$(COMPOSE) -f docker-compose.yml up -d --pull always

up-anytype:
	mkdir -p ./data/.config ./data/.npm
	$(COMPOSE) -f docker-compose.yml -f docker-compose.anytype.yml up -d --pull always


up-infra:
	$(COMPOSE) -p infra -f docker-compose.infra.yml up -d --pull always

update:
	git fetch origin && git checkout -B main origin/main

android-mcp-install:
	$(ANDROID_MCP_SCRIPT) install

android-mcp-start:
	$(ANDROID_MCP_SCRIPT) start

android-mcp-stop:
	$(ANDROID_MCP_SCRIPT) stop

android-mcp-restart:
	$(ANDROID_MCP_SCRIPT) restart

android-mcp-status:
	$(ANDROID_MCP_SCRIPT) status

android-mcp-run:
	$(ANDROID_MCP_SCRIPT) run
