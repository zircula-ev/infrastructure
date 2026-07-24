# 04 – Aktueller Stand

Stand: 24.07.2026

## Ziel

Eine gemeinsame selbst gehostete Kollaborationsplattform für Zircula e.V. und die
angebundenen Organisationen. Die organisatorische Trennung erfolgt innerhalb
einer einzelnen Nextcloud über Gruppen und anwendungsbezogene Berechtigungen.

## Infrastruktur

- Ubuntu 26.04 LTS
- Docker Engine und Docker Compose
- Caddy 2.11 als zentraler Reverse Proxy
- gemeinsame externe Netze `zircula_frontend`, `zircula_backend` und
  `zircula_monitoring`
- PostgreSQL und Redis als getrennte Stacks
- Redis mit Passwortauthentifizierung über Compose-Secret
- automatische Ubuntu-Sicherheitsupdates
- UFW für IPv4 und IPv6
- AppArmor und Docker-Standard-Seccomp aktiv

## Anwendungen

### Nextcloud

- produktiv unter `cloud.zircula.org`
- PostgreSQL und Redis
- Team Folders, Collectives, Deck und weitere Vereinsanwendungen
- Collabora Online unter `office.zircula.org`
- zentrale Benutzer- und Gruppenstruktur über Authentik und OIDC

### Talk High Performance Backend

- produktiv unter `talk.cloud.zircula.org`
- Signaling, SFU sowie integriertes TURN/STUN
- 3478/TCP und 3478/UDP öffentlich erreichbar
- erfolgreicher Testanruf zwischen Vereins-WLAN und Mobilfunk
- alter Stack `docker/nextcloud-talk` entfernt; maßgeblich ist `docker/talk-hpb`

### Authentik

- produktiv unter `auth.zircula.org`
- eigener Datenbankbenutzer und eigene PostgreSQL-Datenbank
- getrenntes Authentik-Break-Glass-Konto ohne Nextcloud-Entitlements
- Nextcloud über OIDC mit automatischer Benutzer- und Gruppenprovisionierung
- anwendungsspezifische Entitlements für Organisations- und Administratorgruppen
- WebAuthn und MFA-Pflicht für `Nextcloud Admins` erfolgreich getestet
- Worker läuft ohne Root-Rechte, ohne Docker-Socket und nur im Backend-Netz
- der vorhandene Embedded Outpost benötigt keinen Docker-Socket
- versioniertes WERK × ZIRCULA Branding mit hellem Farbschema und deutscher
  Oberfläche erfolgreich ausgerollt und getestet

### Collabora

- produktiv unter `office.zircula.org`
- WOPI mit der zentralen Nextcloud
- keine direkte Hostport-Freigabe

### Monitoring

Auf dem VPS aktiv und geprüft:

- Node Exporter für Hostmetriken
- Blackbox Exporter für HTTPS- und TLS-Prüfungen
- Prometheus mit validierten Regeln und ausschließlich internen Targets
- Alertmanager mit erfolgreichem Slack-Testalarm
- Grafana unter `monitoring.zircula.org`
- lokaler Grafana-Break-Glass-Login und Authentik-OIDC mit Admin-Mapping
- versioniertes VPS-Basisdashboard wird nach dem Login direkt als
  Startdashboard angezeigt
- keine öffentlichen Metrik- oder Administrationsports außer Grafana über Caddy

Auf `nctest` überwacht Uptime Kuma die vier öffentlichen Endpunkte für
Nextcloud, Authentik, Collabora und Talk HPB unabhängig vom VPS. Die Oberfläche
ist nur im Tailnet über Tailscale Serve auf HTTPS-Port 8443 erreichbar. DOWN- und
Entwarnungsnachrichten an Slack wurden mit einem ungefährlichen Testmonitor
bestätigt. Da `nctest` versehentlich ausgeschaltet werden kann, bleibt diese
Instanz eine Übergangslösung und keine hochverfügbare externe Überwachung.

## Migration und Organisation

- gemeinsame Ordner- und Berechtigungsstruktur definiert
- Team Folders eingerichtet
- rclone für die Migration der bisherigen Clouds vorbereitet
- erste Werk-Haus-Datenübernahme läuft beziehungsweise wird geprüft
- Datenmigration und organisatorisches Onboarding werden getrennt vom
  Infrastrukturaufbau dokumentiert

## Sicherheitsstand

Positiv geprüft:

- nur erwartete öffentliche Ports
- keine produktiven Datenbank-, Cache- oder Monitoringports am Host
- automatische Sicherheitsupdates aktiv
- SSH-Passwortanmeldung deaktiviert
- AppArmor und Seccomp aktiv
- keine fehlgeschlagenen systemd-Dienste
- alle produktiven `.env` mit Modus 600
- Root-SSH deaktiviert und `MaxAuthTries` auf 3 reduziert
- Redis-Passwort gemeinsam mit Nextcloud produktiv eingeführt
- Redis läuft als UID/GID 999 und lehnt anonyme Zugriffe ab
- `vm.overcommit_memory=1` dauerhaft gesetzt
- Dependabot für die aktiven und neu angelegten Compose-Stacks konfiguriert
- OIDC-Provisionierung, Gruppenentzug, Adminentzug und Back-Channel-Logout geprüft
- Authentik-Benutzer ohne Nextcloud-Entitlements erfolgreich abgewiesen
- Authentik-Worker ohne Root-Rechte und Docker-Socket erfolgreich geprüft
- Monitoringcontainer ohne unnötige Hostports und Socket-Mounts geprüft

