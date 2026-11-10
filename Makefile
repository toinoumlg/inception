SOURCE=srcs

UP:= docker compose up -d
BUILD:= docker compose build
DOWN:= docker compose down

up:
	mkdir -p /home/amalangu/data/wordpress && mkdir -p /home/amalangu/data/mariadb
	cd $(SOURCE) && $(UP)

down:
	cd $(SOURCE) && $(DOWN)

build:
	cd $(SOURCE) && $(BUILD)
	
clear:
	cd $(SOURCE) && $(DOWN) -v
	sudo rm -rf /home/amalangu/data

re: clear build up

.PHONY: up down build clear