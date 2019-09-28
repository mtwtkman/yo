.PHONY:

# local

build-rs:
	cargo build

build-js:
	cd assets/js && npm run build

elm-install:
	cd assets/js && npx elm install $(ELM_PACKAGE)

build: build-rust build-js

start:
	systemfd --no-pid -s https::0.0.0.0:55301 -- cargo watch -x run


# docker

init:
	docker-compose build

up:
	docker-compose up -d

log-web:
	docker-compose logs -f --tail 100 web

log:
	docker-compose logs -f --tail 100

redis-cli:
	docker-compose exec redis redis-cli
