# Zircula Infrastruktur

Dieses private Repository dokumentiert und versioniert die Docker-Infrastruktur
für die gemeinsame Nextcloud von Zircula e.V. und den angebundenen Organisationen.
Produktive Daten und Geheimnisse liegen ausschließlich auf dem VPS und sind nicht
Bestandteil des Repositories.

## Architektur

```text
Internet
  ├── :80/:443 ──► Caddy
  │                 ├── cloud.zircula.org ──────► Nextcloud
  │                 ├── office.zircula.org ─────► Collabora
  │                 ├── auth.zircula.org ───────► Authentik
  │                 └── talk.cloud.zircula.org ─► Talk HPB
  └── :3478 TCP/UDP ─────────────────────────────► Talk TURN/STUN

Nextcloud ──► PostgreSQL
Nextcloud ──► Redis
```

## Docker-Stacks

| Stack | Aufgabe | Netzwerke | Öffentliche Hostports |
|---|---|---|---|
| `caddy` | Reverse Proxy und TLS | Frontend | 80/TCP, 443/TCP |
| `nextcloud` | zentrale Kollaborationsplattform | Frontend, Backend | keine |
| `postgres` | zentrale Datenbankinstanz | Backend | keine |
| `redis` | Cache, Sitzungen und Dateisperren | Backend | keine |
| `collabora` | Nextcloud Office | Frontend | keine |
| `authentik` | Identity Provider | Frontend, Backend | keine |
| `talk-hpb` | Signaling, SFU und TURN/STUN | Frontend | 3478/TCP+UDP |

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

Die Netzwerke werden einmalig auf dem Host erstellt und von den Stacks als
`external: true` referenziert. Das Backend ist ein gemeinsames Vertrauensnetz und
ersetzt keine Authentifizierung der darin betriebenen Dienste.

## Secrets

- Produktive `.env` werden niemals committet.
- Alle `.env` auf dem VPS besitzen Modus 600.
- Beispielwerte verwenden ausschließlich Platzhalter wie `CHANGE_ME`.
- Secrets werden getrennt erzeugt und nicht in Tickets, Chats oder Logs kopiert.
- `docker compose config` wird bevorzugt mit `--quiet` ausgeführt, damit keine
  interpolierten Werte ausgegeben werden.

## Typische Startreihenfolge

```text
Netzwerke → PostgreSQL → Redis → Nextcloud → Collabora/Authentik/Talk HPB → Caddy
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
