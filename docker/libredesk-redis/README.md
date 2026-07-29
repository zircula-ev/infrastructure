# LibreDesk Redis

Dieser Stack stellt ausschließlich Redis für LibreDesk bereit. Er wird nicht von
Nextcloud oder anderen Anwendungen mitbenutzt und ist nur im internen Netz
`zircula_backend` erreichbar.

## Sicherheit

- Redis 7.4.10 Alpine
- Passwort aus einem lokalen Compose-Secret
- kein Hostport und kein Frontend-Netz
- Prozess als Image-Benutzer `redis`
- read-only Root-Dateisystem
- alle Capabilities entfernt und `no-new-privileges`
- AOF-Persistenz unter `/srv/zircula/libredesk-redis`

Das Passwort muss exakt dem Wert in `docker/libredesk/.env` entsprechen. Beide
lokalen Dateien erhalten Modus 600 und werden nicht committet.

## Vorbereitung

```bash
cp .env.example .env
chmod 600 .env

docker pull redis:7.4.10-alpine

redis_uid="$(docker run --rm --entrypoint id redis:7.4.10-alpine -u redis)"
redis_gid="$(docker run --rm --entrypoint id redis:7.4.10-alpine -g redis)"

sudo install -d -o "$redis_uid" -g "$redis_gid" -m 700 \
  /srv/zircula/libredesk-redis
```

Das Passwort einmal mit `openssl rand -hex 32` erzeugen und in beide
LibreDesk-`.env`-Dateien eintragen.

## Start und Prüfung

```bash
docker compose config --quiet
docker compose up -d
docker compose ps
docker compose logs --tail=100 libredesk-redis

docker compose exec libredesk-redis id

docker compose exec libredesk-redis sh -c \
  'REDISCLI_AUTH="$(cat /run/secrets/libredesk_redis_password)" redis-cli ping'

docker compose exec libredesk-redis redis-cli ping
```

Der authentifizierte Test muss `PONG` liefern. Der letzte, absichtlich
unauthentifizierte Test muss mit `NOAUTH` scheitern.

## Backup, Update und Rollback

LibreDesk speichert den maßgeblichen Ticketbestand in PostgreSQL und Uploads im
Anwendungsdatenpfad. Redis-AOF kann ergänzend gesichert werden, ist aber keine
alleinige oder primäre Wiederherstellungsquelle.

Vor Redis-Updates LibreDesk stoppen oder in ein Wartungsfenster nehmen. Release
Notes lesen und AOF-Kompatibilität prüfen:

```bash
docker compose pull
docker compose up -d
docker compose ps
docker compose logs --tail=100 libredesk-redis
```

Danach authentifizierten Zugriff, LibreDesk-Healthcheck und eine Testoperation
prüfen. Bei einem inkompatiblen Datenformat werden vorheriges Image und AOF-Stand
gemeinsam wiederhergestellt.
