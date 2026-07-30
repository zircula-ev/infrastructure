# 10 – Monitoring

## Ziel und Abgrenzung

Das Monitoring trennt Außenverfügbarkeit, interne Ursachenanalyse und
Benachrichtigung:

```mermaid
flowchart LR
    Kuma[Uptime Kuma auf nctest] -->|HTTPS-Prüfung von außen| Public[Öffentliche Dienste]
    Exporter[Node und Blackbox Exporter] --> Prometheus
    Prometheus --> Grafana
    Prometheus --> Alertmanager
    Kuma --> Slack
    Kuma -->|kritische Ausfälle| ITMail[itadmin und LibreDesk]
    Alertmanager --> Slack
    Alertmanager -->|severity critical| ITMail
```

Uptime Kuma ist vorläufig auf nctest untergebracht. Da nctest ausgeschaltet
werden kann, ist dies keine hochverfügbare externe Überwachung. Nach einer
organisatorischen Entscheidung wird mindestens ein unabhängiger externer
Heartbeat oder Monitoringstandort ergänzt.

Prometheus, Alertmanager und Grafana laufen auf demselben VPS wie die
Produktivdienste. Sie liefern Ursachenanalyse und historische Werte, können aber
einen vollständigen VPS-Ausfall nicht selbst nach außen melden.

## Umsetzungsstand vom 24.07.2026

Auf dem VPS ausgerollt und geprüft sind Node Exporter, Blackbox Exporter,
Alertmanager, Prometheus und Grafana. Bestätigt wurden:

- Hostmetriken und ausschließlich lesende Mounts im Node Exporter
- erfolgreiche HTTP-, TLS- und Zertifikatsprüfung durch Blackbox Exporter
- validierte Prometheus-Konfiguration, neun Regeln und sieben erreichbare Targets
- sechs erfolgreiche öffentliche Probes einschließlich Vaultwarden und LibreDesk
- Alertmanager-Readiness und ein in Slack angekommener manueller Testalarm
- Grafana-Health, provisionierte Prometheus-Datenquelle und VPS-Dashboard
- lokaler Grafana-Break-Glass-Login
- Authentik-OIDC mit erfolgreichem Admin-Rollenmapping
- Abweisung nach Entitlement-Entzug sowie vollständiger Grafana-/Authentik-Logout
- öffentliche Erreichbarkeit ausschließlich von Grafana über Caddy
- rootless Uptime Kuma auf dem lokalen ZFS-Dataset von `nctest`
- Zugriff auf Uptime Kuma ausschließlich über Tailscale Serve auf HTTPS-Port 8443
- acht erfolgreiche externe Dienstprüfungen einschließlich LibreDesk, Grafana,
  Vaultwarden und öffentlichem VPS-HTTPS-Port
- getestete Slack-DOWN- und Entwarnungsnachrichten

Das VPS-Dashboard ist als Grafana-Startseite ausgerollt und wird nach dem
Authentik-Login direkt angezeigt. Ein temporärer Benutzer ohne
Grafana-Entitlement wurde nach erfolgreicher Authentik-Rückleitung von Grafanas
`role_attribute_strict` abgewiesen; Binding und Testkonto wurden anschließend
entfernt. Rollenentzug und anschließende erneute Anmeldung wurden ebenfalls
abgewiesen. Der Grafana-Logout leitete erfolgreich zum Authentik-End-Session-
Endpunkt weiter; eine stille Wiederanmeldung war danach nicht möglich. Uptime
Kuma auf `nctest` ist mit lokaler SQLite-Datenbank, TOTP für das
Administratorkonto und direkter Slack-Alarmierung ausgerollt.

## Getrennte Stacks

Jedes eigenständige Produkt besitzt einen eigenen Compose-Stack:

