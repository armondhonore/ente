# Nexlayer deploy fix guidance

Pinned: true

This repo deploys the Ente Photos web app (static Next.js export served by nginx).

- Build context: repo root.
- Use the repo's root `Dockerfile` exactly as committed. Do NOT regenerate, ground-check,
  or split this into multiple components — it is authoritative and single-pod.
- The Dockerfile builds only the photos web app (`npm run build:photos`, which needs the
  bundled Rust wasm toolchain) and serves the static export via nginx on port 3000.
- The static site renders its UI at `/` without a live backend, returning HTTP 200.
- Do not add a database or extra pods; this single pod serves the web frontend only.
