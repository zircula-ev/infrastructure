# Caddy

Dieser Stack stellt den zentralen Reverse Proxy und die TLS-Terminierung der
Zircula-Infrastruktur bereit.

## Öffentliche Routen

| Domain | Internes Ziel |
|---|---|
| `cloud.zircula.org` | `nextcloud:80` |
| `office.zircula.org` | `collabora:9980` |
| `auth.zircula.org` | `authentik-server:9000` |
| `monitoring.zircula.org` | `grafana:3000` |
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
- `../authentik/branding/assets` – read-only eingebundene Authentik-Branding-Assets

## Authentik-Branding-Assets

Unter `https://auth.zircula.org/branding/` liefert Caddy ausschließlich die
versionierten Dateien aus `docker/authentik/branding/assets` aus. Der
`handle_path`-Block entfernt das URL-Präfix, verwendet keinen Verzeichnisindex
und setzt für die unveränderlichen Dateinamen einen langfristigen
`Cache-Control: immutable`-Header. Alle anderen Anfragen an
`auth.zircula.org` gehen weiterhin an `authentik-server:9000`.

Direkte Prüfung nach einem gezielten Caddy-Recreate:

```bash
curl -fsSI https://auth.zircula.org/branding/werk-x-zircula.v1.png
curl -fsSI https://auth.zircula.org/branding/favicon.v1.svg
```

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

Die `Caddyfile` ist als einzelne Datei in den Container gebunden. Ersetzt Git die
Datei beim Branchwechsel oder Pull durch einen neuen Inode, kann ein laufender
Container noch die vorherige Fassung sehen. Fehlt eine neue Route trotz
erfolgreichem Reload in der Container-Datei, wird Caddy kontrolliert neu erstellt:

```bash
docker compose up -d --force-recreate caddy
docker compose ps
docker compose logs --since=2m caddy
```

Das Recreate übernimmt den aktuellen Bind-Mount und verursacht eine kurze
Unterbrechung am Reverse Proxy. Zertifikatsdaten unter `/data` und die
Laufzeitkonfiguration unter `/config` bleiben erhalten.

Neue Routen werden erst aktiviert, wenn DNS gesetzt und der Zielcontainer im
Frontend-Netz intern erreichbar ist. Für Grafana wird vor dem Reload zusätzlich
`http://grafana:3000/api/health` aus dem Caddy-Container geprüft.

## Sicherheit

- ausschließlich Ports 80 und 443 am Host
- interne Zielports nur im Frontend-Netz
- HSTS für alle produktiven Domains
- `/data` und `/config` persistent, aber nicht im Repository
- keine Adminoberfläche des Docker-Hosts über Caddy veröffentlichen
- Prometheus, Alertmanager und Exporter nicht über Caddy veröffentlichen

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

Nach einem Update werden alle öffentlichen Domains geprüft.
