# Uptime Kuma auf nctest

Uptime Kuma prüft die öffentlichen Zircula-Dienste von außerhalb des Manitu-VPS.
nctest ist kein hochverfügbarer Monitoringstandort; der Rechner kann versehentlich
ausgeschaltet werden. Diese Instanz ist deshalb eine dokumentierte Übergangslösung
und ersetzt keine spätere unabhängige externe Überwachung.

## Zugriff und Sicherheit

- Port 3001 ist ausschließlich an `127.0.0.1` gebunden.
- Die Administrationsoberfläche wird nur innerhalb des Tailnets über Tailscale
  Serve erreichbar gemacht.
- Der Docker-Socket wird nicht eingebunden.
- Das offizielle Rootless-Image läuft als UID/GID 1000 und erhält keine Linux-
  Capabilities.
- Die SQLite-Daten liegen lokal auf ZFS und nicht auf NFS.
- Die lokale Anmeldung bleibt aktiviert; das eigenständige Administratorkonto ist
  mit einem eindeutigen Passwort und TOTP geschützt.
- Die primäre Basis-URL lautet
  `https://nctest.tailf7eaa5.ts.net:8443`.
- Slack-Webhooks und Uptime-Kuma-Daten werden nicht versioniert.
- Die erste Ausbaustufe verwendet ausschließlich HTTP(S)- und gegebenenfalls
  TCP-Monitore. ICMP/Ping ist bewusst nicht aktiviert; deshalb bleiben alle
  Linux-Capabilities einschließlich `NET_RAW` entfernt.

Falls später ICMP fachlich erforderlich wird, werden zuerst Alternativen und ein
isolierter Funktionstest geprüft. `NET_RAW` wird nur als einzeln dokumentierte
Capability ergänzt und nicht vorsorglich freigeschaltet.

## Vorbereitung

Vor dem Anlegen des Datasets den Poolzustand prüfen:

```bash
sudo zpool status -v DATA_Store
```

Danach einmalig:

```bash
sudo zfs create \
  -o mountpoint=/DATA_Store/uptime-kuma \
  -o compression=lz4 \
  DATA_Store/uptime-kuma

sudo chown -R timo:timo /DATA_Store/uptime-kuma
sudo chmod 750 /DATA_Store/uptime-kuma

cp .env.example .env
chmod 600 .env
```

Auf `nctest` gehört UID/GID 1000 dem Benutzer `timo`. Das Rootless-Image
verwendet intern UID/GID 1000 als Benutzer `node`; dadurch kann es ohne
Root-Rechte in das Dataset schreiben. Vor dem ersten Start wurde dieser Zugriff
isoliert mit `--network none`, `cap_drop: ALL` und `no-new-privileges` geprüft.

## Start und Tailscale-Zugriff

```bash
docker compose config --quiet
docker compose up -d
docker compose ps
docker compose logs --tail=100 uptime-kuma

curl -fsS http://127.0.0.1:3001/ >/dev/null \
  && echo "Uptime Kuma lokal erreichbar"

docker inspect --format \
  'user={{.Config.User}} privileged={{.HostConfig.Privileged}} ports={{json .NetworkSettings.Ports}}' \
  uptime-kuma

docker inspect --format \
  'cap_drop={{json .HostConfig.CapDrop}} security={{json .HostConfig.SecurityOpt}}' \
  uptime-kuma

tailscale serve status
sudo tailscale serve --bg --https=8443 http://127.0.0.1:3001
tailscale serve status
```

Uptime Kuma ist danach ausschließlich im Tailnet unter
`https://nctest.tailf7eaa5.ts.net:8443` erreichbar. Die bestehende
Tailscale-Serve-Route auf HTTPS-Port 443 bleibt unverändert. Die Adresse wird
nicht im öffentlichen DNS veröffentlicht. Der erste Statusaufruf stellt sicher,
dass keine vorhandene Serve-Konfiguration unbemerkt ersetzt wird.

Nur die Kuma-Route wird bei Bedarf wieder entfernt:

```bash
sudo tailscale serve --https=8443 off
tailscale serve status
```

## Eingerichtete Monitore

| Name | Typ | Ziel | Inhaltsprüfung |
|---|---|---|---|
| Nextcloud | HTTP(s) – Keyword | `https://cloud.zircula.org/status.php` | `"maintenance":false` |
| Authentik | HTTP(s) | `https://auth.zircula.org/-/health/ready/` | – |
| Collabora | HTTP(s) – Keyword | `https://office.zircula.org/hosting/discovery` | `wopi-discovery` |
| Nextcloud Talk HPB | HTTP(s) | `https://talk.cloud.zircula.org/api/v1/welcome` | – |
| LibreDesk | HTTP(s) – Keyword | `https://support.zircula.org/health` | `"status":"success"` |
| Grafana | HTTP(s) – Keyword | `https://monitoring.zircula.org/api/health` | `"database":"ok"` |
| Vaultwarden | HTTP(s) | `https://vault.zircula.org/alive` | – |
| Zircula VPS HTTPS | TCP Port | `195.90.217.88:443` | – |

