SOURCE=srcs

UP = docker compose up -d
BUILD = docker compose build
DOWN = docker compose down

up:
	mkdir -p ~/data/wordpress && mkdir -p ~/data/mariadb
	cd $(SOURCE) && $(UP)

down:
	cd $(SOURCE) && $(DOWN)

build:
	cd $(SOURCE) && $(BUILD)
	
clear:
	cd $(SOURCE) && $(DOWN) -v

fclear: clear
	rm -rf ~/data

re: clear build up

.PHONY: up down build clear
