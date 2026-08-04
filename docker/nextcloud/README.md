# Nextcloud

Dieser Stack stellt die zentrale Nextcloud unter `cloud.zircula.org` bereit. Die
organisatorische Trennung der Vereine erfolgt innerhalb dieser einen Instanz über
Gruppen, Team Folders, Talk-Unterhaltungen, Collectives und App-Berechtigungen.

## Architektur

```text
Browser ──HTTPS──► Caddy ──HTTP/Docker──► Nextcloud
                                           ├── PostgreSQL
                                           ├── Redis ──► Client Push
                                           ├── Collabora
                                           └── Talk HPB
```

Nextcloud ist mit beiden externen Docker-Netzen verbunden:

- `zircula_frontend`: Verbindung zu Caddy und öffentlich angebundenen Diensten
- `zircula_backend`: Verbindung zu PostgreSQL und Redis

Am Nextcloud-Container wird kein Hostport veröffentlicht. Der Zugriff erfolgt
ausschließlich über Caddy.

## Dateien und Daten

- `compose.yaml` – Container, Volumes, Secrets und Netzwerke
- `.env.example` – Vorlage ohne produktive Geheimnisse
- `.env` – produktive lokale Konfiguration; nicht versioniert, Modus 600
- `secrets/redis_password` – lokales Redis-Secret; nicht versioniert, Modus 600
- `php/conf.d/opcache.ini` – zusätzliche PHP-OPcache-Konfiguration
- `templates/update.user.php` – versionierter Hinweis im Wartungsmodus
- `scripts/notify-push-entrypoint` – sicherer Start des Client-Push-Sidecars
- `/srv/zircula/nextcloud/html` – Installation, Konfiguration und Apps
- `/srv/zircula/nextcloud/data` – Nutzdaten

Backup und Restore müssen `html`, `data` und die PostgreSQL-Datenbank gemeinsam
berücksichtigen.

## Voraussetzungen

1. `zircula_frontend` und `zircula_backend` existieren.
2. PostgreSQL und Redis laufen und sind im Backend-Netz erreichbar.
3. Datenbank- und Redis-Zugangsdaten stimmen mit den jeweiligen Stacks überein.
4. Caddy enthält die Routen für `cloud.zircula.org` auf `nextcloud:80`
   sowie `/push/*` auf `notify-push:7867`.
5. Die Verzeichnisse unter `/srv/zircula/nextcloud` besitzen die erforderlichen
   Eigentümer und Rechte.

## Konfiguration

```bash
cp .env.example .env
chmod 600 .env
docker compose config --quiet
docker compose up -d
docker compose ps
docker compose logs --tail=100 nextcloud
```

`docker compose config` kann ohne `--quiet` interpolierte Geheimnisse ausgeben.
Diese Ausgabe darf nicht in Tickets, Chats oder das Repository kopiert werden.

## Redis-Authentifizierung einführen

Redis und Nextcloud verwenden dasselbe zufällige Passwort. Docker Compose stellt
es beiden Containern als Datei unter `/run/secrets/redis_password` bereit. Das
Passwort wird weder in der Compose-Datei noch als Redis-Prozessargument abgelegt.

Auf dem VPS einmalig erzeugen:

```bash
openssl rand -hex 32
```

Den Wert als `REDIS_PASSWORD` in diese beiden lokalen Dateien eintragen:

- `docker/redis/.env`
- `docker/nextcloud/.env`

Danach beide Dateien absichern:

```bash
chmod 600 docker/redis/.env docker/nextcloud/.env
```

Die Umstellung erfolgt in einem kurzen Wartungsfenster. Zuerst beide
Konfigurationen prüfen, dann Redis und unmittelbar danach Nextcloud neu erstellen:

```bash
cd /opt/zircula/git/infrastructure/docker/redis
docker compose config --quiet

cd /opt/zircula/git/infrastructure/docker/nextcloud
docker compose config --quiet

cd /opt/zircula/git/infrastructure/docker/redis
docker compose up -d

cd /opt/zircula/git/infrastructure/docker/nextcloud
docker compose up -d
```

Prüfung ohne Ausgabe des Passworts:

```bash
cd /opt/zircula/git/infrastructure/docker/redis
docker compose ps

cd /opt/zircula/git/infrastructure/docker/nextcloud
docker compose exec --user www-data nextcloud php occ status
docker compose logs --tail=100 nextcloud
```

Bei einem abweichenden Passwort bleibt Redis gesund, aber Nextcloud protokolliert
Authentifizierungsfehler. In diesem Fall beide lokalen `.env` vergleichen, ohne
die Werte weiterzugeben, und nur Nextcloud erneut erstellen.

Die gemeinsame Redis-Authentifizierung wurde am 15.07.2026 produktiv aktiviert.
Geprüft wurden Nextcloud-Status, Dateibrowser, Dateioperationen, Talk sowie das
Erstellen und Bearbeiten eines Dokuments über Collabora. In den Nextcloud-Logs
traten keine Redis-Authentifizierungs- oder Verbindungsfehler auf.

## Client Push

Die App `notify_push` und der gehärtete Sidecar liefern Änderungen zeitnah an
unterstützte Nextcloud-Clients. Der Sidecar verwendet PostgreSQL und Redis über
das Backend-Netz, veröffentlicht keinen Hostport und ist ausschließlich über
Caddys Route `https://cloud.zircula.org/push/` erreichbar.