| Stack | Aufgabe | Netze | Hostports |
|---|---|---|---|
| `node-exporter` | Hostmetriken | Monitoring | keine |
| `blackbox-exporter` | interne HTTPS-Prüfungen | Monitoring | keine |
| `alertmanager` | Gruppierung und Zustellung von Alarmen | Monitoring | keine |
| `prometheus` | Sammlung, Speicherung und Regeln | Monitoring | keine |
| `grafana` | Dashboards und Auswertung | Frontend, Monitoring | keine |
| `hosts/nctest/docker/uptime-kuma` | externe Verfügbarkeitsprüfung | nctest | nur localhost |

Die Trennung erlaubt unabhängige Updates, Tests und Rollbacks. Das gemeinsame
externe Netz `zircula_monitoring` wird einmalig auf dem VPS erstellt:

```bash
docker network create zircula_monitoring
```

## Öffentlicher Zugriff

Nur Grafana wird über Caddy unter `https://monitoring.zircula.org` veröffentlicht.
Prometheus, Alertmanager und Exporter bleiben ausschließlich intern erreichbar.

Grafana verwendet authentik über Generic OAuth/OIDC. Die Anwendung nutzt
anwendungsspezifische Entitlements:

- `Grafana Admins` → Grafana-Organisationsrolle `Admin`
- `Grafana Editors` → `Editor`
- `Grafana Viewers` → `Viewer`
- kein passendes Entitlement → Anmeldung verweigert

Ein lokaler, von Authentik getrennter Grafana-Serveradministrator bleibt als
Break-Glass-Konto bestehen. OAuth-Auto-Login und das Ausblenden des Loginformulars
werden erst nach dokumentiertem Break-Glass-Test bewertet.

## Secrets und Erstinitialisierung

Secrets werden absichtlich nicht automatisch erzeugt. Automatische Erzeugung bei
jedem Deployment könnte bestehende Schlüssel ersetzen; fest eingebaute
Standardwerte wären unsicher. Stattdessen werden sie einmalig lokal angelegt und
danach außerhalb von Git verwahrt:

| Komponente | Lokale Werte | Ablage |
|---|---|---|
| Node Exporter | keine Secrets | nur Versionswert in `.env` |
| Blackbox Exporter | keine Secrets | nur Versionswert in `.env` |
| Prometheus | derzeit keine Secrets | Aufbewahrungswerte in `.env` |
| Alertmanager | Slack-Webhook, SMTP-Passwort des technischen Postfachs | `secrets/slack_webhook_url` und `secrets/itadmin_smtp_password`, UID/GID 65534 und Modus 400 |
| Grafana | Break-Glass-Zugang, Secret Key, OIDC-Client | `.env`, Modus 600 |
| Uptime Kuma | lokaler Admin, Slack-Webhook und SMTP-Zugang | Laufzeitdatenbank auf nctest |

Das Kopieren einer `.env.example` erzeugt nur die dokumentierte lokale
Konfigurationsdatei. Werte mit `CHANGE_ME` müssen vor dem Start ersetzt werden.
Compose-Dateien erzeugen fehlende Secret-Dateien und besonders sensible
Persistenzpfade nicht stillschweigend.

## Erste Ausbaustufe

Erfasst werden zunächst:

- CPU, RAM, Swap, Load und Netzwerk des VPS
- Dateisystembelegung
- Erreichbarkeit aller Monitoringkomponenten
- öffentliche HTTPS-Endpunkte einschließlich Vaultwardens `/alive`-Route,
  LibreDesks `/health`-Route und Grafanas `/api/health`
- öffentlicher TCP-Port 443 des VPS als unabhängiger Transportcheck
- Restlaufzeit der TLS-Zertifikate
- verfügbare APT-Paket- und Sicherheitsupdates
- Neustartbedarf sowie Alter der letzten erfolgreichen Updateprüfung

Prometheus bewahrt Werte standardmäßig 15 Tage und bis maximal 5 GB auf. Grafana
provisioniert Datenquelle und Basisdashboard aus Git. Das Basisdashboard ist als
Startdashboard konfiguriert, damit der Einzelserver nach dem Login direkt
angezeigt wird.

