# Redis

Dieser Stack stellt den zentralen Redis-Dienst für Nextcloud bereit. Redis wird
für Cache, PHP-Sitzungen und transaktionale Dateisperren verwendet.

## Architektur

Redis ist ausschließlich mit `zircula_backend` verbunden und veröffentlicht
keinen Hostport. Anwendungen erreichen den Dienst intern unter `redis:6379`.

Das Backend-Netz verhindert direkten Internetzugriff, ist aber ein gemeinsam
genutztes Vertrauensnetz. Deshalb ist Redis zusätzlich mit einem zufälligen
Passwort geschützt. Ein kompromittierter anderer Container im Backend kann Redis
damit nicht ohne Zugangsdaten verwenden.

## Dateien und Daten

- `compose.yaml` – Dienst, Secret, Healthcheck und Netzwerk
- `redis-secure-entrypoint.sh` – erzeugt die flüchtige Redis-Konfiguration
- `.env.example` – Vorlage ohne produktives Passwort
- `.env` – produktive lokale Konfiguration; nicht versioniert, Modus 600
- `/srv/zircula/redis` – persistente AOF-Daten

## Secret-Verarbeitung

Das Passwort wird aus `REDIS_PASSWORD` in der lokalen `.env` als Docker-Compose-
Secret unter `/run/secrets/redis_password` eingebunden. Beim Containerstart wird
durch das als `redis` laufende Entrypoint-Script auf einem flüchtigen `tmpfs` eine
Redis-Konfiguration mit Modus 600 erzeugt. Das Script akzeptiert bewusst nur das
mit `openssl rand -hex 32` erzeugte hexadezimale Format.

Dadurch steht das Passwort nicht:

- in `compose.yaml`,
- im Repository,
- als Container-Umgebungsvariable,
- als Redis-Prozessargument.

Die Compose-Secret-Quelle `environment` wird von `docker compose` unterstützt,
nicht von `docker stack deploy`. Dieser Stack wird mit Docker Compose betrieben.

## Passwort erzeugen

```bash
cp .env.example .env
openssl rand -hex 32
chmod 600 .env
```

Den erzeugten Wert in `REDIS_PASSWORD` eintragen. Derselbe Wert muss in
`docker/nextcloud/.env` hinterlegt werden. Das Passwort niemals in GitHub,
Tickets, Logs oder Chats kopieren.

## Start und Prüfung

```bash
docker compose config --quiet
docker compose up -d
docker compose ps
docker compose logs --tail=100 redis
```

Der Healthcheck authentifiziert sich über das gemountete Secret und muss
`healthy` melden.

Ein anonymer Zugriff muss abgewiesen werden:

```bash
docker compose exec redis redis-cli ping
```

Erwartet wird `NOAUTH Authentication required`.

Der authentifizierte interne Healthcheck kann ohne Anzeige des Passworts erneut
ausgeführt werden:

```bash
docker inspect --format '{{json .State.Health}}' redis
```

## Einführung in der bestehenden Installation

Redis und Nextcloud müssen im selben Wartungsfenster umgestellt werden. Die
vollständige Reihenfolge ist in `docker/nextcloud/README.md` dokumentiert.
Zwischen dem Redis-Neustart und dem Nextcloud-Neustart kann Nextcloud kurzzeitig
keine Sitzungen oder Sperren über Redis verarbeiten.

## Backup

Redis ist nicht die alleinige Quelle produktiver Nextcloud-Daten. Maßgeblich sind
Nextcloud-Dateien, Konfiguration und PostgreSQL-Datenbank. Das persistente
Redis-Verzeichnis kann zusätzlich gesichert werden, ersetzt diese Komponenten aber
nicht.

## Updates

```bash
docker compose pull
docker compose up -d
docker compose ps
docker compose logs --tail=100 redis
```

Nach dem Update müssen Redis und Nextcloud gesund sein und ein Login sowie eine
Dateioperation getestet werden.
