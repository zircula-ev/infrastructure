# Docker Networks

Die Docker-Netzwerke werden einmalig auf dem Host erstellt und anschließend von allen Docker-Compose-Stacks als externe Netzwerke verwendet.

## Netzwerke

### zircula_frontend

Für öffentlich erreichbare Dienste.

Beispiele:

- Caddy
- Website
- Nextcloud
- Nextcloud Talk

### zircula_backend

Für interne Kommunikation.

Beispiele:

- PostgreSQL
- Redis
- Nextcloud
- Nextcloud Talk

## Erstellung

```bash
docker network create zircula_frontend
docker network create zircula_backend
```

Alle Compose-Dateien referenzieren diese Netzwerke anschließend als `external: true`.
