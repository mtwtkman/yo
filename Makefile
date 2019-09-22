.PHONY:

build-rust:
	cargo build

build-js:
	cd assets/js && npm run build

build: build-rust build-js

start:
	cargo run
