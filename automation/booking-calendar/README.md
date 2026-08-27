# Buchungsmails in den Nextcloud-Kalender

Dieser Hostdienst überträgt Buchungs- und Stornierungsmails von MyTurn und
CommonsBooking/Lale direkt in den gemeinsamen Nextcloud-Kalender. Er ersetzt die
frühere SQLite-Zwischenablage und den Slack-/Talk-Tagesdigest.

Der Anwendungscode liegt im Repository `zircula-ev/Zircula-Automation`. Dieses
Verzeichnis enthält die versionierte VPS-Integration.

## Darstellung

- Räume: ein Termin mit Anfangs- und Endzeit.
- Werkzeug und Lastenräder: ein Ausgabetermin und ein Rückgabetermin.
- Am selben Tag: ein kombinierter Termin.
- Keine Termine an den Tagen dazwischen.
- Stabile UIDs verhindern Duplikate; Stornierungen entfernen alle Rollen.

## Laufzeitpfade

- Code: `/opt/zircula/git/Zircula-Automation`
- Python: `/opt/zircula/venvs/booking-calendar`
- Secrets: `/etc/zircula-booking-importer/environment`
- Service: `zircula-booking-calendar.service`
- Timer: `zircula-booking-calendar.timer`

Die echte Environment-Datei ist nicht versioniert und erhält
`root:zircula-booking-importer 0640`. Der Dienst läuft als eigener Benutzer
ohne Login-Shell. Eine relevante Mail wird erst nach erfolgreichem CalDAV-Schritt
als gelesen markiert.

Installation, Nachtests und Rückfall stehen in
`docs/20-booking-calendar-automation.md`.
