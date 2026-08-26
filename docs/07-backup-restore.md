# 07 – Backup und Restore

Ein VPS-Snapshot ist eine zusätzliche kurzfristige Rückfallebene, aber kein
vollständiges Backupkonzept. Das produktive Verfahren erzeugt deshalb auf dem
VPS ein clientseitig verschlüsseltes Restic-Repository und spiegelt es über
einen streng eingeschränkten Lesezugang nach nctest.

## Datenfluss

1. Der VPS startet den Sicherungslauf und versetzt Nextcloud in den
   Wartungsmodus.
2. PostgreSQL wird logisch mit `pg_dumpall` und Zstandard gesichert.
3. Vaultwarden erzeugt eine anwendungseigene SQLite-Sicherung.
4. Grafanas SQLite-Datenbank wird über die SQLite-Backup-API kopiert und
   geprüft.
5. Restic sichert die Dateidaten, lokalen Konfigurationen, Secrets und
   konsistenten Dumps verschlüsselt nach
   `/opt/zircula/backups/export/restic`.
6. Nextcloud wird auch bei einem Fehler über die Abschlussbehandlung wieder aus
   dem Wartungsmodus genommen.
7. nctest ruft das verschlüsselte Repository mit einem eigenen SSH-Schlüssel
   und einem erzwungenen `rrsync -ro`-Befehl ab.
8. Nach erfolgreicher Spiegelung erstellt nctest einen ZFS-Snapshot.

nctest erhält weder den Restic-Schlüssel noch eine normale Shell oder
Schreibrechte auf dem VPS. Die Implementierung und Installation sind zusätzlich
in `backup/README.md` dokumentiert.

## Schutzumfang

Gesichert werden insbesondere:

- Nextcloud HTML, Konfiguration, Apps und Nutzerdaten
- logische Dumps aller PostgreSQL-Datenbanken, darunter Nextcloud, Authentik und
  LibreDesk
- Authentik-Daten, Zertifikate und Templates
- Caddy-Zertifikats- und Laufzeitdaten
- Grafana über eine konsistente SQLite-Kopie
- Vaultwarden über sein eingebautes Backup sowie Anhänge und Schlüssel
- LibreDesk-Uploads
- Alertmanager-Zustand
- lokale produktive `.env`- und Secret-Dateien des Infrastrukturcheckouts
- versionierte Compose-, Betriebs- und Wiederherstellungsdokumentation

Bewusst nicht als primäre Wiederherstellungsquelle gesichert werden rohe
PostgreSQL-Datendateien, Redis-Cache- und Queuezustände sowie
Prometheus-Zeitreihen und der aus Nextcloud vollständig regenerierbare
Elasticsearch-Suchindex. Ebenfalls ausgeschlossen sind Git-Objektdaten, bekannte
temporäre Diagnosepfade und leere historische Platzhalter. Die konkrete Liste
liegt versioniert unter `backup/vps/restic-excludes`.

## Konsistenz und Fehlerverhalten

Der Backupservice läuft als Root, weil er unterschiedliche Eigentümer und
geschützte Konfigurationen lesen sowie den Nextcloud-Wartungsmodus steuern muss.
Der systemd-Dienst begrenzt seinen Schreibzugriff auf die erforderlichen
Backup-, Nextcloud-, Vaultwarden- und Metrikpfade.

Der Wartungsmodus wird vor den Datenbank- und Dateisicherungen aktiviert. Ein
Abbruch darf ihn nicht unbeabsichtigt aktiv lassen. Ein Lauf gilt erst dann als
erfolgreich, wenn Dumps und SQLite-Kopien erstellt, der Restic-Snapshot
geschrieben, die Aufbewahrung angewendet und `restic check` erfolgreich
abgeschlossen wurden.

Der externe Pull startet zeitversetzt auf nctest. Er ersetzt den bisherigen
Spiegel erst nach erfolgreicher Übertragung und erstellt anschließend einen
ZFS-Snapshot. Ein Übertragungsfehler darf keinen erfolgreichen Stand als neu
kennzeichnen.

