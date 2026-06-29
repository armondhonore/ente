# Nexlayer single-pod build: Ente Photos web app (static Next.js export served by nginx).
# Derived from web/Dockerfile, trimmed to the photos app only so the build is fast
# and reliable. The static site renders its login/landing UI without a live backend,
# so GET / returns 200 regardless of the museum API state.

FROM mirror.gcr.io/library/node:24 AS builder

# Rust toolchain for building ente-wasm (required by build:photos -> build:wasm).
RUN apt-get update && apt-get install -y curl build-essential && rm -rf /var/lib/apt/lists/* && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --target wasm32-unknown-unknown
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /build
COPY web/ ./web
COPY rust/ ./rust

WORKDIR /build/web

ENV NEXT_PUBLIC_ENTE_ENDPOINT=ENTE_API_ORIGIN_PLACEHOLDER

RUN npm ci
RUN npm run build:photos

FROM mirror.gcr.io/library/nginx:stable

WORKDIR /out
COPY --from=builder /build/web/apps/photos/out /out/photos

COPY <<'EOF' /etc/nginx/conf.d/default.conf
server {
    listen 3000;
    root /out/photos;
    location / { try_files $uri $uri.html /index.html; }
}
EOF

EXPOSE 3000

ENV ENTE_API_ORIGIN=http://localhost:8080

COPY <<EOF /docker-entrypoint.d/90-replace-ente-env.sh
find /out -name '*.js' |
    xargs sed -i'' "s#ENTE_API_ORIGIN_PLACEHOLDER#\$ENTE_API_ORIGIN#g"
EOF
RUN chmod +x /docker-entrypoint.d/90-replace-ente-env.sh
