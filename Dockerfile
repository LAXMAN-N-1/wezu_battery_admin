FROM ghcr.io/cirruslabs/flutter:3.41.0 AS build

WORKDIR /app

ARG API_BASE_URL=https://api1.powerfrill.com

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN flutter config --enable-web
RUN flutter build web --release --pwa-strategy=none --dart-define=API_BASE_URL=${API_BASE_URL}

FROM nginx:1.27-alpine AS runtime

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