## Aufbewahrung

Restic bewahrt derzeit auf:

- 7 tägliche Sicherungen
- 4 wöchentliche Sicherungen
- 6 monatliche Sicherungen

nctest bewahrt zusätzlich die letzten 14 ZFS-Spiegel-Snapshots auf. Vor größeren
Updates und Migrationen werden bei Bedarf zusätzliche manuelle Stände erzeugt.
Die Regeln werden nach Beobachtung des realen Datenwachstums überprüft.

## Verschlüsselung und Zugriff

- Restic verschlüsselt bereits auf dem VPS vor der Übertragung.
- Das Restic-Passwort liegt root-only auf dem VPS.
- Das Passwort wird offline an mindestens zwei kontrollierten Orten verwahrt.
- Der SSH-Schlüssel auf nctest ist ausschließlich für diesen Pull bestimmt.
- Das VPS-Konto besitzt ein gesperrtes Passwort und ausschließlich einen
  erzwungenen read-only-rsync-Befehl.
- Secrets, Schlüssel und Passwörter werden nicht in Git, Chats, Tickets oder
  Logs kopiert.
- Die nctest-Kopie darf nicht als einzige dauerhafte Sicherung betrachtet
  werden.

## Überwachung

Der VPS-Backupservice schreibt über den Textfile Collector des Node Exporters
Metriken zu Erfolg, Zeitpunkt und Dauer des letzten Laufs. Prometheus alarmiert
bei einem fehlgeschlagenen oder überfälligen Backup. Der erfolgreiche externe
nctest-Pull und die Existenz des ZFS-Snapshots werden zusätzlich auf nctest
geprüft.

Die Alarmregeln werden erst nach dem ersten erfolgreichen manuellen Backup
aktiviert, damit eine noch nicht initialisierte Installation keinen
Scheinfehler auslöst.

## Restore-Test

Vor Aktivierung der Timer wird mindestens ein kleiner Restore in ein leeres
Verzeichnis durchgeführt und mit der Quelldatei verglichen. Danach wird
quartalsweise in einer isolierten Umgebung geprüft:

1. gewünschten Restic-Snapshot auswählen
2. Snapshot in ein leeres Restore-Verzeichnis zurückspielen
3. PostgreSQL aus dem komprimierten logischen Dump rekonstruieren
4. Grafana- und Vaultwarden-Kopien auf Integrität prüfen
5. Nextcloud-Konfiguration, Apps, Daten und Eigentümer wiederherstellen
6. Nextcloud-Status, Login und Stichproben von Dateien und Team Folders prüfen
7. Office, Talk, Authentik-OIDC und LibreDesk-Anhänge stichprobenartig testen
8. Elasticsearch leer bereitstellen und den Volltextindex aus Nextcloud neu
   aufbauen; der Index wird nicht aus Restic restauriert
9. Dauer, Probleme und verwendeten Sicherungsstand dokumentieren

Ein Backup gilt betrieblich erst nach einem erfolgreichen Restore-Test als
belastbar.

## Betriebsgrenzen und nächste Ausbaustufe

nctest kann versehentlich ausgeschaltet werden, befindet sich nicht in einem
professionellen Rechenzentrum und überwacht seinen eigenen vollständigen Ausfall
nicht unabhängig. Seine ZFS-Snapshots verbessern den Schutz vor versehentlichem
oder kompromittiertem Überschreiben, ersetzen aber kein zweites geografisch und
organisatorisch unabhängiges Ziel.

Nach Stabilisierung des Go-live-Betriebs werden deshalb RPO, RTO,
Verantwortlichkeiten und ein dauerhaftes weiteres Backupziel verbindlich
beschlossen. Bis dahin ergänzen die weiter verfügbaren alten Clouds und
anlassbezogene VPS-Snapshots die neue Sicherung, ersetzen sie jedoch nicht.
