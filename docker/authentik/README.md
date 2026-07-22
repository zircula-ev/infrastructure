# Authentik

Authentik ist der zentrale Identity Provider der Zircula-Infrastruktur. Der Dienst
läuft produktiv unter `https://auth.zircula.org`. Nextcloud ist über OIDC
angebunden; die Anbindung weiterer Dienste über OIDC oder SAML erfolgt
schrittweise.

## Architektur

- `authentik-server` – Weboberfläche, API und Authentifizierung
- `authentik-worker` – Hintergrundaufgaben und optionales Outpost-Management
- PostgreSQL – eigene Datenbank und eigener Datenbankbenutzer
- Caddy – TLS und Reverse Proxy auf `authentik-server:9000`

Der Server ist mit Frontend und Backend verbunden. Der Worker benötigt das
Backend für PostgreSQL. Eine Frontend-Verbindung des Workers und der Docker-Socket
sind nur erforderlich, wenn die eingesetzte Outpost-Konfiguration sie tatsächlich
benötigt.

## Dateien und Daten

- `compose.yaml` – Server, Worker, Volumes und Netzwerke
- `.env.example` – Vorlage ohne produktive Geheimnisse
- `.env` – produktive lokale Konfiguration; nicht versioniert, Modus 600
- `/srv/zircula/authentik/data` – Anwendungsdaten
- `/srv/zircula/authentik/certs` – durch Authentik verwaltete Zertifikate
- `/srv/zircula/authentik/templates` – angepasste Templates

## Docker-Socket

Der Worker bindet derzeit `/var/run/docker.sock` ein und läuft dafür als root.
Authentik verwendet diesen Zugriff ausschließlich für die automatische
Bereitstellung und Verwaltung von Outposts. Der Socket verleiht dem Container
praktisch administrative Rechte auf dem gesamten Docker-Host.

Vor der produktiven Nutzung von Outposts wird entschieden:

1. Wird kein automatisch verwalteter Outpost benötigt, werden Socket-Mount und
   `user: root` entfernt.
2. Wird die automatische Verwaltung benötigt, wird ein restriktiver Docker-
   Socket-Proxy geprüft und der Zugriff dokumentiert.

Diese Änderung erfolgt nicht ohne vorherige Prüfung der tatsächlich konfigurierten
Outposts.

## Konfiguration

```bash
cp .env.example .env
openssl rand -base64 60
chmod 600 .env
docker compose config --quiet
docker compose up -d
docker compose ps
```

`AUTHENTIK_SECRET_KEY` darf nach der Inbetriebnahme nicht ohne geplante Migration
geändert werden, da dies Sitzungen und kryptografische Funktionen beeinflusst.

## Benutzerverwaltung

- `akadmin` ausschließlich als Break-Glass-Konto
- tägliche Administration über persönliche Konten
- MFA für alle Administratorkonten
- Break-Glass-Zugangsdaten offline und verschlüsselt verwahren
- Anwendungsbindungen ausdrücklich konfigurieren; fehlende Bindungen können je
  nach Anwendung allen Benutzern Zugriff gewähren

## Nextcloud OIDC

Authentik ist die zentrale Quelle für reguläre Nextcloud-Benutzer, Gruppen,
Passwörter und MFA. Benutzer werden beim ersten erfolgreichen OIDC-Login in
Nextcloud erzeugt. Gruppen und Administratorrechte werden ausschließlich über
anwendungsspezifische Entitlements übertragen.

Konfiguration, Onboarding, Offboarding, Break-Glass-Verfahren und Testnachweise
sind in `docs/08-authentik-nextcloud-oidc.md` dokumentiert. Client-Secrets,
MFA-Schlüssel und Wiederherstellungscodes bleiben außerhalb von Git.

## Mail

SMTP ist für Wiederherstellung, Benachrichtigungen und E-Mail-Stages empfohlen.
Wenn SMTP produktiv verwendet wird, müssen die tatsächlich benötigten
`AUTHENTIK_EMAIL__*`-Variablen ohne Geheimwerte in `.env.example` ergänzt werden.

Test:

```bash
docker compose exec worker ak test_email <empfaenger@example.org>
```

## Betrieb

```bash
docker compose logs -f server
docker compose logs -f worker
```

## Updates

Authentik wird nur auf eine vorher geprüfte konkrete Version aktualisiert.

```bash
docker compose pull
docker compose up -d
docker compose ps
docker compose logs --tail=100 server worker
```

Vor jedem Update: Release Notes, PostgreSQL-Backup und VPS-Snapshot prüfen. Danach
Login, MFA, Recovery-Mail und mindestens eine angebundene Anwendung testen.

