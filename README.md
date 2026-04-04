# WEZU Battery Admin Frontend

Flutter web admin panel deployed with Docker Compose and reverse-proxied by Coolify.

## Production defaults

- Frontend domain: `admin.powerfrill.com`
- Backend API: `https://api1.powerfrill.com`
- Container internal port: `80`
- Public host port mapping: disabled (Coolify proxy should handle ingress)

## Local run

```bash
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=https://api1.powerfrill.com
```

## Build (web)

```bash
flutter build web --release --pwa-strategy=none --dart-define=API_BASE_URL=https://api1.powerfrill.com
```

## Docker image

```bash
docker build \
  --build-arg API_BASE_URL=https://api1.powerfrill.com \
  -t wezu-battery-admin:latest .
```

## Coolify settings

- Build Pack: `Docker Compose`
- Compose file: `docker-compose.yaml`
- Service port (internal): `80`
- Domain: `admin.powerfrill.com`
- SSL: Let’s Encrypt enabled
- Exposed host ports in compose: none (`ports:` should not be used)

### Coolify environment variables (build-time)

Set this in Coolify:

```env
API_BASE_URL=https://api1.powerfrill.com
```

## DNS checklist

- `A` record: `admin.powerfrill.com` -> VPS public IP
- Do not configure any DNS port mapping.
- If using Coolify ingress, avoid separate host-level nginx TLS termination for this domain.

## Deployment checks

```bash
curl -I https://admin.powerfrill.com
curl -sS https://admin.powerfrill.com/health
```

Expected:

- HTTPS response with valid certificate for `admin.powerfrill.com`
- `/health` returns `200 ok`
