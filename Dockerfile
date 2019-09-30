FROM rust

RUN apt update
RUN apt upgrade -y
RUN apt install libpq-dev
RUN cargo install systemfd cargo-watch
RUN cargo install diesel_cli --no-default-features --features postgres
RUN mkdir /app
WORKDIR /app
COPY Cargo.toml Cargo.toml
COPY Cargo.lock Cargo.lock
COPY src src


CMD ["cargo", "build"]
