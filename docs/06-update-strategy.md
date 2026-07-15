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

- Authentik, Collabora, Nextcloud und Portainer auf getestete konkrete Versionen
  pinnen.
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

GitHub Dependabot kann Docker-Compose-Abhängigkeiten überwachen. Vorgeschlagen wird
eine wöchentliche Konfiguration für alle Stack-Verzeichnisse, die ausschließlich
Pull Requests erstellt. Automatisches Mergen bleibt deaktiviert.

Für Images, deren Tag über Variablen zusammengesetzt wird, muss geprüft werden, ob
Dependabot sie erkennt. Falls nicht, wird Renovate oder eine reine
Benachrichtigungslösung wie Diun eingesetzt. Das Tool darf niemals direkt den
Produktivserver aktualisieren.

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
- Portainer: nur über den administrativen Zugang erreichbar

