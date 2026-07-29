# Node Exporter

Node Exporter stellt Prometheus ausschließlich lesende Hostmetriken des VPS zur
Verfügung. Der Dienst besitzt keinen öffentlichen Hostport und ist nur im
Monitoring-Netz erreichbar.

## Daten und Rechte

- `/proc`, `/sys` und `/` werden ausschließlich lesend eingebunden.
- `/srv/zircula/node-exporter/textfile` enthält atomar erzeugte eigene Metriken,
  etwa Backupalter oder den Paket- und Neustartstatus.
- Der Docker-Socket wird nicht eingebunden.
- Das Container-Dateisystem ist schreibgeschützt; alle Capabilities werden
  entfernt.

Der Root-Dateisystem-Mount ist für Hostmetriken erforderlich, erlaubt aber keinen
Schreibzugriff. Neue Textfile-Collector-Skripte werden einzeln dokumentiert und
dürfen keine Secrets oder frei wählbaren Prometheus-Labels aus Benutzerdaten
erzeugen.

## Vorbereitung und Start

```bash
sudo install -d -o root -g root -m 755 \
  /srv/zircula/node-exporter/textfile

docker compose config --quiet
docker compose up -d
docker compose ps
```

## Host-Updateprüfung

`scripts/zircula-host-update-metrics` aktualisiert ausschließlich die lokalen
APT-Paketlisten und simuliert ein Upgrade. Es installiert keine Pakete und führt
keinen Neustart aus. Das Ergebnis wird atomar für den Textfile Collector
geschrieben:

- Anzahl verfügbarer Paketupdates
- Anzahl verfügbarer Sicherheitsupdates
- Neustartbedarf aus `/var/run/reboot-required`
- Zeitpunkt der letzten erfolgreichen Prüfung

Installation auf dem VPS:

```bash
sudo install -o root -g root -m 755 \
  scripts/zircula-host-update-metrics \
  /usr/local/sbin/zircula-host-update-metrics

sudo install -o root -g root -m 644 \
  systemd/zircula-host-update-metrics.service \
  systemd/zircula-host-update-metrics.timer \
  /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl start zircula-host-update-metrics.service
sudo systemctl enable --now zircula-host-update-metrics.timer
```

Der Timer läuft täglich, zehn Minuten nach einem verpassten Start und mit einer
zufälligen Verzögerung von bis zu 30 Minuten. Ein Fehler ersetzt die letzte
erfolgreiche Metrikdatei nicht; Prometheus meldet veraltete Werte nach 36 Stunden.

Die Unit verwendet weiterhin `NoNewPrivileges`, `PrivateTmp`,
`ProtectHome`, `ProtectSystem=full` und `ProtectControlGroups`. APT muss
seine Downloadprozesse vorübergehend auf den Systembenutzer `_apt` (UID 42)
absenken. Isolierte systemd-Tests auf dem eingesetzten Ubuntu-26.04-Host haben
bestätigt, dass `RestrictSUIDSGID`, `ProtectKernelTunables`,
`ProtectKernelModules`, `LockPersonality` und `RestrictRealtime` diesen
Wechsel dort jeweils mit `EPERM` verhindern. Diese Einstellungen werden deshalb
bewusst nicht für genau diese rein prüfende Oneshot-Unit gesetzt. Das Skript
installiert keine Pakete und führt keinen Neustart aus.

Prüfung:

```bash
systemctl status --no-pager zircula-host-update-metrics.service
systemctl list-timers --all zircula-host-update-metrics.timer

cat /srv/zircula/node-exporter/textfile/system_updates.prom

docker run --rm --network zircula_monitoring \
  curlimages/curl:8.16.0 \
  --fail --silent http://node-exporter:9100/metrics \
  | grep '^zircula_host_'
```

Bei einer Änderung des Skripts muss die versionierte Fassung erneut nach
`/usr/local/sbin` installiert werden. Ein Rollback deaktiviert zunächst den
Timer und entfernt anschließend ausschließlich die installierte Unit, das
Skript und `system_updates.prom`.

## Prüfung

```bash
docker compose logs --tail=100 node-exporter
docker inspect --format '{{range $name, $_ := .NetworkSettings.Networks}}{{$name}} {{end}}' \
  node-exporter
docker inspect --format '{{range .Mounts}}{{println .Source .Destination .RW}}{{end}}' \
  node-exporter
```

Erwartet werden ausschließlich `zircula_monitoring`, kein Hostport, kein
Docker-Socket und `false` für alle Host-Mounts in der Spalte `RW`.

## Update und Rollback

Die Image-Version steht direkt in `compose.yaml`, damit Dependabot sie erkennen
und als Pull Request aktualisieren kann. Vor dem Update werden Release Notes und
Prometheus-Kompatibilität geprüft.

```bash
docker compose pull
docker compose up -d
docker compose ps
```

Ein Rollback erfolgt durch Wiederherstellen der vorherigen Version und erneutes
`docker compose up -d`.
