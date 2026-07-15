# 06 – Update-Strategie

Ziel ist eine zeitnahe, aber kontrollierte Aktualisierung ohne unbeaufsichtigte
Major-Upgrades. Watchtower oder vergleichbare automatische Container-Neustarts
werden für diesen produktiven Einzelserver nicht eingesetzt.

## Ebenen

### Ubuntu

- Sicherheitsupdates täglich automatisiert installieren.
- Normale Paketupdates monatlich im Wartungsfenster prüfen.
- Neustartbedarf überwachen; kein unangekündigter Auto-Reboot während der Nutzung.
- Ein LTS-Release-Upgrade erst nach Herstellerfreigabe, Backup und Restore-Test.

### Container-Images

- Authentik, Collabora und Nextcloud auf getestete konkrete Versionen pinnen.
- Caddy, PostgreSQL und Redis mindestens auf eine Major-Linie begrenzen; ein Pull
  darf nur im Wartungsfenster erfolgen, weil auch ein Major-Tag neue Patch-Images
  liefert.
- `aio-talk:latest` bleibt die dokumentierte Ausnahme, solange Nextcloud kein
  geeignetes stabiles Versionstag für diese Betriebsart anbietet. Das Image wird
  trotzdem nicht automatisch ausgerollt.
- Nach erfolgreichem Test optional den tatsächlich eingesetzten Digest
  dokumentieren, um Deployments reproduzierbar zu machen.

### Nextcloud

- neueste Maintenance-Version der eingesetzten Major-Linie zeitnah installieren
- Major-Versionen ausschließlich einzeln und ohne Überspringen aktualisieren
- vorab Kompatibilität von Talk, Team Folders, Collectives, Office und weiteren
  produktiven Apps prüfen
- Downgrade nicht als Rückfallplan verwenden; Rückfall erfolgt durch Restore

## Benachrichtigung über Updates

GitHub Dependabot überwacht die Docker-Compose-Abhängigkeiten der aktiven Stacks
wöchentlich montags um 06:00 Uhr in der Zeitzone `Europe/Berlin`. Die Konfiguration
liegt unter `.github/dependabot.yml` und erstellt ausschließlich Pull Requests.
Automatisches Mergen und ein automatisches Deployment auf den VPS bleiben
deaktiviert.

Überwacht werden:

- Authentik
- Caddy
- Collabora
- Nextcloud
- PostgreSQL
- Redis
- Talk HPB

Für Images, deren Tag über Variablen zusammengesetzt wird, muss geprüft werden, ob
Dependabot sie erkennt. Falls nicht, wird Renovate oder eine reine
Benachrichtigungslösung wie Diun eingesetzt. Das Tool darf niemals direkt den
Produktivserver aktualisieren.

Dependabot bewertet keine anwendungsspezifische Datenmigration. Insbesondere
werden Major-Updates von Datenbanken niemals allein aufgrund eines grünen oder
konfliktfreien Pull Requests gemergt.

## Abhängigkeitentscheidungen vom 15.07.2026

### Caddy 2.10 auf 2.11

Der vorgeschlagene Wechsel bleibt für ein separates Wartungsfenster offen. Vor
dem Merge werden die neue Caddy-Version und das bestehende Caddyfile validiert.
Nach dem Rollout werden alle vier öffentlichen Domains und ihre Upstreams geprüft.

### PostgreSQL 17 auf 18

Der automatisch erzeugte Pull Request wurde geschlossen und die Major-Version 18
für automatische Vorschläge ignoriert. PostgreSQL-Major-Versionen sind nicht
datenverzeichniskompatibel und benötigen `pg_upgrade` oder logischen
Dump/Restore. Zusätzlich ändert das offizielle PostgreSQL-18-Image den empfohlenen
Volume-/PGDATA-Aufbau. Ein Wechsel erfolgt deshalb ausschließlich als eigenes
Migrationsprojekt mit:

1. aktuellem logischem Dump,
2. getesteter Wiederherstellung in einer isolierten PostgreSQL-18-Instanz,
3. separatem Datenverzeichnis,
4. angekündigtem Wartungsfenster,
5. Anwendungs- und Integritätsprüfung,
6. dokumentiertem Rückfallplan.

## Wartungsfenster

Empfehlung für den kleinen Vereinsbetrieb:

- wöchentlich: Meldungen und Security Advisories sichten
- monatlich: reguläres Wartungsfenster von 60–90 Minuten
- außerplanmäßig: kritische, tatsächlich relevante Sicherheitslücken innerhalb
  von 24–72 Stunden nach Backup und verkürztem Test
- quartalsweise: Restore-Test und vollständige Rechte-/Portprüfung

## Standardablauf pro Stack

1. Release Notes und bekannte Probleme lesen.
2. Abhängigkeiten und erforderliche Migrationsschritte prüfen.
3. Backupalter und Restore-Fähigkeit bestätigen.
4. VPS-Snapshot als zusätzliche kurzfristige Rückfallebene erstellen.
5. Konfiguration ohne Ausgabe von Secrets prüfen:

   ```bash
   docker compose config --quiet
   ```

6. Neues Image laden und dessen Digest notieren:

   ```bash
   docker compose pull
   docker image ls --digests
   ```

7. Nur den vorgesehenen Stack aktualisieren:

   ```bash
   docker compose up -d
   docker compose ps
   docker compose logs --tail=100
   ```

8. Dienstspezifische Nachtests durchführen.
9. Bei Erfolg Versionsänderung, Datum und Testergebnis committen bzw.
   dokumentieren.
10. Snapshot erst nach einer angemessenen Beobachtungszeit entfernen.

## Nachtests

- Caddy: Konfiguration valide, alle Domains mit gültigem TLS erreichbar
- PostgreSQL/Redis: Healthchecks und Nextcloud-Zugriff funktionieren
- Nextcloud: Status, Cron, Administrationseinstellungen, Dateioperationen
- Collabora: Dokument öffnen, bearbeiten und speichern
- Authentik: Login, MFA, Recovery-Mail und angebundene Anwendung
- Talk HPB: Welcome-Endpunkt und Anruf zwischen zwei getrennten Netzen
