# Caddy

Dieser Stack stellt den zentralen Reverse Proxy und die TLS-Terminierung der
Zircula-Infrastruktur bereit.

## Öffentliche Routen

| Domain | Internes Ziel |
|---|---|
| `cloud.zircula.org` | `nextcloud:80` |
| `office.zircula.org` | `collabora:9980` |
| `auth.zircula.org` | `authentik-server:9000` |
| `talk.cloud.zircula.org` | `talk-hpb:8081` |

Caddy ist ausschließlich mit `zircula_frontend` verbunden. Interne Zielports
werden nicht am Host veröffentlicht.

## Dateien und Daten

- `compose.yaml` – Container, Hostports, Volumes und Netzwerk
- `Caddyfile` – öffentliche Routen und Header
- `.env.example` – allgemeine Vorlage
- `.env` – lokale Konfiguration; nicht versioniert, Modus 600
- `/srv/zircula/caddy/data` – Zertifikate und ACME-Daten
- `/srv/zircula/caddy/config` – Laufzeitkonfiguration

## Ports

- 80/TCP für ACME und HTTPS-Weiterleitung
- 443/TCP für HTTPS

Weitere Anwendungsports werden nicht über Caddy veröffentlicht. Talk TURN/STUN
verwendet separat 3478/TCP und 3478/UDP.

## Konfiguration prüfen

Vor jedem Reload:

```bash
docker compose exec caddy caddy validate --config /etc/caddy/Caddyfile
docker compose exec caddy caddy fmt --diff /etc/caddy/Caddyfile
```

Nach erfolgreicher Prüfung:

```bash
docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile
docker compose logs --tail=100 caddy
```

## Sicherheit

- ausschließlich Ports 80 und 443 am Host
- interne Zielports nur im Frontend-Netz
- HSTS für alle produktiven Domains
- `/data` und `/config` persistent, aber nicht im Repository
- keine Adminoberfläche des Docker-Hosts über Caddy veröffentlichen

`includeSubDomains` und `preload` setzen voraus, dass alle betroffenen Subdomains
dauerhaft über gültiges HTTPS erreichbar sind. Neue Subdomains müssen vor der
Veröffentlichung entsprechend geprüft werden.

## Backup und Updates

Das Caddy-Datenverzeichnis enthält private ACME-Schlüssel und wird verschlüsselt
gesichert. Inhalte dürfen nicht in das Repository gelangen.

```bash
docker compose pull
docker compose up -d
docker compose exec caddy caddy validate --config /etc/caddy/Caddyfile
docker compose logs --tail=100 caddy
```

Nach einem Update werden alle vier öffentlichen Domains geprüft.