Offen:

- externes Backupziel und Restore-Test etablieren
- ergänzendes Image- und Secret-Scanning etablieren
- ausstehende Ubuntu-Paketupdates im Wartungsfenster installieren
- MFA und Recovery für beide Break-Glass-Konten abschließen
- MFA-Governance für weitere Organisationsgruppen festlegen
- OIDC-Offboarding sowie Desktop-/Mobile-Client und WebDAV testen

## Validierung vom 15.07.2026

Nach dem Redis- und Nextcloud-Rollout wurden erfolgreich geprüft:

- Redis-Healthcheck und Schreiben als Benutzer `redis` mit UID/GID 999
- Ablehnung nicht authentifizierter Redis-Verbindungen mit `NOAUTH`
- authentifizierter Zugriff über das Secret
- AOF-Persistenz über einen Containerneustart
- Nextcloud-Status ohne Redis-Authentifizierungsfehler
- Dateibrowser und Dateioperationen
- Talk-Anruf
- neues Dokument und Bearbeitung über Collabora
- neue SSH-Public-Key-Sitzung als `timo` einschließlich `sudo`

Dependabot erstellt wöchentlich Pull Requests, führt jedoch keine Updates auf dem
VPS aus. PostgreSQL-Major-Versionen bleiben von automatischen Vorschlägen
ausgenommen, weil dafür eine geplante Migration erforderlich ist.

## Validierung vom 22.07.2026

Für die Authentik- und Nextcloud-Integration wurden erfolgreich geprüft:

- lokaler Nextcloud-Break-Glass-Login über `/login?direct=1`
- OIDC-Login und automatische Neuanlage von `timohecken`
- Übernahme von Benutzer-ID, Anzeigename, E-Mail-Adresse und Gruppen
- Entzug und erneute Vergabe einer Organisationsgruppe
- Entzug und erneute Vergabe der Nextcloud-Administratorrechte
- Abweisung eines Authentik-Kontos ohne Nextcloud-Entitlements
- Back-Channel-Logout von Authentik nach Nextcloud
- WebAuthn für das persönliche Administratorkonto

Details und Betriebsverfahren stehen in
`docs/08-authentik-nextcloud-oidc.md`.

## Validierung vom 23.07.2026

Erfolgreich geprüft und auf dem VPS ausgerollt:

- Caddy 2.11 einschließlich öffentlicher Anwendungen und TLS
- Authentik-Worker als UID/GID 1000 ohne Docker-Socket und ohne Frontend-Netz
- Authentik-Worker-Healthcheck sowie öffentliche Live- und Ready-Endpunkte
- Node-Exporter-Metriken und ausschließlich lesende Host-Mounts
- Blackbox-Probe gegen Nextcloud mit HTTP 200, TLS und `probe_success 1`
- Alertmanager-Readiness und Zustellung eines manuellen Testalarms an Slack
- Prometheus-Konfiguration, sechs Regeln, sieben erreichbare Targets und vier
  erfolgreiche öffentliche Probes
- Grafana-Datenbank, öffentliche Health-Route, lokaler Break-Glass-Login,
  Authentik-OIDC, Admin-Rollenmapping und provisioniertes Dashboard
- Ablehnung eines Testbenutzers ohne Grafana-Entitlement durch
  `role_attribute_strict`; temporäre Binding und Testkonto anschließend entfernt
- Authentik-Branding mit persönlichem WebAuthn/MFA-Login, Nextcloud- und
  Grafana-OIDC, schmalem Viewport sowie getrennten lokalen Break-Glass-Zugängen

## Validierung vom 24.07.2026

Erfolgreich auf `nctest` ausgerollt und geprüft:

- Uptime Kuma 2.4.0 als Rootless-Image mit UID/GID 1000
- lokales ZFS-Dataset mit SQLite-Persistenz
- keine zusätzlichen Linux-Capabilities und kein Docker-Socket
- Bindung ausschließlich an `127.0.0.1:3001`
- Zugriff nur über die zusätzliche Tailscale-Serve-Route auf HTTPS-Port 8443
- lokale Anmeldung mit TOTP für das Administratorkonto
- vier erfolgreiche öffentliche Dienstprüfungen
- Slack-Nachrichten für DOWN und anschließende Entwarnung
- Grafana-Rollenentzug mit erfolgreicher Abweisung bei erneuter Anmeldung
- vollständiger Grafana-/Authentik-Logout ohne stille Wiederanmeldung

## Produktionsreife

Die Kerndienste und das interne Monitoring sind funktionsfähig. Vollständig
belastbare Produktionsreife wird erst angenommen, wenn ein externes Backup und
ein erfolgreicher Restore-Test dokumentiert sind. Ein VPS-Snapshot allein erfüllt
diese Anforderung nicht. Uptime Kuma kann einen vollständigen VPS-Ausfall zwar
unabhängig melden, sein Standort `nctest` ist jedoch nicht hochverfügbar.

## Nächste Schritte

1. Backupziel, Aufbewahrung und Restore-Test umsetzen.
2. ausstehende Ubuntu-Paketupdates kontrolliert installieren.
3. regelmäßige Image- und Secret-Scans ergänzen.
4. Benutzer-Onboarding und MFA-Governance abschließen.
5. Migration der bisherigen Clouds durchführen.