Die HTTP-Monitore verwenden ein Intervall von 60 Sekunden und drei
Wiederholungen. Der Wiederholungsabstand liegt je nach Monitor zwischen 30 und
60 Sekunden; dadurch führt ein einzelner kurzer Fehler nicht sofort zu einer
Benachrichtigung. Der Request-Timeout beträgt 20 Sekunden. Erfolgreich sind
HTTP-Status 200 bis 299. TLS-Fehler werden nicht ignoriert und die
Zertifikatsablaufwarnung bleibt aktiv.

Der TCP-Monitor prüft bewusst nur, ob der öffentliche HTTPS-Port des VPS
erreichbar ist. Er unterscheidet einen vollständigen VPS-/Caddy-Ausfall von
einem Fehler einer einzelnen Anwendung.

## Benachrichtigungsrouting

Uptime Kuma verwaltet Benachrichtigungsziele in seiner lokalen
Laufzeitdatenbank. Unter **Settings → Notifications** existieren zwei getrennte
Ziele:

### Slack – Übergang

Der bestehende Monitoring-Webhook bleibt während der Slack-Übergangsphase an
allen Monitoren aktiviert. Er wird erst entfernt, wenn der Ersatzweg unter
realen Bedingungen geprüft wurde.

### E-Mail – kritischer externer Ausfall

Die SMTP-Benachrichtigung verwendet:

| Feld | Wert |
|---|---|
| Benachrichtigungstyp | Email (SMTP) |
| Name | `E-Mail – kritischer externer Ausfall` |
| SMTP-Server | `mail.manitu.de` |
| Port | `465` |
| Sicherheit | TLS |
| Benutzername | `itadmin@zircula.org` |
| Absender | `itadmin@zircula.org` |
| Empfänger | `itadmin@zircula.org` |
| CC | `itsupport@zircula.org` |

Das Passwort wird nur in Uptime Kumas SQLite-Datenbank gespeichert und nicht in
Git oder dieser Dokumentation. Die Benachrichtigung wird nicht als pauschaler
Standard für neue Monitore aktiviert, sondern gezielt diesen kritischen
Monitoren zugewiesen:

- Zircula VPS HTTPS
- Nextcloud
- Authentik
- LibreDesk

Damit erreicht ein vollständiger oder zentraler Ausfall den technischen
Verteiler direkt. Die Kopie an `itsupport@zircula.org` bleibt im externen
Manitu-Postfach erhalten und wird von LibreDesk nach dessen Wiederkehr als
Ticket eingelesen.

Collabora, Talk HPB, Grafana und das noch nicht allgemein ausgerollte
Vaultwarden senden zunächst nur an Slack. Ihre spätere E-Mail-Eskalation wird
nach Beobachtung des Alarmvolumens entschieden.

Benachrichtigungsziele werden pro Monitor unter **Edit → Notifications**
zugeordnet. Geplante Arbeiten erhalten vorher ein Maintenance Window, damit
erwartete DOWN-/UP-Folgen keine Tickets erzeugen.

## Funktionstest

Die vorhandenen und neu ergänzten Monitore wurden mit ihren realen Endpunkten
erfolgreich geprüft. Die vollständige Slack-Alarmkette wurde zusätzlich mit
einem temporären HTTP-Monitor gegen den absichtlich geschlossenen lokalen Port
`127.0.0.1:9` getestet.

Nach Einrichtung des SMTP-Ziels wird derselbe ungefährliche Negativtest einmal
mit der kritischen E-Mail-Benachrichtigung wiederholt. Erwartet werden:

1. DOWN-Nachricht an Slack,
2. E-Mail an `itadmin@zircula.org`,
3. LibreDesk-Ticket über `itsupport@zircula.org`,
4. nach Korrektur des Ziels eine UP-/Entwarnung.

Der Testmonitor wird danach gelöscht. Kein produktiver Dienst wird dafür
gestoppt.

## Updates und Datenprüfung

```bash
docker compose pull
docker compose up -d
docker compose ps
docker compose logs --tail=100 uptime-kuma
sudo zfs list DATA_Store/uptime-kuma
```

Vor Major-Updates werden die Uptime-Kuma-Release-Notes und ein ZFS-Snapshot des
Datasets geprüft. Snapshots ersetzen kein separates Backup der Konfiguration.
