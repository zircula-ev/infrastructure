# Authentik

Authentik ist der zentrale Identity Provider der Zircula-Infrastruktur. Der Dienst
läuft produktiv unter `https://auth.zircula.org`. Nextcloud ist über OIDC
angebunden; die Anbindung weiterer Dienste über OIDC oder SAML erfolgt
schrittweise.

## Architektur

- `authentik-server` – Weboberfläche, API, eingebetteter Outpost und
  Authentifizierung
- `authentik-worker` – Hintergrundaufgaben ohne Zugriff auf den Docker-Daemon
- PostgreSQL – eigene Datenbank und eigener Datenbankbenutzer
- Caddy – TLS und Reverse Proxy auf `authentik-server:9000`

Der Server ist mit Frontend und Backend verbunden. Der Worker ist ausschließlich
mit dem Backend verbunden, weil er PostgreSQL erreichen muss. Der eingebettete
Outpost läuft im Server und benötigt weder einen separaten Outpost-Container noch
den Docker-Socket.

## Dateien und Daten

- `compose.yaml` – Server, Worker, Volumes und Netzwerke
- `.env.example` – Vorlage ohne produktive Geheimnisse
- `.env` – produktive lokale Konfiguration; nicht versioniert, Modus 600
- `/srv/zircula/authentik/data` – Anwendungsdaten
- `/srv/zircula/authentik/certs` – durch Authentik verwaltete Zertifikate
- `/srv/zircula/authentik/templates` – angepasste Templates
- `blueprints/werk-zircula-brand.yaml` – deklarative Brand-Konfiguration
- `branding/` – versionierte Assets, CSS, Vorschau und Betriebsdokumentation

## Docker-Socket und Worker-Rechte

Die aktuelle Installation verwendet ausschließlich den eingebetteten Outpost und
OIDC-Provider. Automatisch durch Authentik bereitgestellte Docker-Outposts werden
nicht benötigt.

Deshalb gilt verbindlich:

- kein Mount von `/var/run/docker.sock`
- kein expliziter Root-Betrieb des Workers
- `AUTHENTIK_OUTPOSTS__DISCOVER=false`
- Worker ausschließlich im Backend-Netz

Ein direkter Docker-Socket-Mount verleiht dem Worker praktisch Root-Rechte auf dem
gesamten Host. Er darf nicht nur zur Behebung einer fehlerhaften Integration
wieder hinzugefügt werden.

Falls zukünftig ein separater Proxy-, LDAP-, RADIUS- oder RAC-Outpost benötigt
wird, wird zuerst ein manuell verwalteter Outpost geprüft. Nur wenn automatische
Docker-Verwaltung organisatorisch erforderlich ist, wird ein restriktiver
Docker-Socket-Proxy als eigene Änderung entworfen und getestet.

## Dateirechte vor der Umstellung

Der Authentik-Worker läuft ohne Root-Rechte mit dem Benutzer des Images, derzeit
standardmäßig UID/GID 1000. Ohne Root kann er falsche Eigentümer der gemounteten
Verzeichnisse nicht automatisch korrigieren.

Vor dem ersten Deployment dieser Änderung:

```bash
cd /opt/zircula/git/infrastructure/docker/authentik

docker compose config --quiet
docker compose run --rm --no-deps --entrypoint id worker

docker compose run --rm --no-deps --entrypoint sh worker -c '
  set -eu
  for path in /data /certs; do
    test -r "$path"
    test -w "$path"
    printf "read/write ok: %s\\n" "$path"
  done
  test -r /templates
  printf "read ok: /templates\\n"
'

sudo find /srv/zircula/authentik \
  -maxdepth 2 \
  -printf '%u:%g %m %p\n'
```

`/data` und `/certs` müssen für UID/GID 1000 les- und schreibbar sein.
`/templates` muss nur lesbar sein und kann deshalb `root:root 755` bleiben.
Wenn der Test erfolgreich endet, ist kein `chown` erforderlich. Nur wenn der
Test wegen unpassender Eigentümer fehlschlägt und die Ausgabe von `find` dies
bestätigt, werden die Eigentümer kontrolliert korrigiert:

```bash
sudo chown -R 1000:1000 \
  /srv/zircula/authentik/data \
  /srv/zircula/authentik/certs
```

Vor dem rekursiven `chown` wird die Ausgabe von `find` geprüft. Andere
Verzeichnisse unter `/srv/zircula` sind nicht Bestandteil dieser Änderung.

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

## Deployment des Worker-Hardenings

Vorher in Authentik prüfen:

1. Unter **Applications → Outposts** existiert nur
   `authentik Embedded Outpost`.
2. Kein Outpost verwendet eine Docker-Integration zur Bereitstellung eines
   separaten Containers.
