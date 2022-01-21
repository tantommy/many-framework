FROM rust:latest as chef
# We only pay the installation cost once,
# it will be cached from the second build onwards
RUN cargo install cargo-chef
WORKDIR /src

FROM chef AS planner
COPY /rust-toolchain.toml /Cargo.* ./
RUN cargo version
COPY /src/http_proxy/Cargo.toml ./src/http_proxy/
COPY /src/kvstore/Cargo.toml ./src/kvstore/
COPY /src/ledger/Cargo.toml ./src/ledger/
COPY /src/omni-abci/Cargo.toml ./src/omni-abci/
COPY /src/omni-echo/Cargo.toml ./src/omni-echo/
COPY /src/omni-kvstore/Cargo.toml ./src/omni-kvstore/
COPY /src/omni-ledger/Cargo.toml ./src/omni-ledger/
RUN --mount=type=ssh cargo chef prepare  --recipe-path recipe.json

FROM chef as builder
WORKDIR /src

RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install make openssh-client git jq

# Install build dependencies
RUN apt-get -y install musl-dev libssl-dev clang lld librocksdb-dev

RUN mkdir ~/.cargo && \
    echo "[net]" >> ~/.cargo/config.toml && \
    echo "git-fetch-with-cli = true" >> ~/.cargo/config.toml && \
    echo "retry = 2" >> ~/.cargo/config.toml


COPY --from=planner /src/recipe.json recipe.json
# Just make sure we're already caching the rust toolchain.
COPY /rust-toolchain.toml .

# Build dependencies - this is the caching Docker layer!
RUN --mount=type=ssh cargo chef cook --release --recipe-path recipe.json

# Build application
COPY . .
RUN --mount=type=ssh cargo build --release