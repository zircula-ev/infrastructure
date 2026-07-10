# 04 – Current Status

## Ziel

Aufbau der ersten produktiven Anwendung auf der neuen VPS-Infrastruktur.

## Erreichte Meilensteine

### Infrastruktur

- Ubuntu Server eingerichtet
- SSH-Schlüssel und Benutzerverwaltung
- Docker CE installiert
- GitHub Repository eingebunden
- Gemeinsame Docker-Netzwerke (`zircula_frontend`, `zircula_backend`)

### Dienste

- Caddy
  - HTTPS über Let's Encrypt
  - Reverse Proxy
  - Testdomain `vps.zircula.org`

- PostgreSQL
  - eigener Stack
  - persistente Daten unter `/srv/zircula/postgres`

- Redis
  - eigener Stack
  - persistente Daten unter `/srv/zircula/redis`

### Anwendungen

- Nextcloud
  - eigener Stack
  - nutzt PostgreSQL
  - nutzt Redis
  - Reverse Proxy über Caddy
  - Installationsseite erreichbar

## Architektur

Jeder Dienst besitzt einen eigenen Docker-Stack.

Produktive Daten liegen unter `/srv/zircula`.

Die Infrastruktur liegt versioniert unter `/opt/zircula/git/infrastructure`.

## Offene Punkte

- Nextcloud installieren
- Trusted Domains
- Cron
- APCu
- Collabora
- Backupkonzept
- Migration der bisherigen Daten
