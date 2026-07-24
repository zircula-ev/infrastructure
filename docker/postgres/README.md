# PostgreSQL

Dieser Stack stellt die zentrale PostgreSQL-17-Instanz der Zircula-Infrastruktur
bereit. Anwendungen verwenden getrennte Datenbanken und Datenbankrollen.

## Architektur

- ausschließlich im externen Netz `zircula_backend`
- kein veröffentlichter Hostport
- persistente Daten unter `/srv/zircula/postgres`
- Healthcheck über `pg_isready`
- Nextcloud und Authentik besitzen jeweils eigene Datenbanken und Rollen

Das gemeinsame Backend-Netz ersetzt keine Datenbanktrennung. Zugangsdaten einer
Anwendung dürfen keinen Zugriff auf die Datenbank einer anderen Anwendung
erhalten.

## Dateien und Secrets

- `compose.yaml` – Container, Persistenz, Netzwerk und Healthcheck
- `.env.example` – Vorlage ohne produktive Zugangsdaten
- `.env` – lokale Initialisierungs- und Administrationswerte; nicht
  versioniert, Modus 600
- `/srv/zircula/postgres` – PostgreSQL-Datenverzeichnis

`POSTGRES_USER` und `POSTGRES_PASSWORD` werden vom offiziellen Image nur bei
der Initialisierung eines leeren Datenverzeichnisses ausgewertet. Eine spätere
Änderung der `.env` ändert vorhandene Datenbankrollen nicht automatisch.
Anwendungszugänge werden zusätzlich in den jeweiligen lokalen Stack-`.env`
hinterlegt und niemals in Git, Tickets oder Chats kopiert.

## Vorbereitung und Start

Vor einer Erstinstallation:

```bash
sudo install -d -m 700 /srv/zircula/postgres

cp .env.example .env
chmod 600 .env

docker compose config --quiet
docker compose up -d
docker compose ps
docker compose logs --tail=100 postgres
```

Bei einer bestehenden Installation wird das Datenverzeichnis nicht neu
initialisiert und nicht gelöscht. Eigentümer werden nur nach Prüfung des
tatsächlich im Image verwendeten Datenbankbenutzers verändert.

Healthcheck prüfen:

```bash
docker inspect --format '{{json .State.Health}}' postgres
```

Anwendungsdatenbanken und Rollen werden einmalig mit zufälligen, getrennten
Passwörtern angelegt. Änderungen erfolgen in einer administrativen
`psql`-Sitzung und werden anschließend mit der jeweiligen Anwendung getestet.
Passwörter werden nicht als Kommandozeilenargument übergeben.

## Backup

Das laufende PostgreSQL-Datenverzeichnis wird nicht mit einem gewöhnlichen
Dateikopiervorgang als konsistentes Datenbankbackup behandelt. Maßgeblich sind
logische Dumps mit `pg_dump` beziehungsweise `pg_dumpall --globals-only`.
Ein dateibasiertes Backup erfolgt nur bei gestopptem Container oder mit einem
dafür geeigneten konsistenten Snapshotverfahren.

Ein vollständiges Plattformbackup enthält:

1. globale Rollen und Berechtigungen,
2. je einen logischen Dump jeder Anwendungsdatenbank,
3. die dazugehörigen Anwendungsdateien und lokalen Secrets im selben
   dokumentierten Sicherungsstand.

Der Ablauf und Restore-Test stehen in `docs/07-backup-restore.md`. Ein Backup
gilt erst nach erfolgreicher Wiederherstellung in einer isolierten Umgebung als
belastbar.

## Updates

Patch- und Minor-Änderungen innerhalb PostgreSQL 17 erfolgen im
Wartungsfenster:

```bash
docker compose config --quiet
docker compose pull
docker compose up -d
docker compose ps
docker compose logs --tail=100 postgres
```

Danach werden Healthcheck sowie Nextcloud- und Authentik-Zugriff geprüft.

PostgreSQL-Major-Versionen sind nicht datenverzeichniskompatibel. Ein Wechsel auf
PostgreSQL 18 oder neuer erfolgt niemals nur durch Ändern des Image-Tags, sondern
als eigenes Migrationsprojekt mit aktuellem Dump, isoliertem Restore-Test,
separatem Datenverzeichnis, Wartungsfenster und dokumentiertem Rückfallplan.
