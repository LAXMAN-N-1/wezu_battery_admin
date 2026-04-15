# syntax=docker/dockerfile:1.7

# ─── Stage 1: Flutter Web Build ──────────────────────────────────────────────
# Using the slim "stable" tag and pinning via --platform for reproducibility.
# The cirruslabs image includes the full Flutter SDK; we only need web.
FROM ghcr.io/cirruslabs/flutter:3.41.0 AS build

WORKDIR /app

# Cap dart2js old-gen heap at 3 GB so it GCs aggressively instead of
# ballooning and getting OOM-killed on memory-constrained build hosts.
ENV PUB_CACHE=/root/.pub-cache \
    CI=true \
    FLUTTER_SUPPRESS_ANALYTICS=true \
    DART_VM_OPTIONS="--old_gen_heap_size=3072"

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

# Backend base URL injected at build time for Flutter web.
# Keep default aligned with production API domain used by dealer/customer apps.
ARG API_BASE_URL=https://api1.wezutech.com

# 4) Build web — cache .dart_tool between builds for incremental compilation
#    API_BASE_URL is injected for explicit backend targeting.
#    nginx /api reverse-proxy remains available as a compatibility fallback.
#    Note: --web-renderer removed in Flutter 3.41 (CanvasKit is default).
#    Note: --pwa-strategy removed in Flutter 3.41 (deprecated).
#    Note: icon tree-shaking is enabled (default) — we only use const Icons.*
#    constants, so dart2js can safely prune unused glyphs. This also
#    significantly reduces dart2js peak memory, preventing OOM kills.
RUN --mount=type=cache,target=/root/.pub-cache \
    --mount=type=cache,target=/app/.dart_tool \
    flutter build web \
      --release \
      --dart-define=API_BASE_URL="${API_BASE_URL}"

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
