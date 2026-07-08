SOURCE=srcs

DATA:=/home/amalangu/data
UP:= docker compose up -d
BUILD:= docker compose build
DOWN:= docker compose down

up:
	cd $(SOURCE) && $(UP)

down:
	cd $(SOURCE) && $(DOWN)

build:
	cd $(SOURCE) && $(BUILD)
	
clear:
	cd $(SOURCE) && $(DOWN)
	sudo rm -rf /home/amalangu/data
	docker volume rm inception_mariadb-data
	docker volume rm inception_wordpress-data

re: clear build up

.PHONY: up down build clear
