# Node Exporter

Node Exporter stellt Prometheus ausschließlich lesende Hostmetriken des VPS zur
Verfügung. Der Dienst besitzt keinen öffentlichen Hostport und ist nur im
Monitoring-Netz erreichbar.

## Daten und Rechte

- `/proc`, `/sys` und `/` werden ausschließlich lesend eingebunden.
- `/srv/zircula/node-exporter/textfile` enthält später atomar erzeugte eigene
  Metriken, etwa Backupalter oder Neustartbedarf.
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
