COMPOSE := docker compose

.PHONY: up up-anytype

up:
	$(COMPOSE) -f docker-compose.yml up -d --pull always

up-anytype:
	$(COMPOSE) -f docker-compose.yml -f docker-compose.anytype.yml up -d --pull always
