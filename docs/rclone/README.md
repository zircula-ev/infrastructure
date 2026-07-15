# rclone

## Zweck

`rclone` wird derzeit für Migration und kontrollierte Datenübertragungen zwischen
den bisherigen Nextcloud-Instanzen und der zentralen Nextcloud verwendet.

Die Konfiguration `rclone.conf` enthält Zugangsdaten, liegt ausschließlich lokal
auf dem Server und wird nicht versioniert.

## Konfigurierte Remotes

| Remote | Zweck |
|---|---|
| `Werkhaus` | bisherige WERK-Cloud |
| `nextcloud.zircula` | bisherige Zircula-Cloud |
| `cloud.zircula` | zentrale produktive Nextcloud |

## Verbindungstest

```bash
rclone lsd Werkhaus:
rclone lsd nextcloud.zircula:
rclone lsd cloud.zircula:
```

Ausgaben können Dateinamen und organisatorische Informationen enthalten und
werden vor einer Weitergabe geprüft.

## Migration

- zunächst ausschließlich lesende Listen- und Prüfbefehle
- Kopier- und Synchronisationsrichtung vor jedem Lauf kontrollieren
- `--dry-run` verwenden, bevor Daten verändert oder gelöscht werden könnten
- keine Löschoptionen ohne separates Backup und Freigabe
- nach der Übertragung Nextcloud-Dateien, Eigentümer und Indizes kontrollieren

## Abgrenzung zum Backup

rclone ist ein mögliches Transportwerkzeug, aber die vorhandenen Migrationsremotes
sind noch kein produktives Backupkonzept. Ein Backup benötigt zusätzlich:

- ein externes, getrenntes Ziel
- clientseitige Verschlüsselung
- definierte Aufbewahrung
- Alarmierung bei Fehlern
- PostgreSQL-Dumps und Nextcloud-Konfiguration
- regelmäßige Restore-Tests

Der verbindliche Backup- und Restore-Prozess wird in
`docs/07-backup-restore.md` dokumentiert.

## Sicherheit

- `rclone.conf` restriktiv berechtigen und verschlüsselt sichern
- vor Änderungen eine verschlüsselte Kopie der Konfiguration erstellen
- Zugangsdaten niemals in Kommandozeilen, GitHub, Tickets oder Chats einfügen
- Backupkonten nur mit den erforderlichen Rechten ausstatten

