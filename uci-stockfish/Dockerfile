# Docker Chess engines
# stockfish

FROM bitnami/minideb:latest AS builder
LABEL maintainer "Antidote1911 <antidote1911@gmail.com>"

RUN install_packages curl build-essential ca-certificates git
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH "/root/.cargo/bin:$PATH"

COPY ./Cargo.toml /
COPY src/ ./src/
RUN cargo build --release

RUN git clone --depth 1 --branch sf_17 https://github.com/official-stockfish/Stockfish.git
RUN cd /Stockfish/src && make build ARCH=x86-64-bmi2

############################################################

FROM bitnami/minideb:latest
## RUN install_packages netcat-traditional ucspi-tcp

COPY ./stockfish.sh /
RUN chmod +x /stockfish.sh

COPY --from=builder /target/release/server /stockfish/
COPY --from=builder /Stockfish/src/stockfish /stockfish/
COPY --from=builder /Stockfish/src/*.nnue /stockfish/

EXPOSE $STOCKFISH_PORT
ENTRYPOINT ["/stockfish.sh"]
