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

- Alertmanager
- Authentik
- Blackbox Exporter
- Caddy
- Collabora
- Grafana
- LibreDesk
- LibreDesk Redis
- Nextcloud
- Node Exporter
- PostgreSQL
- Prometheus
- Redis
- Talk HPB
- Uptime Kuma auf `nctest`
- Vaultwarden

Die Verzeichnisse sind in `.github/dependabot.yml` ausdrücklich aufgeführt.
Neue Einträge werden von Dependabot erst berücksichtigt, nachdem diese
Konfiguration im Default-Branch `main` angekommen ist. Image und Tag stehen
direkt in den jeweiligen Compose-Dateien; variable Tags aus lokalen
`.env`-Dateien werden vermieden, weil Dependabot sie nicht zuverlässig als
aktualisierbare Abhängigkeit erkennt. Die dokumentierte Ausnahme
`aio-talk:latest` benötigt weiterhin eine manuelle Digest- und Release-Prüfung.
Dependabot darf niemals direkt den Produktivserver aktualisieren.

Dependabot bewertet keine anwendungsspezifische Datenmigration. Insbesondere
werden Major-Updates von Datenbanken niemals allein aufgrund eines grünen oder
konfliktfreien Pull Requests gemergt.

## Abhängigkeitentscheidungen vom 15.07.2026

### Caddy 2.10 auf 2.11

Der Wechsel wurde am 23.07.2026 ausgerollt und mit den öffentlichen Anwendungen,
Upstreams und TLS geprüft. Wird eine einzeln gebundene Konfigurationsdatei durch
Git mit einer neuen Inode ersetzt, genügt ein Reload des bestehenden Containers
nicht immer. In diesem Fall wird Caddy mit `docker compose up -d --force-recreate`
neu erstellt und die geladene Konfiguration anschließend erneut geprüft.

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

### Vaultwarden 1.36.0 auf 1.37.0

Das Sicherheitsupdate wurde am 29.07.2026 ausgerollt. Die Veröffentlichung
schließt acht Kategorien mittlerer Sicherheitsprobleme und verbessert unter
anderem SSO, Trusted-Proxy-Behandlung und Schutz vor anonymem
WebSocket-Flooding. Vor dem Update wurden ein Vaultwarden-Datenbanksnapshot und
ein vollständiges Backup des gestoppten Datenpfads erzeugt.

Wegen der strengeren Prüfung von `DATABASE_URL` verwendet der Stack nun die
explizite SQLite-URL `sqlite:///data/db.sqlite3`. Nach dem Update wurden
Datenbankintegrität, Authentik-SSO/MFA, Master-Passwort, Vault-Operationen,
Synchronisation, erneute Anmeldung, SMTP, öffentliche Erreichbarkeit und das
Container-Hardening erfolgreich geprüft.

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
- Authentik: Login, MFA, Recovery-Mail, angebundene Anwendung und Worker-Healthcheck
- Talk HPB: Welcome-Endpunkt und Anruf zwischen zwei getrennten Netzen
- Node Exporter: Hostmetriken vorhanden, Mounts nur lesend, kein Hostport
- Blackbox Exporter: `probe_success 1`, erwarteter HTTP-Status und TLS-Metrik
- Alertmanager: Readiness und befristeter Testalarm bis zum Empfänger
- Prometheus: `promtool`, geladene Regeln, alle erwarteten Targets und
  Alertmanager-Verbindung
- Grafana: API-Health, Datenquelle, Dashboard, lokaler Break-Glass-Login,
  Authentik-OIDC und Rollenmapping
- Vaultwarden: Healthcheck, OIDC, Vault-Entsperrung, Synchronisation,
  Organisationen, Collections, Anhänge, SMTP und öffentliche `/alive`-Probe
- LibreDesk: `/health`, lokaler Break-Glass-Login, OIDC mit MFA, Mailabruf,
  Versand, Threading, Anhänge, Rollen und interner Redis-Zugriff
- LibreDesk Redis: authentifizierter `PONG`, anonymer Zugriff abgewiesen, AOF
  beschreibbar und kein Hostport
- Uptime Kuma: öffentliche HTTP-/TCP-Prüfungen und Benachrichtigung; kein ICMP,
  solange `NET_RAW` nicht ausdrücklich freigegeben ist
