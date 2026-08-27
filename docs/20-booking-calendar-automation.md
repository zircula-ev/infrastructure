# 20 – Buchungsmails in den Nextcloud-Kalender

## Ziel

MyTurn- und CommonsBooking/Lale-Mails werden direkt per CalDAV in **Ausleihen &
Buchungen (Kalender)** übertragen. SQLite sowie Slack-/Talk-Digest entfallen.

Der konkrete CalDAV-Pfad und alle Zugangsdaten bleiben ausschließlich in
`/etc/zircula-booking-importer/environment`.

## Verifiziert am 27.08.2026

- Absenderdomains `myturn.com` und `lale-bremerhaven.de`
- reale MyTurn- und Lale-Mails vollständig geparst
- CalDAV-Discovery sowie Anlegen, Lesen und Löschen
- End-to-End-Test mit zwei Ausgabe-/Rückgabeterminen
- keine Termine an den Zwischentagen
- fünf automatisierte Anwendungstests

## Rollout

Voraussetzung: Beide Änderungen befinden sich in ihren jeweiligen
`main`-Branches.

1. Benutzer und Verzeichnisse anlegen:

```bash
sudo useradd --system --home-dir /nonexistent --shell /usr/sbin/nologin zircula-booking-importer
sudo install -d -m 755 /opt/zircula/venvs
sudo install -d -o root -g zircula-booking-importer -m 750 /etc/zircula-booking-importer
```

Vor `useradd` wird geprüft, ob der Benutzer bereits existiert.

2. Anwendung installieren:

```bash
cd /opt/zircula/git
git clone https://github.com/zircula-ev/Zircula-Automation.git
python3 -m venv /opt/zircula/venvs/booking-calendar
/opt/zircula/venvs/booking-calendar/bin/pip install --requirement /opt/zircula/git/Zircula-Automation/requirements.txt
```

3. `automation/booking-calendar/environment.example` nach
`/etc/zircula-booking-importer/environment` kopieren, lokal befüllen und
schützen:

```bash
sudo chown root:zircula-booking-importer /etc/zircula-booking-importer/environment
sudo chmod 640 /etc/zircula-booking-importer/environment
```

4. Units installieren und prüfen:

```bash
sudo install -m 644 automation/booking-calendar/systemd/zircula-booking-calendar.service /etc/systemd/system/
sudo install -m 644 automation/booking-calendar/systemd/zircula-booking-calendar.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo bash automation/booking-calendar/scripts/preflight.sh
sudo systemd-analyze verify /etc/systemd/system/zircula-booking-calendar.service /etc/systemd/system/zircula-booking-calendar.timer
```

5. Timer zunächst deaktiviert lassen und einen Lauf prüfen:

```bash
sudo systemctl start zircula-booking-calendar.service
systemctl show zircula-booking-calendar.service -p ActiveState -p SubState -p Result -p ExecMainStatus
sudo journalctl -u zircula-booking-calendar.service --since=-10m --no-pager
```

Erst nach fachlicher Kalender- und Mailprüfung:

```bash
sudo systemctl enable --now zircula-booking-calendar.timer
```

## Nachtests

- Service endet mit `Result=success` und `ExecMainStatus=0`.
- Ausgabe, Rückgabe und Raumzeiten stimmen.
- Wiederholungen erzeugen keine Duplikate.
- Fehlerhafte Mails bleiben ungelesen.
- Das Journal enthält keine Secrets.
- `systemctl list-timers` zeigt den nächsten Lauf.

## Rückfall

```bash
sudo systemctl disable --now zircula-booking-calendar.timer
```

Danach Dienst deaktiviert lassen. Bei möglicher Secret-Kompromittierung werden
IMAP- und App-Passwort rotiert. Mails oder Primärdaten müssen für den Rückfall
nicht gelöscht werden.
