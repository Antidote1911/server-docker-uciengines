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

FROM debian:bookworm-slim AS engine

RUN apt-get update && \
    apt-get install -y --no-install-recommends wget ca-certificates && \
    wget -q "https://github.com/official-stockfish/Stockfish/releases/download/sf_17/stockfish-ubuntu-x86-64-avx2.tar" \
         -O /tmp/stockfish.tar && \
    tar -xf /tmp/stockfish.tar -C /tmp && \
    cp /tmp/stockfish/stockfish-ubuntu-x86-64-avx2 /usr/local/bin/stockfish && \
    chmod +x /usr/local/bin/stockfish && \
    rm -rf /tmp/stockfish* /var/lib/apt/lists/*

FROM debian:bookworm-slim

COPY --from=builder /build/target/release/uciserver /usr/local/bin/uciserver
COPY --from=engine  /usr/local/bin/stockfish         /usr/local/bin/stockfish

ARG PORT=8100
ENV PORT=${PORT}

EXPOSE ${PORT}

CMD ["sh", "-c", "uciserver --port ${PORT} --engine /usr/local/bin/stockfish"]
