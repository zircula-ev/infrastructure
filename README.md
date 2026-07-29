# Zircula Infrastruktur

Dieses private Repository dokumentiert und versioniert die Docker-Infrastruktur
für die gemeinsame Nextcloud von Zircula e.V. und den angebundenen Organisationen.
Produktive Daten und Geheimnisse liegen ausschließlich auf den jeweiligen Hosts
und sind nicht Bestandteil des Repositories.

## Architektur

```text
Internet
  ├── :80/:443 ──► Caddy
  │                 ├── cloud.zircula.org ──────► Nextcloud
  │                 ├── office.zircula.org ─────► Collabora
  │                 ├── auth.zircula.org ───────► Authentik
  │                 ├── monitoring.zircula.org ─► Grafana
  │                 ├── vault.zircula.org ──────► Vaultwarden
  │                 ├── support.zircula.org ────► LibreDesk
  │                 └── talk.cloud.zircula.org ─► Talk HPB
  └── :3478 TCP/UDP ─────────────────────────────► Talk TURN/STUN

Nextcloud ──► PostgreSQL
Nextcloud ──► Redis
Prometheus ─► Alertmanager, Node Exporter und Blackbox Exporter
Grafana ────► Prometheus
Vaultwarden ─OIDC─► Authentik
LibreDesk ──► PostgreSQL und eigener Redis
LibreDesk ─OIDC─► Authentik
nctest/Uptime Kuma ──HTTPS──► öffentliche Dienste
```

## Docker-Stacks auf dem VPS

| Stack | Aufgabe | Netzwerke | Öffentliche Hostports |
|---|---|---|---|
| `caddy` | Reverse Proxy und TLS | Frontend | 80/TCP, 443/TCP |
| `nextcloud` | zentrale Kollaborationsplattform | Frontend, Backend | keine |
| `postgres` | zentrale Datenbankinstanz | Backend | keine |
| `redis` | Cache, Sitzungen und Dateisperren | Backend | keine |
| `collabora` | Nextcloud Office | Frontend | keine |
| `authentik` | Identity Provider | Frontend, Backend | keine |
| `talk-hpb` | Signaling, SFU und TURN/STUN | Frontend | 3478/TCP+UDP |
| `node-exporter` | Hostmetriken | Monitoring | keine |
| `blackbox-exporter` | HTTPS-Prüfungen | Monitoring | keine |
| `alertmanager` | Alarmrouting | Monitoring | keine |
| `prometheus` | Metriken und Alarmregeln | Monitoring | keine |
| `grafana` | Monitoringoberfläche | Frontend, Monitoring | keine |
| `vaultwarden` | Passwort- und Secret-Verwaltung | Frontend | keine |
| `libredesk` | IT-Support-Ticketing (PoC) | Frontend, Backend | keine |
| `libredesk-redis` | anwendungseigener Cache und Queue | Backend | keine |

Hostbezogene Stacks außerhalb des VPS stehen unter `hosts/`. Der derzeit
dokumentierte Host `nctest` betreibt Uptime Kuma als vorläufige externe
Verfügbarkeitsprüfung.

Jeder produktive Stack besitzt:

- `compose.yaml`
- `.env.example` ohne produktive Secrets
- `README.md` mit Start-, Prüf-, Update- und Betriebshinweisen

## Verzeichnisse auf dem VPS

```text
/opt/zircula/git/infrastructure  Repository
/srv/zircula                    persistente Anwendungsdaten
/opt/zircula/backups            lokale Arbeits- und Backupdaten
```

## Docker-Netzwerke

- `zircula_frontend`: Dienste, die Caddy erreichen muss
- `zircula_backend`: interne Kommunikation mit PostgreSQL und Redis
- `zircula_monitoring`: Prometheus, Grafana, Alertmanager und Exporter

Die Netzwerke werden einmalig auf dem Host erstellt und von den Stacks als
`external: true` referenziert. Gemeinsame Netze sind Vertrauensbereiche und
ersetzen keine Authentifizierung der darin betriebenen Dienste.

## Secrets

- Produktive `.env` werden niemals committet.
- Alle `.env` auf den Hosts besitzen Modus 600.
- Beispielwerte verwenden ausschließlich Platzhalter wie `CHANGE_ME`.
- Secret-Dateien unter `secrets/` werden nicht versioniert.
- Secrets werden getrennt erzeugt und nicht in Tickets, Chats oder Logs kopiert.
- `docker compose config` wird bevorzugt mit `--quiet` ausgeführt, damit keine
  interpolierten Werte ausgegeben werden.

## Typische Startreihenfolge

```text
Netzwerke → PostgreSQL → Redis → Nextcloud → Collabora/Authentik/Talk HPB
          → Vaultwarden → LibreDesk Redis → LibreDesk
          → Monitoring-Exporter → Alertmanager → Prometheus → Grafana → Caddy
```

Bereits laufende, voneinander unabhängige Stacks werden bei normalen Updates nur
einzeln neu erstellt.

## Betrieb

- Änderungen erfolgen über kurze Feature-Branches und nachvollziehbare Commits.
- Vor Deployments wird `docker compose config --quiet` ausgeführt.
- Containerupdates erfolgen kontrolliert in einem Wartungsfenster.
- Dependabot prüft die aktiven Compose-Stacks wöchentlich und erstellt nur Pull
  Requests; automatisches Mergen oder Ausrollen ist nicht aktiviert.
- Ein Snapshot ergänzt das Backup, ersetzt aber keinen getesteten Restore.
- Server- und Sicherheitsmaßnahmen werden unter `docs/` dokumentiert.

Wichtige Dokumente:

- `docs/03-architecture.md`
- `docs/04-current-status.md`
- `docs/05-security-hardening.md`
- `docs/06-update-strategy.md`
- `docs/07-backup-restore.md`
- `docs/08-authentik-nextcloud-oidc.md`
- `docs/09-container-privilege-review.md`
- `docs/10-monitoring.md`
- `docs/11-slack-nextcloud-nutzungsabgrenzung.md`
- `docs/12-vaultwarden.md`
- `docs/13-libredesk.md`
