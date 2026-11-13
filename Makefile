COMPOSE = docker compose -f srcs/docker-compose.yml

DATA = $(HOME)/data

all: up

check: 
	@test -f srcs/.env || { \
		echo "srcs/.env not set"; exit 1; \
	}

	@test -d secrets || { \
		echo "secrets/* not set"; exit 1; \
	}
	@$(COMPOSE) config --quiet

dirs:
	@mkdir -p "$(DATA)/mariadb" "$(DATA)/wordpress"

up: check dirs
	$(COMPOSE) up -d --build --wait

build: check
	$(COMPOSE) build


down: check
	$(COMPOSE) down

stop: check
	$(COMPOSE) stop

start: check
	$(COMPOSE) start --wait

restart: check
	$(COMPOSE) restart

logs:
	$(COMPOSE) logs --follow

ps:
	$(COMPOSE) ps --all

clean: check
	$(COMPOSE) down -v --remove-orphans

fclean: clean
	sudo rm -rf -- "$(DATA)/mariadb" "$(DATA)/wordpress"

re: clean up

.PHONY: all check dirs up build down stop start restart \
	logs ps clean fclean re
