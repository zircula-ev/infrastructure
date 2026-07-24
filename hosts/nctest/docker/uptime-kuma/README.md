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

Alle vier Monitore verwenden ein Intervall von 60 Sekunden, drei Wiederholungen,
30 Sekunden Wiederholungsabstand, 20 Sekunden Request-Timeout und akzeptieren
HTTP-Status 200 bis 299. TLS-Fehler werden nicht ignoriert; die
Zertifikatsablaufwarnung ist aktiviert. Benachrichtigungen gehen über den
bestehenden Monitoring-Webhook an Slack.

Die vollständige Alarmkette wurde mit einem temporären HTTP-Monitor gegen den
absichtlich geschlossenen lokalen Port `127.0.0.1:9` geprüft. Nach der
DOWN-Nachricht wurde dessen Ziel auf den erreichbaren Nextcloud-Statusendpunkt
geändert und die UP-/Entwarnungsnachricht bestätigt. Der Testmonitor wurde
anschließend gelöscht; kein produktiver Dienst wurde gestoppt.

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