Anwendungsspezifische Metriken für Nextcloud, Authentik, Vaultwarden, LibreDesk,
PostgreSQL, Redis und Caddy folgen einzeln. Dafür werden keine Datenbankkonten,
Docker-Socket-Mounts oder privilegierten Container vorsorglich angelegt.

## Hostupdates und Neustartbedarf

Ein versioniertes Hostskript aktualisiert täglich nur die APT-Paketlisten,
simuliert ein Upgrade und schreibt vier numerische Metriken atomar in den
Textfile Collector des Node Exporters. Es installiert keine Pakete und startet
den VPS nicht neu.

Der systemd-Timer läuft zehn Minuten nach dem Start beziehungsweise täglich um
07:15 Uhr mit einer zufälligen Verzögerung von bis zu 30 Minuten. Die Service-Unit
besitzt keinen Zugriff auf Secrets. Schlägt eine Prüfung fehl, bleibt die letzte
erfolgreiche Metrik erhalten und wird nach 36 Stunden als veraltet gemeldet.

Grafana zeigt normale Updates, Sicherheitsupdates, Neustartbedarf und Alter der
Prüfung. Slack erhält Warnungen nur für Sicherheitsupdates, Neustartbedarf und
fehlende beziehungsweise veraltete Prüfungen. Installation und Neustarts bleiben
bewusste administrative Wartungsschritte.

## Alarmierung

Prometheus-Regeln werden ausschließlich nach erfolgreicher `promtool`-Prüfung
aktiviert. Alertmanager gruppiert und dedupliziert Alarme und routet sie anhand
des Labels `severity`.

Während der Slack-Übergangsphase gilt:

| Alarmklasse | Slack | Direkte IT-Mail | LibreDesk |
|---|---|---|---|
| Warnung | ja | nein | nein |
| `HostRebootRequired` | ja, höchstens täglich | nein | nein |
| Kritisch | ja | ja | ja |

Kritische Alarme gehen zusätzlich über das technische Manitu-Postfach an
`itadmin@zircula.org` und `itsupport@zircula.org`. Das SMTP-Passwort liegt
ausschließlich in der lokalen Datei
`docker/alertmanager/secrets/itadmin_smtp_password`. Alertmanager-E-Mail-
Threading hält Alarm, Wiederholungen und Entwarnung derselben Alertgruppe in
einem Mailthread, damit LibreDesk eine bestehende Konversation aktualisieren
kann. Kritische Alarme werden nach zwölf Stunden wiederholt; normale Warnungen
nach vier Stunden.

Uptime Kuma alarmiert unabhängig vom VPS. Slack bleibt zunächst an allen
Monitoren aktiv. Die zusätzliche SMTP-Benachrichtigung
`E-Mail – kritischer externer Ausfall` ist nur dem VPS-Portmonitor sowie
Nextcloud, Authentik und LibreDesk zugeordnet. Sie sendet direkt an
`itadmin@zircula.org` und als Kopie an `itsupport@zircula.org`. So bleibt die
Meldung auch bei einem vollständigen VPS-Ausfall im externen Manitu-Postfach
erhalten.

Geplante Arbeiten werden vorab als Uptime-Kuma-Maintenance und bei Bedarf als
zeitlich begrenzte Alertmanager-Silence eingetragen. Alarmtests stoppen keine
Produktivdienste. Verwendet werden befristete Testalarme oder absichtlich nicht
existierende Testziele.

Slack wird erst entfernt, wenn sowohl Uptime-Kuma-E-Mail als auch der
Alertmanager-/LibreDesk-Thread einschließlich Entwarnung unter realen
Bedingungen getestet wurden. Ein späterer zusätzlicher Wechsel zu Nextcloud Talk
erfolgt über einen Webhook beziehungsweise Bot, ohne die Messwerterfassung neu
aufzubauen.

