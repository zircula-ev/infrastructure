# 07 – Backup und Restore

Ein VPS-Snapshot ist eine zusätzliche kurzfristige Rückfallebene, aber kein
vollständiges Backupkonzept. Das produktive Backup muss verschlüsselt, extern und
wiederherstellbar sein.

## Schutzumfang

Mindestens zu sichern sind:

- `/srv/zircula/nextcloud/html`
- `/srv/zircula/nextcloud/data`
- logische PostgreSQL-Dumps aller produktiven Datenbanken
- `/srv/zircula/caddy`
- `/srv/zircula/authentik`
- `/srv/zircula/libredesk/uploads`
- logischer Dump der LibreDesk-Datenbank
- LibreDesk-Anwendungsschlüssel im verschlüsselten Secret-Backup
- produktive `.env`- und rclone-Konfiguration getrennt verschlüsselt
- Repository und eine dokumentierte Liste der verwendeten Image-Versionen/Digests

Redis-Daten sind für Nextcloud üblicherweise Cache- und Lock-Zustand und werden
nicht als alleinige Wiederherstellungsquelle behandelt. Auch LibreDesk-Redis ist
keine primäre Wiederherstellungsquelle; maßgeblich sind Datenbankdump, Uploads
und der zum Sicherungsstand gehörende Anwendungsschlüssel. Ob ein Redis-Backup
benötigt wird, wird pro Anwendung dokumentiert.

## Konsistenz

Für ein konsistentes Nextcloud-Backup:

1. Wartungsfenster ankündigen.
2. Nextcloud-Wartungsmodus aktivieren.
3. PostgreSQL logisch sichern.
4. Nextcloud-Konfiguration, Apps, Themes und Daten sichern.
5. Backup auf Vollständigkeit und Lesbarkeit prüfen.
6. Wartungsmodus deaktivieren.
7. verschlüsselte Kopie auf ein externes Ziel übertragen.

Beispielbefehle werden erst nach Festlegung des Backupziels, der
Aufbewahrungsfristen und der produktiven Datenbanknamen verbindlich in ein Script
überführt. Passwörter dürfen nicht als Kommandozeilenargument oder in Logs landen.

## Aufbewahrungsvorschlag

- 7 tägliche Sicherungen
- 4 wöchentliche Sicherungen
- 6 monatliche Sicherungen
- zusätzliche Sicherung vor jedem größeren Update oder jeder Migration

Die konkrete Frist muss mit verfügbarem Speicher, Datenschutz und den
organisatorischen Anforderungen der Vereine abgestimmt werden.

## Verschlüsselung und Zugriff

- Backupziel außerhalb des VPS
- clientseitige Verschlüsselung vor der Übertragung
- eigenes Backupkonto mit minimalen Rechten
- Lösch- oder Immutable-Schutz auf dem Ziel, wenn verfügbar
- Wiederherstellungsschlüssel offline an mindestens zwei verantwortliche Personen
  übergeben
- Zugriff und Restore-Vorgang dokumentieren, ohne Secrets zu versionieren

## Restore-Test

Quartalsweise wird in einer isolierten Umgebung geprüft:

1. frischen PostgreSQL- und Nextcloud-Stack bereitstellen
2. Konfiguration, Daten und Datenbank wiederherstellen
3. Eigentümer und Dateirechte korrigieren
4. `occ maintenance:repair` und Statusprüfung ausführen
5. Login, Stichproben von Dateien, Team Folders, Office und Talk prüfen
6. Dauer, Probleme und verwendeten Backupstand dokumentieren

Ein Backup gilt nur dann als erfolgreich, wenn dieser Restore-Test bestanden wurde.

## Noch festzulegen

- externes Backupziel
- verwendetes Werkzeug und Verschlüsselungsverfahren
- maximal tolerierbarer Datenverlust (RPO)
- maximal tolerierbare Wiederherstellungszeit (RTO)
- verantwortliche Personen und Vertretung
- Alarmierung bei fehlgeschlagenem oder veraltetem Backup
