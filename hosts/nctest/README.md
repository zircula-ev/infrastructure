# nctest

nctest ist ein aus vorhandener Hardware aufgebauter, intern betriebener Ubuntu-
Host. Er ist Spielwiese und Standort einiger lokaler Hilfsdienste, aber kein
hochverfügbarer Produktionsserver.

## Dokumentierter Stand vom 24.07.2026

- Ubuntu 26.04 LTS
- Intel Core i5-2400, vier Kerne
- 11 GiB RAM
- Docker Engine und Docker Compose
- Tailscale für administrativen Zugriff
- ZFS-Pool `DATA_Store` aus zwei gespiegelten vdevs
- ungefähr 2,5 TiB verfügbar
- monatlicher ZFS-Scrub ohne bekannte Datenfehler

## Rollen

- Shinobi zeichnet Kameras aus dem lokalen Hausnetz für wenige Tage auf.
- Uptime Kuma überwacht als vorläufige externe Instanz acht öffentliche
  Endpunkte beziehungsweise Ports des Manitu-VPS.
- Alle Monitore alarmieren während der Übergangsphase über Slack; zentrale
  Ausfälle gehen zusätzlich per SMTP an `itadmin@zircula.org` und
  `itsupport@zircula.org`.
- nctest dient vorläufig als zusätzliches Backupziel, bis Vorstand und Vereine
  das dauerhafte externe beziehungsweise lokale Backupziel beschlossen haben.
- kleinere Buchungs-, Mail- und Slack-Skripte existieren außerhalb des derzeit
  versionierten Umfangs.

Die historische lokale Test-Nextcloud und das lokale Collabora werden außer
Betrieb genommen, da `cloud.zircula.org` produktiv bereitsteht. Ihre alten
Compose-Dateien und Laufzeitdaten werden in diesem Repository nicht nachträglich
als Sollzustand dokumentiert.

## Grenzen

- Mitglieder schalten den Rechner gelegentlich versehentlich aus.
- Uptime Kuma kann seinen eigenen vollständigen Ausfall nicht melden.
- nctest ist deshalb weder alleinige Backupquelle noch endgültiger externer
  Monitoringstandort.
- Kameraaufzeichnungen gehören nicht in das Plattformbackup.
- Shinobi bleibt bewusst im Hausnetz; eine Verlagerung auf den VPS würde
  dauerhafte Videostreams, VPN-Abhängigkeit und eine unnötige gemeinsame
  Sicherheitsdomäne erzeugen.

## Repository und Deployment

Der gewünschte Checkoutpfad lautet:

```text
/opt/zircula/git/infrastructure
```

Da die Organisation Deploy-Keys nicht zulässt, erfolgt der private
Repositoryzugriff interaktiv über einen zeitlich begrenzten Fine-grained
Personal Access Token. Der Token ist ausschließlich für
`zircula-ev/infrastructure` freigegeben und besitzt nur `Contents: Read-only`.
Er wird weder in der Remote-URL noch dauerhaft im Git Credential Store
hinterlegt. Änderungen entstehen in Feature-Branches und werden nicht direkt auf
nctest committet.

Produktive `.env`, rclone-Konfigurationen, Slack-Webhooks, SMTP-Zugangsdaten,
Kamerazugangsdaten und Uptime-Kuma-Laufzeitdaten bleiben ausschließlich lokal.

## Betrieb

Vor einem Neustart werden mindestens geprüft:

```bash
docker ps
systemctl --failed
sudo zpool status -v DATA_Store
```

Nach einem Neustart:

```bash
docker ps
tailscale status
tailscale serve status
sudo zpool status -v DATA_Store
```

Der Zustand von Shinobi und den Backupjobs wird getrennt geprüft. Uptime Kuma
wird zusätzlich über den Stack unter
`hosts/nctest/docker/uptime-kuma` sowie die unveränderte Tailscale-Serve-Route
auf HTTPS-Port 8443 geprüft.