Installation, Selbsttest, Betrieb, Update und Rollback sind in
`docs/14-client-push.md` beschrieben.

## Authentik und OIDC

Reguläre Benutzer, Gruppen, Passwörter und MFA werden zentral in Authentik
verwaltet. Nextcloud erzeugt Benutzer beim ersten OIDC-Login automatisch und
übernimmt ausschließlich die für diese Anwendung definierten Entitlements.

Der lokale Benutzer `nextcloudadmin` bleibt als getrenntes Break-Glass-Konto
erhalten. Der direkte lokale Login ist unter `/login?direct=1` erreichbar. Die
vollständige Konfiguration und die geprüften Rückfallwege sind in
`docs/08-authentik-nextcloud-oidc.md` dokumentiert.

## OCC und Hintergrundjobs

```bash
docker compose exec --user www-data nextcloud php occ status
docker compose exec --user www-data nextcloud php occ background:cron
```

Für den produktiven Betrieb muss in Nextcloud **Cron** als Hintergrundjob-Modus
aktiv sein. Der tatsächlich verwendete Scheduler – Host-Cron oder separater
Cron-Container – muss überwacht und dokumentiert werden.

## Sicherheit

- keine Warnungen in **Administrationseinstellungen → Übersicht**
- MFA für persönliche Administratorkonten; MFA und Recovery für das lokale
  Break-Glass-Konto werden vor dem produktiven Rollout abgeschlossen
- persönliche Administratorkonten statt geteilter Konten
- Freigabelinks und App-Berechtigungen regelmäßig überprüfen
- `allowed_admin_ranges` nach Einführung eines stabilen Admin-VPNs prüfen

## Wartungsseite

Der Nextcloud-Container bindet
`templates/update.user.php` schreibgeschützt über die gleichnamige
Core-Vorlage ein. Dadurch bleibt der Hinweis bei einer Neuerstellung des
Containers erhalten, ohne die übrige Installation oder das konfigurierte
Branding zu verändern.

Während eines Backups oder einer geplanten Wartung informiert die Seite über
das reguläre Sicherungsfenster zwischen 02:30 und 02:45 Uhr, die übliche Dauer
von 10–20 Minuten und die Kontaktadresse `itsupport@zircula.org`. Sie zeigt
bewusst keinen vermeintlichen Live-Fortschritt und unterscheidet technisch nicht
zwischen Backup und anderer Wartung.

Nach jedem Nextcloud-Update wird die versionierte Vorlage mit
`core/templates/update.user.php` des neuen Images verglichen. Die Einbindung
wird danach einmal kontrolliert getestet:

```bash
set -Eeuo pipefail

docker compose config --quiet
docker compose up -d --force-recreate nextcloud

maintenance_enabled=false
response_file="$(mktemp)"

cleanup_maintenance_test() {
  if [[ "${maintenance_enabled}" == true ]]; then
    docker compose exec -T --user www-data nextcloud \
      php occ maintenance:mode --off \
      || true
  fi

  rm -f "${response_file}"
}

trap cleanup_maintenance_test EXIT

docker compose exec -T --user www-data nextcloud \
  php occ maintenance:mode --on

maintenance_enabled=true

http_status="$(
  curl -sS \
    -o "${response_file}" \
    -w '%{http_code}' \
    https://cloud.zircula.org/
)"

test "${http_status}" = 503

grep -F \
  'Reguläre Sicherungen beginnen täglich zwischen 02:30 und 02:45 Uhr' \
  "${response_file}"

docker compose exec -T --user www-data nextcloud \
  php occ maintenance:mode --off

maintenance_enabled=false
rm -f "${response_file}"
trap - EXIT

docker compose exec -T --user www-data nextcloud \
  php occ status
```

Der Wartungsmodus wird unmittelbar nach dem Sichttest wieder deaktiviert. Vor
dem Verlassen der Sitzung wird zusätzlich mit `php occ status` kontrolliert,
dass `maintenance: false` gilt.

## Backup

Ein vollständiges Backup besteht mindestens aus:

1. `/srv/zircula/nextcloud/html`
2. `/srv/zircula/nextcloud/data`
3. logischem PostgreSQL-Dump der Nextcloud-Datenbank
4. produktiven `.env` in einem getrennten, verschlüsselten Secrets-Backup

Der Ablauf ist in `docs/07-backup-restore.md` beschrieben. Ein Backup gilt erst
nach einem erfolgreichen Restore-Test als betriebsbereit.

## Updates

Nextcloud-Major-Versionen werden nacheinander installiert. Die Image-Version steht
direkt in `compose.yaml`, damit Dependabot sie erkennen kann. Vor jedem Update
werden Release Notes und App-Kompatibilität geprüft und ein konsistentes Backup
erstellt.

```bash
docker compose pull
docker compose up -d
docker compose exec --user www-data nextcloud php occ status
```

Nachtests:

- Login, Dateizugriff und Synchronisation
- Team Folders und Collectives
- Office-Dokument öffnen und speichern
- Talk-Testanruf aus zwei getrennten Netzen
- Cron und Administrationseinstellungen ohne neue Warnungen