3. Eine bestehende automatisch erkannte lokale Docker-Integration wird von keinem
   Objekt referenziert.
4. Eine angemeldete persönliche Admin-Sitzung und der Authentik-Break-Glass-Weg
   stehen für den Funktionstest bereit.

Danach:

```bash
cd /opt/zircula/git/infrastructure/docker/authentik

docker compose config --quiet
docker compose up -d --force-recreate server worker
docker compose ps
docker compose logs --tail=100 server worker
```

Rechte und Socket-Abwesenheit prüfen:

```bash
docker compose exec worker sh -c 'test "$(id -u)" -ne 0'
docker compose exec worker test ! -S /var/run/docker.sock
docker compose exec worker ak healthcheck

docker inspect --format '{{.Config.User}}' authentik-worker
docker inspect --format '{{range $name, $_ := .NetworkSettings.Networks}}{{$name}} {{end}}' \
  authentik-worker
```

Erwartet:

- Worker-UID ist nicht 0.
- Im Worker existiert kein Docker-Socket.
- Der Healthcheck ist erfolgreich.
- Der Worker ist nur mit `zircula_backend` verbunden.

Anwendungstests:

- Authentik-Login und Adminoberfläche
- WebAuthn/MFA eines Testkontos
- OIDC-Login in Nextcloud
- Gruppen- und Entitlement-Übertragung
- Back-Channel-Logout
- Testmail und System Tasks
- eingebetteter Outpost ohne Fehlerstatus

Rollback bei einem Fehler:

1. Den zuletzt bekannten funktionsfähigen Commit beziehungsweise einen
   vorbereiteten Revert der Compose-Änderung auschecken.
2. Konfiguration prüfen und ausschließlich Server und Worker neu erstellen:

```bash
docker compose config --quiet
docker compose up -d --force-recreate server worker
docker compose ps
docker compose logs --tail=100 server worker
```

`git switch main` ist ausdrücklich kein Rollback: Das Hardening ist bereits in
`main` enthalten. Ein Rollback verändert weder Authentik-Datenbank noch Secrets
und darf den Docker-Socket nur im Rahmen einer separat geprüften
Outpost-Entscheidung wieder einführen.

## Branding

Die Brand für `auth.zircula.org` wird über einen file-basierten Blueprint
verwaltet. Der Worker liest `./blueprints` ausschließlich read-only unter
`/blueprints/custom`. Caddy liefert Logo und Favicon gleichursprünglich und mit
versionierten Dateinamen unter `https://auth.zircula.org/branding/` aus.

Der Blueprint identifiziert ausschließlich die vorhandene Brand mit der Domain
`auth.zircula.org` und verwaltet Titel, Logo, Favicon, Custom CSS, das helle
Farbschema, Deutsch als bevorzugte Oberflächensprache sowie das zweispaltige
Layout der User Library. Default-Status, Flow-Zuweisungen, Zertifikate, Default
Application und Flow-Hintergrund bleiben unberührt. Der native zweistufige
Authentik-Login sowie MFA- und OIDC-Flows werden durch das Branding nicht
verändert.

Vor jeder CSS- oder Blueprint-Änderung:

```bash
./branding/scripts/check-css-sync.sh
docker compose config --quiet
```

Vor der erstmaligen Aktivierung wird die bestehende Brand außerhalb des
Repositories als JSON gesichert. Das Entfernen des Blueprints setzt bereits
angewendete Datenbankwerte nicht zurück. Der getestete Rückbau beendet zuerst
die Blueprint-Reconciliation, stellt danach den geschützten Brand-Export wieder
her und entfernt erst anschließend die Caddy-Assetroute. Die vollständige
Prüfliste steht unter `branding/docs/integration-checklist.md`.

Das Branding wurde am 23.07.2026 mit Authentik 2026.5.4 erfolgreich geprüft:
persönlicher Login einschließlich WebAuthn/MFA, Nextcloud- und Grafana-OIDC,
schmaler Viewport sowie die getrennten lokalen Break-Glass-Zugänge
funktionieren.

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
`AUTHENTIK_EMAIL__*`-Variablen ohne Geheimwerte in `.env.example` ergänzt
werden.

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

Authentik wird nur auf eine vorher geprüfte konkrete Version aktualisiert. Die
Image-Version steht direkt in `compose.yaml`, damit Dependabot sie erkennen kann.

```bash
docker compose pull
docker compose up -d
docker compose ps
docker compose logs --tail=100 server worker
```

Vor jedem Update: Release Notes, PostgreSQL-Backup und VPS-Snapshot prüfen. Danach
Login, MFA, Recovery-Mail und mindestens eine angebundene Anwendung testen.
