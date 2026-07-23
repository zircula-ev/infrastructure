# Blackbox Exporter

Blackbox Exporter führt die von Prometheus angeforderten HTTP-Prüfungen aus. Die
erste Ausbaustufe prüft ausschließlich HTTPS-Endpunkte; ICMP und damit die
Capability `NET_RAW` werden nicht aktiviert.

Der Dienst veröffentlicht keinen Hostport, besitzt keinen Docker-Socket und ist
nur im Netz `zircula_monitoring` erreichbar.

## Start und Prüfung

```bash
cp .env.example .env
chmod 600 .env

docker compose config --quiet
docker compose up -d
docker compose ps
docker compose logs --tail=100 blackbox-exporter
```

Nach dem Prometheus-Start wird der Exporter über Prometheus unter **Status →
Targets** geprüft. Ein direkter interner Test ist möglich mit:

```bash
docker run --rm --network zircula_monitoring curlimages/curl:8.16.0 \
  'http://blackbox-exporter:9115/probe?module=http_2xx&target=https://cloud.zircula.org/status.php'
```

Das temporäre Curl-Image wird nur für den Test verwendet und ist kein Bestandteil
des Stacks.

## Update und Rollback

```bash
docker compose pull
docker compose up -d
docker compose ps
```

Bei Fehlern wird die vorherige Version in `.env` wiederhergestellt und der Stack
erneut erstellt.
