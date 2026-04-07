# syntax=docker/dockerfile:1.7

# ─── Stage 1: Flutter Web Build ──────────────────────────────────────────────
# Using the slim "stable" tag and pinning via --platform for reproducibility.
# The cirruslabs image includes the full Flutter SDK; we only need web.
FROM ghcr.io/cirruslabs/flutter:3.41.0 AS build

WORKDIR /app

ARG API_BASE_URL=https://api1.powerfrill.com

ENV PUB_CACHE=/root/.pub-cache \
    CI=true \
    FLUTTER_SUPPRESS_ANALYTICS=true

# 1) Enable web (skip Android/iOS toolchains)
RUN flutter config --enable-web --no-enable-android --no-enable-ios \
    --no-enable-linux-desktop --no-enable-macos-desktop --no-enable-windows-desktop

# 2) Dependency layer — only re-runs when pubspec changes
COPY pubspec.yaml pubspec.lock ./
RUN --mount=type=cache,target=/root/.pub-cache \
    flutter pub get --no-example

# 3) Copy ONLY what the web build actually needs (skip platform dirs, tests, etc.)
COPY lib/ lib/
COPY web/ web/
COPY assets/ assets/
COPY analysis_options.yaml ./

# 4) Build web — cache .dart_tool between builds for incremental compilation
RUN --mount=type=cache,target=/root/.pub-cache \
    --mount=type=cache,target=/app/.dart_tool \
    flutter build web \
      --release \
      --pwa-strategy=none \
      --web-renderer=canvaskit \
      --dart-define=API_BASE_URL=${API_BASE_URL} \
      --no-tree-shake-icons

# ─── Stage 2: Lightweight Nginx Runtime (~7 MB) ─────────────────────────────
FROM nginx:1.27-alpine AS runtime

# Remove default nginx site
RUN rm -rf /usr/share/nginx/html/*

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=2 \
  CMD wget -q -O /dev/null http://127.0.0.1/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
