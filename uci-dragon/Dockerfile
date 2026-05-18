FROM rust:1-alpine AS builder

RUN apk add --no-cache musl-dev

WORKDIR /build

# Pré-compilation des dépendances (cache Docker)
COPY uciserver/Cargo.toml uciserver/Cargo.toml
COPY Cargo.toml Cargo.toml
RUN mkdir -p uciserver/src && echo 'fn main(){}' > uciserver/src/main.rs
RUN cargo build --release --manifest-path uciserver/Cargo.toml 2>/dev/null || true

# Compilation réelle
COPY uciserver/src uciserver/src
RUN touch uciserver/src/main.rs && \
    cargo build --release --manifest-path uciserver/Cargo.toml

# Dragon n'est pas open-source.
# Placer le binaire Linux dans uci-dragon/dragon avant de builder.
FROM debian:bookworm-slim AS engine

COPY uci-dragon/dragon /usr/local/bin/dragon
RUN chmod +x /usr/local/bin/dragon

FROM debian:bookworm-slim

COPY --from=builder /build/target/release/uciserver /usr/local/bin/uciserver
COPY --from=engine  /usr/local/bin/dragon            /usr/local/bin/dragon

ARG PORT=8200
ENV PORT=${PORT}

EXPOSE ${PORT}

CMD ["sh", "-c", "uciserver --port ${PORT} --engine /usr/local/bin/dragon"]
