# Verschlüsseltes VPS-Backup nach nctest

Diese Komponente ist das vorläufige externe Backupziel, bis ein dauerhaftes
vertragliches oder lokales Ziel beschlossen ist. nctest bleibt ein
Übergangssystem und darf nicht die einzige Wiederherstellungsquelle werden.

## Datenfluss

1. Der VPS versetzt Nextcloud für den konsistenten Sicherungslauf in den
   Wartungsmodus.
2. PostgreSQL wird logisch mit `pg_dumpall` gesichert.
3. Vaultwarden erzeugt eine anwendungseigene SQLite-Sicherung.
4. Grafanas SQLite-Datenbank wird über die SQLite-Backup-API kopiert.
5. Die neu erzeugten Datenbankkopien werden vor der Sicherung auf Integrität
   geprüft und nach dem Lauf wieder aus dem unverschlüsselten Staging entfernt.
6. Restic sichert die produktiven Dateidaten, Konfigurationen, Secrets und Dumps
   clientseitig verschlüsselt.
7. Ein dedizierter SSH-Benutzer stellt ausschließlich das verschlüsselte
   Exportverzeichnis über `rrsync -ro` bereit.
8. nctest spiegelt den Export und erstellt danach einen ZFS-Snapshot.

Der private SSH-Key auf nctest besitzt keine Shell, kein Forwarding und keinen
Schreibzugriff auf dem VPS. Der Restic-Schlüssel wird getrennt davon offline an
mindestens zwei kontrollierten Orten verwahrt.

## Wartungsseite während der Sicherung

Während der konsistenten Sicherung zeigt Nextcloud eine Wartungsseite. Die
versionierte Anpassung soll ausschließlich einen festen, ehrlichen Hinweis
verwenden und keine dynamische Fortschritts- oder Zeitangabe vortäuschen:

> Die WERK × ZIRCULA Cloud wird derzeit gewartet oder gesichert und ist in Kürze
> wieder verfügbar. Bei unerwartet langer Nichterreichbarkeit:
> itsupport@zircula.org

Nextclouds eingebauter Wartungsmodus unterstützt keinen individuellen
Begründungstext. Die Anpassung wird deshalb als kleine, persistente
Theme-Überschreibung umgesetzt und nach jedem Nextcloud-Major-Update gegen die
aktuelle Core-Vorlage geprüft. Die produktive Einbindung erfolgt außerhalb eines
laufenden Backups und erst nach einem Test des automatischen Ein- und
Ausschaltens des Wartungsmodus.

## Schutzumfang

Gesichert werden insbesondere:

- Nextcloud HTML, Konfiguration, Apps und Nutzerdaten
- Authentik-Daten, Zertifikate und Templates
- Caddy-Zertifikats- und Laufzeitdaten
- Grafana-Daten über eine konsistente SQLite-Kopie
- Vaultwarden über die eingebaute SQLite-Sicherung sowie Anhänge und Schlüssel
- LibreDesk-Uploads und alle PostgreSQL-Datenbanken
- Alertmanager-Zustand
- produktive lokale `.env`- und Secret-Dateien im Infrastrukturcheckout
- versionierte Betriebs- und Compose-Konfiguration

Bewusst ausgeschlossen sind rohe PostgreSQL-Datendateien, Redis-Cache- und
Queuezustände, Prometheus-Zeitreihen, Git-Objektdaten, der alte partielle
Vaultwarden-Diagnosepfad, automatisch erzeugte `db_*.sqlite3`-Arbeitskopien und
  der leere Minecraft-Bootstrap-Platzhalter. Die geprüfte Vaultwarden-Datenbank
  liegt stattdessen nur während des Laufs im geschützten Staging und wird in
  dieser Form in Restic aufgenommen.

## Aufbewahrung

Restic behält 7 tägliche, 4 wöchentliche und 6 monatliche Sicherungen. nctest
behält zusätzlich die letzten 14 erfolgreichen Spiegelstände als ZFS-Snapshots.
Die alten Clouds bleiben während der Übergangsphase eine zusätzliche
Rückfallquelle für die migrierten Bestandsdaten.

## VPS installieren

Vor dem Deployment muss der öffentliche nctest-Key vorliegen. Sein geprüfter
Fingerprint lautet:

```text
SHA256:kycgEnZte0Wh5/IkUrGEiEzJJb1WL9ozrYMA/Om3PQ0
```

Pakete und Systemkonto:

```bash
sudo apt update
sudo apt install restic

sudo groupadd --system zircula-backup

sudo useradd \
  --system \
  --gid zircula-backup \
  --home-dir /var/lib/zircula-backup \
  --create-home \
  --shell /bin/bash \
  zircula-backup

sudo passwd --lock zircula-backup

sudo install -d \
  -o zircula-backup \
  -g zircula-backup \
  -m 700 \
  /var/lib/zircula-backup/.ssh

sudo install -d \
  -o root \
  -g zircula-backup \
  -m 750 \
  /opt/zircula/backups/export
```

