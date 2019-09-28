FROM rust

RUN cargo install systemfd cargo-watch
RUN mkdir /app
WORKDIR /app
COPY Cargo.toml Cargo.toml
COPY Cargo.lock Cargo.lock
COPY src src


CMD ["cargo", "build"]
