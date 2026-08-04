# Nextcloud Client Push

Client Push stellt zeitnahe Änderungsbenachrichtigungen für unterstützte
Nextcloud-Clients bereit. Der Dienst ergänzt die vorhandene Nextcloud-, Redis-
und PostgreSQL-Infrastruktur und reduziert regelmäßige Abfragen durch Clients.
Die Benachrichtigungen werden von Nextcloud ausdrücklich nach dem
Best-Effort-Prinzip ausgeliefert; Client Push ersetzt deshalb weder Cron noch
andere Konsistenzprüfungen.

## Architektur

```text
Nextcloud ──► PostgreSQL
    │
    └───────► Redis ──Pub/Sub──► notify-push
                                   ▲
Client ──HTTPS──► Caddy ──/push/*──┘
```

Der Sidecar verwendet dasselbe versionierte Nextcloud-Image wie die
Hauptanwendung und startet daraus ausschließlich die x86_64-Binärdatei der
installierten App. Der Container veröffentlicht keinen Hostport. Caddy leitet ausschließlich
Anfragen unter `https://cloud.zircula.org/push/` über das Frontend-Netz an
`notify-push:7867` weiter. Der Daemon erreicht PostgreSQL und Redis über das
Backend-Netz.

Die dynamischen `*.config.php`-Dateien des offiziellen Nextcloud-Docker-Images
enthalten PHP-Ausdrücke, die der vereinfachte Konfigurationsparser von
`notify_push` nicht vollständig versteht. Das versionierte Startskript erzeugt
die offiziell unterstützten Verbindungs-URLs deshalb zur Laufzeit aus denselben
Compose-Variablen und demselben Redis-Secret wie Nextcloud. Sonderzeichen werden
URL-kodiert; die erzeugten URLs werden weder protokolliert noch versioniert.

## Sicherheitsmodell

- Betrieb als UID/GID 33 (`www-data`)
- read-only Root-Dateisystem
- Nextcloud-Installation ausschließlich read-only eingebunden
- keine Linux-Capabilities
- `no-new-privileges`
- kein Hostport und kein Docker-Socket
- nur die erforderlichen Frontend- und Backend-Netze
- produktiver Log-Level `info`, damit keine Storage- und Benutzerzuordnungen aus
  Debugprotokollen ausgegeben werden

Der Dienst besitzt keine eigenen persistenten Daten. Seine Konfiguration und
Registrierungen liegen in der Nextcloud-Datenbank und werden vom bestehenden
Backup erfasst.

## Erstinstallation

Die App muss vor dem ersten Start des Daemons installiert werden, weil das
ausführbare Programm aus dem App-Verzeichnis der Nextcloud-Installation geladen
wird.

```bash
cd /opt/zircula/git/infrastructure/docker/nextcloud

docker compose exec -T --user www-data nextcloud \
  php occ app:install notify_push

docker compose config --quiet
docker compose up -d notify-push
docker compose ps
docker compose logs --tail=100 notify-push
```

Danach wird die versionierte Caddy-Konfiguration geprüft und geladen:

```bash
cd /opt/zircula/git/infrastructure/docker/caddy

docker compose exec -T caddy \
  caddy validate --config /etc/caddy/Caddyfile

docker compose exec -T caddy \
  caddy fmt --diff /etc/caddy/Caddyfile

docker compose up -d --force-recreate caddy
docker compose ps
docker compose logs --since=2m caddy
```

Abschließend richtet der integrierte Selbsttest den öffentlichen Endpunkt ein:

```bash
cd /opt/zircula/git/infrastructure/docker/nextcloud

docker compose exec -T --user www-data nextcloud \
  php occ notify_push:setup \
    https://cloud.zircula.org/push
```

Der Befehl muss alle internen und externen Verbindungstests erfolgreich
abschließen.

## Smoke-Test

```bash
cd /opt/zircula/git/infrastructure/docker/nextcloud

docker compose ps

docker compose exec -T --user www-data nextcloud \
  php occ app:list --enabled \
  | grep -F 'notify_push:'

docker compose exec -T --user www-data nextcloud \
  php occ notify_push:metrics

docker compose logs --since=5m notify-push \
  | grep -Ei 'error|failed|panic' \
  || true

docker inspect --format \
  'user={{.Config.User}} privileged={{.HostConfig.Privileged}} readonly={{.HostConfig.ReadonlyRootfs}} ports={{json .NetworkSettings.Ports}} restart={{.HostConfig.RestartPolicy.Name}}' \
  notify-push

docker inspect --format \
  'cap_drop={{json .HostConfig.CapDrop}} security={{json .HostConfig.SecurityOpt}}' \
  notify-push

curl -fsS https://cloud.zircula.org/status.php
printf '\n'
```

Zusätzlich werden geprüft:

1. Administrationseinstellungen ohne Client-Push-Warnung
2. Anmeldung und Dateiansicht im Browser
3. Änderung einer Testdatei aus einem zweiten Client
4. zeitnahe Aktualisierung im Desktop- oder Mobilclient
5. Talk-Nachricht und Benachrichtigung mit einem zweiten Konto
6. keine neuen Fehler in Nextcloud-, Caddy- oder Notify-Push-Logs

Client Push verbessert die Zustellung an verbundene Nextcloud-Clients. Die
Push-Dienste von Apple und Google für vollständig geschlossene Mobil-Apps sind
ein davon getrennter Transportweg.

## Betrieb und Updates

Nach einem Update der App wird der Daemon neu erstellt beziehungsweise neu
gestartet, damit er das aktualisierte Programm lädt:

```bash
cd /opt/zircula/git/infrastructure/docker/nextcloud

docker compose exec -T --user www-data nextcloud \
  php occ app:update notify_push

docker compose up -d --force-recreate notify-push
docker compose ps
docker compose logs --since=2m notify-push
```

Bei Nextcloud-Major-Updates werden App-Kompatibilität, Containerstart und
`notify_push:setup` erneut geprüft.

## Rollback

Ein Ausfall von Client Push blockiert Nextcloud nicht; Clients fallen auf ihre
regulären Abfragen zurück. Für einen kontrollierten Rollback:

```bash
cd /opt/zircula/git/infrastructure/docker/nextcloud

docker compose stop notify-push

docker compose exec -T --user www-data nextcloud \
  php occ app:disable notify_push
```

Danach wird die Caddy-Konfiguration aus dem vorherigen Git-Stand wieder geladen.
Dateien, Datenbank und regulärer Nextcloud-Betrieb bleiben davon unberührt.
