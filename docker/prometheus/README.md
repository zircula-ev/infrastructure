# Prometheus

Prometheus sammelt und speichert die numerischen Monitoringwerte der
Zircula-Infrastruktur. Der Dienst besitzt keinen öffentlichen Hostport und ist
nur im Netz `zircula_monitoring` erreichbar.

Die erste Ausbaustufe erfasst:

- Prometheus selbst
- Hostmetriken über Node Exporter
- öffentliche HTTPS-Endpunkte über Blackbox Exporter
- TLS-Restlaufzeiten

Anwendungsspezifische Nextcloud-, Authentik-, PostgreSQL-, Redis- und
Caddy-Metriken werden erst nach dem stabilen Baseline-Deployment ergänzt.

## Daten und Aufbewahrung

- `/srv/zircula/prometheus/data` – lokale Zeitreihendaten
- Standard: 15 Tage und maximal 5 GB
- `prometheus.yml` – Scrape-Ziele und Alertmanager
- `alerts/` – versionierte Alarmregeln

Prometheus-Daten sind Betriebsdaten und keine alleinige Wiederherstellungsquelle.
Sie werden in der ersten Backupstufe nicht priorisiert.

## Vorbereitung

```bash
sudo install -d -o 65534 -g 65534 -m 750 \
  /srv/zircula/prometheus/data

cp .env.example .env
chmod 600 .env
```

Vorher müssen `node-exporter`, `blackbox-exporter` und `alertmanager` im
Monitoring-Netz gestartet sein.

## Validierung und Start

```bash
docker compose run --rm --no-deps \
  --entrypoint promtool prometheus \
  check config /etc/prometheus/prometheus.yml

docker compose run --rm --no-deps \
  --entrypoint promtool prometheus \
  check rules /etc/prometheus/alerts/baseline.yml

docker compose config --quiet
docker compose up -d
docker compose ps
docker compose logs --tail=100 prometheus
```

Nach dem Grafana-Start werden Zielzustand und Regeln über Grafana geprüft. Für
eine temporäre Diagnose kann ein SSH-Tunnel oder ein einmaliger Curl-Container im
Monitoring-Netz verwendet werden; Port 9090 wird nicht dauerhaft veröffentlicht.

## Konfigurationsreload

Nach erfolgreicher `promtool`-Prüfung:

```bash
docker compose kill -s SIGHUP prometheus
docker compose logs --tail=100 prometheus
```

## Update und Rollback

```bash
docker compose pull
docker compose up -d
docker compose ps
```

Bei Fehlern wird die vorherige Image-Version wiederhergestellt. Das Datenverzeichnis
wird nicht gelöscht.