Die Befehle `groupadd` und `useradd` werden nur beim Erstsetup ausgeführt.
Vor einer Wiederholung wird mit `getent group zircula-backup` und
`id zircula-backup` geprüft, ob die Objekte bereits existieren.

Public Key eingeschränkt autorisieren:

```bash
read -r backup_public_key

printf '%s %s\n' \
  'restrict,command="/usr/bin/rrsync -ro /opt/zircula/backups/export"' \
  "${backup_public_key}" \
  | sudo tee /var/lib/zircula-backup/.ssh/authorized_keys \
  >/dev/null

unset backup_public_key

sudo chown \
  zircula-backup:zircula-backup \
  /var/lib/zircula-backup/.ssh/authorized_keys

sudo chmod 600 \
  /var/lib/zircula-backup/.ssh/authorized_keys
```

Bei `read` wird die vollständige einzelne Zeile aus
`~/.ssh/zircula_vps_backup_ed25519.pub` auf nctest eingefügt. Private
Schlüssel werden niemals kopiert oder angezeigt.

Restic-Schlüssel und Komponenten:

```bash
sudo install -d -o root -g root -m 700 /etc/zircula-backup

sudo sh -c '
  umask 077
  openssl rand -base64 48 \
    > /etc/zircula-backup/restic-password
'

sudo install -o root -g root -m 600 \
  backup/vps/restic-excludes \
  /etc/zircula-backup/restic-excludes

sudo install -o root -g root -m 755 \
  backup/vps/zircula-backup \
  /usr/local/sbin/zircula-backup

sudo install -o root -g root -m 644 \
  backup/vps/systemd/zircula-backup.service \
  backup/vps/systemd/zircula-backup.timer \
  /etc/systemd/system/

sudo systemctl daemon-reload
```

Der Inhalt von `/etc/zircula-backup/restic-password` wird einmalig kontrolliert
offline hinterlegt, aber niemals in Chat, Git, Tickets oder Logs kopiert.

## nctest installieren

```bash
sudo zfs create \
  -o mountpoint=/DATA_Store/vps-backup \
  -o compression=lz4 \
  -o atime=off \
  DATA_Store/vps-backup

sudo install -d -o root -g root -m 700 /etc/zircula-backup

sudo install -o root -g root -m 600 \
  /home/timo/.ssh/zircula_vps_backup_ed25519 \
  /etc/zircula-backup/vps-ed25519

sudo install -o root -g root -m 755 \
  backup/nctest/zircula-backup-pull \
  /usr/local/sbin/zircula-backup-pull

sudo install -o root -g root -m 644 \
  backup/nctest/systemd/zircula-backup-pull.service \
  backup/nctest/systemd/zircula-backup-pull.timer \
  /etc/systemd/system/

sudo install -d -o root -g root -m 750 \
  /DATA_Store/vps-backup/mirror

sudo systemctl daemon-reload
```

## Prüf- und Aktivierungsreihenfolge

1. `bash -n` für beide Skripte.
2. SSH-Negativtest: Shellzugriff des Backupkontos muss scheitern.
3. Read-only-Rsync-Listentest muss funktionieren.
4. Restic-Schlüssel offline sichern.
5. Ersten VPS-Backupservice manuell starten.
6. Nextcloud-Wartungsmodus muss danach wieder deaktiviert sein.
7. Restic `snapshots` und `check` auf dem VPS.
8. nctest-Pullservice manuell starten.
9. Spiegel, ZFS-Snapshot und Dateianzahlen prüfen.
10. kleine Datei isoliert nach `/tmp` wiederherstellen und vergleichen.
11. Prometheus-Regeln mit `promtool` prüfen und erst nach vorhandenen
    Backupmetriken neu laden.
12. Erst danach beide Timer aktivieren.

```bash
sudo systemctl enable --now zircula-backup.timer
sudo systemctl enable --now zircula-backup-pull.timer
```

Die beiden Aktivierungsbefehle laufen auf ihren jeweiligen Hosts.

## Restore-Grundsatz

Ein Restore erfolgt niemals direkt über die Produktionsdaten. Zuerst wird ein
gewählter Snapshot mit Restic in ein leeres, isoliertes Verzeichnis
wiederhergestellt. PostgreSQL wird aus `postgres-all.sql.zst` rekonstruiert;
Grafana nutzt die geprüfte SQLite-Kopie und Vaultwarden die jüngste eingebaute
Sicherungsdatei. Erst nach Integritäts- und Anwendungstests werden produktive
Pfade ersetzt.

## Grenzen der Übergangslösung

- nctest kann versehentlich ausgeschaltet werden.
- nctest überwacht seinen eigenen Ausfall nicht unabhängig.
- Das lokale Restic-Repository auf dem VPS ist nur eine Transfer- und
  Rückfallebene; maßgeblich ist die externe Kopie.
- Ein kompromittierter VPS kann zukünftige Backupstände beeinflussen. Die
  ZFS-Snapshots auf nctest begrenzen die rückwirkende Wirkung.
- Ein dauerhaftes externes Ziel mit organisatorisch geregeltem Zugriff bleibt
  erforderlich.
