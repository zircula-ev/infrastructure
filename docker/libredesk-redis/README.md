# LibreDesk Redis

Dieser Stack stellt ausschließlich Redis für LibreDesk bereit. Er wird nicht von
Nextcloud oder anderen Anwendungen mitbenutzt und ist nur im internen Netz
`zircula_backend` erreichbar.

## Sicherheit

- Redis 7.4.10 Alpine
- Passwort aus der lokalen Datei `secrets/redis_password`
- Secret schreibgeschützt unter `/run/secrets/libredesk_redis_password`
- kein Hostport und kein Frontend-Netz
- Prozess als Image-Benutzer `redis`
- read-only Root-Dateisystem
- alle Capabilities entfernt und `no-new-privileges`
- AOF-Persistenz unter `/srv/zircula/libredesk-redis`

Das Passwort muss exakt dem Wert `LIBREDESK_REDIS_PASSWORD` in
`docker/libredesk/.env` entsprechen. Die Secret-Datei wird von Git ignoriert,
enthält nur das Passwort ohne Variablennamen und erhält Modus 400 sowie die
numerische Eigentümerschaft des Containerbenutzers.

## Vorbereitung

Zuerst Image-Benutzer und Persistenz vorbereiten:

```bash
docker pull redis:7.4.10-alpine

redis_uid="$(docker run --rm --entrypoint id redis:7.4.10-alpine -u redis)"
redis_gid="$(docker run --rm --entrypoint id redis:7.4.10-alpine -g redis)"

sudo install -d -m 700 \
  /srv/zircula/libredesk-redis

sudo chown "$redis_uid:$redis_gid" \
  /srv/zircula/libredesk-redis

install -d -m 750 secrets

sed -n 's/^LIBREDESK_REDIS_PASSWORD=//p' \
  ../libredesk/.env \
  | sudo tee secrets/redis_password >/dev/null

sudo chown "$redis_uid:$redis_gid" \
  secrets/redis_password

sudo chmod 400 secrets/redis_password

unset redis_uid redis_gid
```

Ohne den Inhalt auszugeben prüfen:

```bash
test -s secrets/redis_password
git check-ignore -v secrets/redis_password

app_password="$(
  sed -n 's/^LIBREDESK_REDIS_PASSWORD=//p' \
    ../libredesk/.env
)"

sudo cmp -s \
  <(printf '%s\n' "$app_password") \
  secrets/redis_password

echo "Redis-Secrets stimmen überein"
unset app_password
```

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
