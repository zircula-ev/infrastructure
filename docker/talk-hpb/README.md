# Nextcloud Talk High Performance Backend

Dieser Stack stellt für die zentrale Nextcloud unter `cloud.zircula.org` den
Nextcloud-Talk-High-Performance-Backend (HPB) bereit. Er verwendet das offizielle
`aio-talk`-Image von Nextcloud und enthält:

- den Signaling-Server,
- das WebRTC-Media-Gateway (SFU),
- einen integrierten TURN-Server, der zugleich als STUN-Server verwendet werden kann.

Der Stack ist für die vorhandene Infrastruktur und die erwartete kleine Anzahl
gleichzeitiger Video-Teilnehmender ausgelegt. Ein separates coturn-, Janus- oder
Recording-Stack ist dafür nicht erforderlich.

## Architektur

```text
Browser
  │
  ├── HTTPS / WSS :443 ──► talk.cloud.zircula.org ──► Caddy ──► talk-hpb:8081
  │
  └── TURN / STUN :3478 TCP + UDP ───────────────────────► talk-hpb

Nextcloud (cloud.zircula.org) ──► Caddy / talk-hpb
```

Der Container ist ausschließlich mit `zircula_frontend` verbunden:

- Caddy kann den Signaling-Dienst über `talk-hpb:8081` erreichen.
- Der HPB erreicht Nextcloud über die öffentliche interne Caddy-Route
  `https://cloud.zircula.org`.
- Es ist keine Verbindung zu `zircula_backend` erforderlich.

## Dateien

- `compose.yaml` – Container, Netzwerk und veröffentlichte TURN/STUN-Ports
- `.env.example` – vollständige Vorlage ohne produktive Geheimnisse
- `.env` – lokale produktive Konfiguration; wird nicht versioniert

## Voraussetzungen

1. DNS: `talk.cloud.zircula.org` benötigt einen A-Record (und bei verwendeter IPv6
   zusätzlich AAAA) auf den VPS.
2. Firewall: `3478/TCP` und `3478/UDP` müssen von außen erreichbar sein.
   Ports 80 und 443 sind bereits durch Caddy belegt.
3. Caddy muss mit dem HPB den gemeinsamen Docker-Netzwerkverbund
   `zircula_frontend` nutzen.

Der Signaling-Port 8081 wird **nicht** am Host veröffentlicht. Er ist nur für
Caddy im Docker-Netz sichtbar.

## Secrets erzeugen

Auf dem VPS im Stack-Verzeichnis:

```bash
cp .env.example .env
openssl rand -hex 32
openssl rand -hex 32
openssl rand -hex 32
chmod 600 .env
```

Die drei erzeugten Werte gehören jeweils in `TURN_SECRET`,
`SIGNALING_SECRET` und `INTERNAL_SECRET`. Sie dürfen weder committet noch in
Tickets oder Chats kopiert werden.

## Caddy ergänzen

In `docker/caddy/Caddyfile` folgenden zusätzlichen Site-Block ergänzen:

```caddyfile
talk.cloud.zircula.org {
    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
    }

    reverse_proxy talk-hpb:8081
}
```

Caddy unterstützt die für Signaling benötigte WebSocket-Weiterleitung über
`reverse_proxy`; dafür ist keine zusätzliche Header-Konfiguration nötig.

Danach Caddy-Konfiguration prüfen und neu laden:

```bash
docker compose config
docker compose up -d
```

## HPB starten

Im Verzeichnis `docker/talk-hpb`:

```bash
docker compose config
docker compose up -d
docker compose ps
docker compose logs -f talk-hpb
```

Die Compose-Prüfung muss vor jedem ersten Start erfolgen. Bei fehlerfreichem
Start antwortet der Signaling-Dienst nach der Caddy-Ergänzung:

```bash
curl https://talk.cloud.zircula.org/api/v1/welcome
```

Erwartet wird eine JSON-Antwort mit
`"nextcloud-spreed-signaling":"Welcome"`.

## Nextcloud Talk konfigurieren

In Nextcloud unter **Administrationseinstellungen → Talk**:

1. High-Performance-Backend:
   - URL: `https://talk.cloud.zircula.org`
   - Shared Secret: der Wert aus `SIGNALING_SECRET`
   - Die Verbindungsprüfung muss erfolgreich sein.

2. TURN:
   - Modus: `turn: only`
   - Server: `talk.cloud.zircula.org:3478`
   - Secret: der Wert aus `TURN_SECRET`
   - Protokolle: UDP und TCP

3. STUN:
   - Server: `talk.cloud.zircula.org:3478`

Der TURN-Dienst stellt auch STUN bereit. Die Konfiguration in Talk sorgt dafür,
dass Clients bei restriktiven Netzen auf den Relay-Dienst ausweichen können.

## Betrieb und Updates

```bash
docker compose pull
docker compose up -d
docker compose logs --tail=100 talk-hpb
```

Vor Updates: Snapshot bzw. Backup prüfen, Release Notes lesen und nach dem
Update den Welcome-Endpunkt sowie einen Testanruf mit zwei getrennten Netzen
prüfen.

## Nicht enthalten

- Aufnahme-Backend
- SIP-Brücke
- separates coturn- oder Janus-Cluster

Diese Komponenten sind für den aktuellen Bedarf nicht erforderlich und können
später als getrennte Stacks ergänzt werden.