## Datenschutz und Sicherheit

- keine öffentlichen Metrik- oder Administrationsports außer Grafana über Caddy
- kein Docker-Socket in einem Monitoringcontainer
- nur lesende Host-Mounts für Node Exporter
- keine Dateinamen, Benutzernamen, URLs mit Tokens oder andere hochkardinale
  Nutzdaten als Prometheus-Labels
- Secrets ausschließlich lokal und mit dienstbezogen minimalen Leserechten
- keine vollständigen Requestpfade oder Inhalte in Dashboards
- Zugriff auf Grafana nur für ausdrücklich berechtigte Authentik-Entitlements
- MFA für Grafana-Administratoren

Prometheus-Metriken und Grafana-Daten können interne Topologie und Betriebszustand
offenlegen und werden daher wie administrative Daten behandelt.

## Deploymentreihenfolge

1. DNS für `monitoring.zircula.org` setzen.
2. `zircula_monitoring` erstellen.
3. Node Exporter starten und prüfen.
4. Host-Updateprüfskript und systemd-Timer installieren und einmalig ausführen.
5. Blackbox Exporter starten und prüfen.
6. Alertmanager inklusive lokalem Slack-Secret starten.
7. Prometheus-Konfiguration und Regeln mit `promtool` prüfen und starten.
8. Authentik-Anwendung, Provider und Entitlements vorbereiten.
9. Grafana zunächst intern starten und Break-Glass-Konto testen.
10. Caddy-Konfiguration validieren und Grafana veröffentlichen.
11. OIDC-Rollen, Ablehnung ohne Entitlement, Logout und Dashboards testen.
12. Uptime Kuma auf nctest installieren und Negativtest durchführen.

Jeder Schritt wird einzeln geprüft. Ein fehlerhafter Stack wird zurückgerollt,
ohne die übrigen Monitoringkomponenten neu zu erstellen.

## Grenzen und nächste Stufen

- unabhängiges externes Monitoringziel beziehungsweise Heartbeat
- Backupalter über Node-Exporter-Textfile-Collector
- Nextcloud- und Authentik-Metriken
- PostgreSQL- und Redis-Exporter mit minimal berechtigten Konten
- Caddy-Requestmetriken ohne sensible Pfadlabels
- dokumentierte Alarmverantwortung und Eskalationszeiten
- regelmäßige Prüfung, ob nctest und Uptime Kuma selbst erreichbar sind


## Vaultwarden

Die versionierte Prometheus-Konfiguration prüft
`https://vault.zircula.org/alive` über den Blackbox Exporter. Nach dem Merge wird
die geladene Konfiguration einschließlich `probe_success 1` kontrolliert. In der
zweiten Vaultwarden-Rolloutphase wird derselbe Endpunkt auf `nctest` als fünfter
HTTPS-Monitor mit Slack-Benachrichtigung ergänzt. Die öffentliche Probe bestätigt Erreichbarkeit und TLS, aber weder Login noch
Entschlüsselbarkeit oder die Aktualität des Backups. Dafür bleiben regelmäßige
funktionale Tests und ein separater Backupalter-Alarm erforderlich.


## LibreDesk

Als sechstes öffentliches Blackbox-Ziel ist
`https://support.zircula.org/health` aktiv. Nach internem Healthcheck, DNS- und
TLS-Freigabe wurde Prometheus neu gestartet; Target und öffentliche Probe sind
erreichbar.

Die öffentliche Probe bestätigt Prozess, Reverse Proxy und TLS. Sie prüft weder
IMAP-Abruf noch SMTP-Versand, OIDC, Ticket-Threading oder Backupaktualität. Diese
Funktionen bleiben Teil der regelmäßigen Betriebsprüfungen in
`docs/13-libredesk.md`. Derselbe Health-Endpunkt ist zusätzlich in Uptime Kuma
auf `nctest` aktiv und wurde erfolgreich getestet.
