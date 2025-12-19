SHELL := /bin/bash

PROJECT_NAME := gaycarboys

.PHONY: up down restart logs wp wp-shell db-shell

up:
	docker compose up -d

down:
	docker compose down

restart: down up

logs:
	docker compose logs -f

wp:
	docker compose run --rm wpcli wp $(CMD)

wp-shell:
	docker compose run --rm wpcli wp shell

db-shell:
	docker compose exec db mysql -u$${DB_USER:-gaycarboys} -p$${DB_PASSWORD:-gaycarboys} $${DB_NAME:-gaycarboys}


