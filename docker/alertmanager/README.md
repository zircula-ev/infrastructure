# Alertmanager

Alertmanager empfängt Prometheus-Alarme, gruppiert und dedupliziert sie und
verteilt sie nach Schweregrad. Slack-Benachrichtigungen sind deaktiviert.
Warnungen bleiben in Prometheus und Grafana sichtbar. Kritische Alarme werden
per E-Mail an LibreDesk und die technische Verteileradresse gesendet.

Der Dienst besitzt keinen öffentlichen Hostport und ist nur im Netz
`zircula_monitoring` erreichbar.

## Routing

| Alarm | Slack | LibreDesk | `itadmin@zircula.org` | Wiederholung |
|---|---|---|---|---|
| `severity="warning"` | nein | nein | nein | keine Zustellung |
| `HostRebootRequired` | nein | nein | nein | keine Zustellung |
| `severity="critical"` | nein | ja | ja | 12 Stunden |

Nicht zugestellte Warnungen werden vom Receiver `discard` angenommen. Dadurch
bleiben Auswertung, Status, Historie und Dashboards erhalten, ohne Nachrichten
an externe Kanäle zu senden.

Die E-Mail-Empfänger für kritische Alarme sind:

- `itsupport@zircula.org`: erzeugt beziehungsweise aktualisiert ein
  LibreDesk-Ticket.
- `itadmin@zircula.org`: erreicht den technischen Personenkreis unabhängig
  davon, ob LibreDesk gerade verfügbar ist.

Für kritische E-Mails ist Alertmanager-Threading mit
`thread_by_date: none` aktiviert. Meldung, Wiederholung und Entwarnung derselben
Alertgruppe verwenden dadurch einen gemeinsamen E-Mail-Thread. LibreDesk kann
die Antworten anhand der Mail-Header derselben Konversation zuordnen.

Der Betreff enthält bewusst keinen wechselnden Status:

```text
[Zircula Monitoring] <Alertname> – <Instance>
```

Dadurch bleibt der Thread bei `firing` und `resolved` stabil. Der aktuelle
Status steht im Nachrichtentext.

## Secrets und Daten

- `/srv/zircula/alertmanager/data` – Silences und Laufzeitdaten
- `secrets/itadmin_smtp_password` – SMTP-Passwort des technischen Postfachs
- `alertmanager.yml` – versionierte Routing- und Gruppierungsregeln

Das SMTP-Secret wird nur als read-only Bind-Mount eingebunden. Eine fehlende
Datei wird durch `create_host_path: false` nicht automatisch als leere Datei
oder root-eigenes Verzeichnis erzeugt. Das Passwort erscheint weder in der
Compose-Datei noch als Umgebungsvariable oder Prozessargument.

Ein eventuell noch vorhandenes `secrets/slack_webhook_url` ist eine ungenutzte
Rollback-Datei und wird nicht in den Container eingebunden. Es kann nach Ablauf
der gewünschten Rückfallfrist sicher gelöscht beziehungsweise in Slack
widerrufen werden.

Nicht geheime SMTP-Werte sind versioniert:

- Server: `mail.manitu.de:465`
- Transport: implizites TLS
- Benutzer und Absender: `itadmin@zircula.org`

## SMTP-Secret vorbereiten

Das Postfachpasswort niemals in die Shellhistorie, Git, Tickets oder Chats
kopieren. Im Alertmanager-Verzeichnis ausführen:

```bash
cd /opt/zircula/git/infrastructure/docker/alertmanager

sudo install -d -o 65534 -g 65534 -m 750 secrets

if ! sudo test -e secrets/itadmin_smtp_password; then
  sudo install -o 65534 -g 65534 -m 400     /dev/null     secrets/itadmin_smtp_password
fi

read -rsp "SMTP-Passwort für itadmin@zircula.org: " SMTP_PASSWORD
printf '\n'

printf '%s' "$SMTP_PASSWORD"   | sudo tee secrets/itadmin_smtp_password   >/dev/null

unset SMTP_PASSWORD

sudo chown 65534:65534   secrets   secrets/itadmin_smtp_password

sudo chmod 750 secrets
sudo chmod 400 secrets/itadmin_smtp_password
```

Rechte prüfen, ohne Inhalte auszugeben:

```bash
sudo stat -c '%U:%G %a %n'   secrets   secrets/itadmin_smtp_password
```

Erwartet:

```text
nobody:nogroup 750 secrets
nobody:nogroup 400 secrets/itadmin_smtp_password
```

## Validierung und Deployment

Vor jeder Aktivierung:

```bash
cd /opt/zircula/git/infrastructure/docker/alertmanager

docker compose run --rm --no-deps   --entrypoint amtool   alertmanager   check-config   /etc/alertmanager/alertmanager.yml

docker compose config --quiet
```

Anschließend kontrolliert neu erstellen:

```bash
docker compose up -d --force-recreate
docker compose ps

docker run --rm   --network zircula_monitoring   curlimages/curl:8.16.0   --fail --silent --show-error   http://alertmanager:9093/-/ready

printf '\n'
```

## Kritischen Testalarm senden

Der Test sendet einen befristeten kritischen Alarm direkt an die interne
Alertmanager-API. Erwartet werden:

- keine Slack-Nachricht,
- E-Mail an `itadmin@zircula.org`,
- LibreDesk-Ticket über `itsupport@zircula.org`,
- nach fünf Minuten eine Entwarnung im selben E-Mail-/Ticketthread.

```bash
cd /opt/zircula/git/infrastructure/docker/alertmanager

STARTS_AT="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
ENDS_AT="$(date -u -d '+5 minutes' '+%Y-%m-%dT%H:%M:%SZ')"

docker run --rm   --network zircula_monitoring   curlimages/curl:8.16.0   --fail --silent --show-error   --header 'Content-Type: application/json'   --data "[{
    \"labels\": {
      \"alertname\": \"MonitoringTicketPipelineTest\",
      \"severity\": \"critical\",
      \"instance\": \"manual-test\",
      \"job\": \"manual-test\"
    },
    \"annotations\": {
      \"summary\": \"Manueller kritischer Monitoring-Test\",
      \"description\": \"Befristeter Test von E-Mail und LibreDesk-Threading\"
    },
    \"startsAt\": \"$STARTS_AT\",
    \"endsAt\": \"$ENDS_AT\"
  }]"   http://alertmanager:9093/api/v2/alerts

printf '\nTestalarm gültig bis %s\n' "$ENDS_AT"
```

Danach prüfen:

```bash
docker compose logs --since=10m alertmanager   | grep -Ei 'error|failed|permission denied|smtp'   || echo "Keine Zustellungsfehler"
```

Das Testticket wird mit dem Tag `Monitoring` versehen, dem IT-Team zugeordnet
und nach der Entwarnung geschlossen. Der Alarm läuft durch `endsAt`
automatisch aus; keine Prometheus-Regel und kein produktiver Dienst wird
verändert.

## Wartungsfenster

Geplante Arbeiten werden in Uptime Kuma als Maintenance Window hinterlegt.
Prometheus-Alarme können bei Bedarf zusätzlich mit einer zeitlich begrenzten
Alertmanager-Silence unterdrückt werden. Silences ersetzen keine
Wartungsdokumentation und werden nicht dauerhaft für bekannte Fehler verwendet.

## Update und Rollback

```bash
docker compose pull
docker compose up -d
docker compose ps
```

Bei SMTP-Problemen wird der vorherige Repository-Commit ausgerollt. Die
Slack-Integration bleibt deaktiviert, bis sie bewusst wieder versioniert,
validiert und ausgerollt wird.
