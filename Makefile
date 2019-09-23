.PHONY:

build-rs:
	cargo build

build-js:
	cd assets/js && npm run build

elm-install:
	cd assets/js && npx elm install $(ELM_PACKAGE)

build: build-rust build-js

start:
	cargo run
