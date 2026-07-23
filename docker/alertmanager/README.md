# Alertmanager

Alertmanager empfängt Prometheus-Alarme, gruppiert und dedupliziert sie und sendet
sie zunächst an Slack. Der Dienst besitzt keinen öffentlichen Hostport und ist
nur im Netz `zircula_monitoring` erreichbar.

## Secret und Daten

- `/srv/zircula/alertmanager/data` – Silences und Laufzeitdaten
- `secrets/slack_webhook_url` – lokaler Slack-Webhook, niemals versionieren
- `alertmanager.yml` – versionierte Routing- und Gruppierungsregeln

Der Slack-Webhook wird über `slack_api_url_file` gelesen und erscheint dadurch
nicht als Umgebungsvariable oder Kommandozeilenargument. Der konfigurierte
Channel `#it-support` entspricht dem vorhandenen Slack-Webhook; bei modernen
Incoming Webhooks ist häufig der im Webhook hinterlegte Channel maßgeblich.

Compose erzeugt die Secret-Datei nicht automatisch und ist mit
`create_host_path: false` absichtlich so konfiguriert, dass der Start bei einer
fehlenden Datei abbricht. Dadurch wird an dieser Stelle kein root-eigenes
Verzeichnis angelegt und kein leerer beziehungsweise unsicherer Ersatzwert
verwendet.

## Vorbereitung

```bash
sudo install -d -o 65534 -g 65534 -m 750 \
  /srv/zircula/alertmanager/data

install -d -m 700 secrets
install -m 600 /dev/null secrets/slack_webhook_url

read -rsp "Slack-Webhook: " SLACK_WEBHOOK
printf '\n'
printf '%s' "$SLACK_WEBHOOK" > secrets/slack_webhook_url
unset SLACK_WEBHOOK

sudo chown 65534:65534 secrets/slack_webhook_url
sudo chmod 400 secrets/slack_webhook_url
```

Der echte Webhook darf nicht in Terminalausgaben, Git, Tickets oder Chats
kopiert werden. Alertmanager läuft als UID/GID 65534 und benötigt deshalb das
Eigentum an der nur lesbaren Secret-Datei. Änderungen erfolgen künftig mit
`sudo`; der Wert wird nicht zum interaktiven Benutzer zurückgelesen.

Rechte prüfen, ohne den Inhalt auszugeben:

```bash
sudo stat -c '%U:%G %a %n' \
  secrets \
  secrets/slack_webhook_url
```

Erwartet werden `timo:timo 700` für das Verzeichnis und `nobody:nogroup 400`
für die Datei. Das Verzeichnis bleibt beim Deploymentbenutzer, damit Git und
Compose den Pfad traversieren können; im Container wird ausschließlich die
Datei eingebunden.

## Validierung und Start

```bash
docker compose run --rm --no-deps \
  --entrypoint amtool alertmanager \
  check-config /etc/alertmanager/alertmanager.yml

docker compose config --quiet
docker compose up -d
docker compose ps
docker compose logs --tail=100 alertmanager
```

## Alarmtest

Der Alarmtest erfolgt nach dem Prometheus-Deployment durch eine befristete
Testregel. Nach erfolgreicher Slack-Zustellung wird die Testregel wieder entfernt.
Ein produktiver Dienst wird dafür nicht gestoppt.

## Update und Rollback

```bash
docker compose pull
docker compose up -d
docker compose ps
```

Bei Fehlern wird die vorherige Image-Version wiederhergestellt. Silences und
Laufzeitdaten bleiben dabei erhalten.
