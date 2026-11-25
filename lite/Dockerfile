# syntax=docker/dockerfile:1.7
# WordCraft lite: build + serve.  From the repo root:
#   docker build -f lite/Dockerfile -t wordcraft-lite .
#   docker run -p 8080:80 wordcraft-lite
# Build the upstream settings instead (for comparison):  --build-arg MODE=upstream
ARG RUST_VERSION=1.95
FROM rust:${RUST_VERSION}-bookworm AS build
ARG TRUNK_VERSION=0.22.2
RUN rustup target add wasm32-unknown-unknown \
 && apt-get update && apt-get install -y --no-install-recommends brotli && rm -rf /var/lib/apt/lists/* \
 && curl -fsSL "https://github.com/trunk-rs/trunk/releases/download/v${TRUNK_VERSION}/trunk-x86_64-unknown-linux-gnu.tar.gz" \
    | tar -xz -C /usr/local/bin trunk
WORKDIR /src
COPY . .
ARG MODE=lite
ARG LITE_OPT_LEVEL=s
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/usr/local/cargo/git \
    --mount=type=cache,target=/root/.cache/trunk \
    --mount=type=cache,target=/src/target-cache,id=wordcraft-target-${MODE}-${LITE_OPT_LEVEL} \
    LITE_OPT_LEVEL=${LITE_OPT_LEVEL} CARGO_TARGET_DIR=/src/target-cache lite/build.sh ${MODE} \
 && mv /src/dist/web-${MODE} /site

FROM nginx:1.27-alpine
COPY lite/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /site /usr/share/nginx/html
