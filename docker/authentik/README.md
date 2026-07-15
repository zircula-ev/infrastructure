# Authentik

Authentik ist der zentrale Identity Provider (IdP) der Zircula-Infrastruktur und bildet zukünftig die Grundlage für Single Sign-on (SSO), Benutzerverwaltung und Authentifizierung über verschiedene Dienste hinweg.

## Status

- Status: Testbetrieb (Feature Branch)
- Domain: https://auth.zircula.org
- Docker Stack: `docker/authentik`
- Datenbank: PostgreSQL (eigene Datenbank `authentik`)
- Reverse Proxy: Caddy
- TLS: Automatisch über Caddy

---

## Architektur

Container:

- authentik-server
- authentik-worker

Authentik nutzt die bestehende PostgreSQL-Instanz der Infrastruktur und besitzt eine eigene Datenbank sowie einen eigenen Datenbankbenutzer.

Redis wird in der verwendeten Authentik-Version nicht benötigt.

---

## Datenverzeichnisse

```
/srv/zircula/authentik/
├── certs/
├── data/
└── templates/
```

---

## Netzwerke

- zircula_frontend
- zircula_backend

---

## Konfiguration

Konfiguration erfolgt vollständig über die `.env`.

Wichtige Bereiche:

- Docker Image
- PostgreSQL
- SMTP
- Secret Key

Die Beispielkonfiguration befindet sich in:

```
.env.example
```

Produktive Zugangsdaten werden ausschließlich in:

```
.env
```

gespeichert und nicht versioniert.

---

## Mail

SMTP wird über Manitu bereitgestellt.

Absender:

```
noreply@zircula.org
```

Konfiguration erfolgt über Umgebungsvariablen in der `.env`.

Ein Funktionstest kann ausgeführt werden mit:

```bash
docker compose exec worker ak test_email <empfaenger@example.org>
```

---

## Benutzerverwaltung

Der während des Initial Setups erzeugte Benutzer `akadmin` bleibt als Notfallkonto bestehen.

Empfohlenes Vorgehen:

- `akadmin` ausschließlich als Break-Glass-Account verwenden
- tägliche Administration über persönliche Administrator-Konten
- MFA für alle Administratoren aktivieren

---

## Start

```bash
docker compose up -d
```

---

## Stop

```bash
docker compose down
```

---

## Logs

Server

```bash
docker compose logs -f server
```

Worker

```bash
docker compose logs -f worker
```

---

## Updates

Image aktualisieren:

```bash
docker compose pull
docker compose up -d
```

Vor jedem Versionsupdate:

- Changelog lesen
- Datenbanksicherung erstellen
- Snapshot des VPS erstellen

---

## Integration (geplant)

Authentik soll zukünftig unter anderem folgende Dienste zentral authentifizieren:

- Nextcloud
- Collabora (optional)
- Pretix
- Website / CMS
- weitere zukünftige Dienste (OIDC/SAML)

Die Einführung erfolgt schrittweise nach erfolgreicher Evaluation im Testbetrieb.
