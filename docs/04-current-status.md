# 04 – Aktueller Stand

Stand: 15.07.2026

## Ziel

Eine gemeinsame selbst gehostete Kollaborationsplattform für Zircula e.V. und die
angebundenen Organisationen. Die organisatorische Trennung erfolgt innerhalb
einer einzelnen Nextcloud über Gruppen und anwendungsbezogene Berechtigungen.

## Infrastruktur

- Ubuntu 26.04 LTS
- Docker Engine und Docker Compose
- Caddy als zentraler Reverse Proxy
- gemeinsame externe Netze `zircula_frontend` und `zircula_backend`
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
- zentrale Benutzer- und Gruppenstruktur für beide Vereine

### Talk High Performance Backend

- produktiv unter `talk.cloud.zircula.org`
- Signaling, SFU sowie integriertes TURN/STUN
- 3478/TCP und 3478/UDP öffentlich erreichbar
- erfolgreicher Testanruf zwischen Vereins-WLAN und Mobilfunk
- alter Stack `docker/nextcloud-talk` entfernt; maßgeblich ist `docker/talk-hpb`

### Authentik

- produktiv unter `auth.zircula.org`
- eigener Datenbankbenutzer und eigene PostgreSQL-Datenbank
- Break-Glass-Konto vorhanden
- schrittweise SSO-Integration geplant
- Docker-Socket des Workers vor produktiver Outpost-Nutzung erneut bewerten

### Collabora

- produktiv unter `office.zircula.org`
- WOPI mit der zentralen Nextcloud
- keine direkte Hostport-Freigabe

## Migration und Organisation

- gemeinsame Ordner- und Berechtigungsstruktur definiert
- Team Folders eingerichtet
- rclone für die Migration der bisherigen Clouds vorbereitet
- Datenmigration und organisatorisches Onboarding werden getrennt vom
  Infrastrukturaufbau dokumentiert

## Sicherheitsstand

Positiv geprüft:

- nur erwartete öffentliche Ports
- keine produktiven Datenbank- oder Cacheports am Host
- automatische Sicherheitsupdates aktiv
- SSH-Passwortanmeldung deaktiviert
- AppArmor und Seccomp aktiv
- keine fehlgeschlagenen systemd-Dienste
- alle produktiven `.env` mit Modus 600
- Root-SSH deaktiviert und `MaxAuthTries` auf 3 reduziert
- Redis-Passwort gemeinsam mit Nextcloud produktiv eingeführt
- Redis läuft als UID/GID 999 und lehnt anonyme Zugriffe ab
- `vm.overcommit_memory=1` dauerhaft gesetzt
- Dependabot für die aktiven Compose-Stacks eingerichtet

Offen:

- Authentik-Docker-Socket anhand der Outpost-Nutzung minimieren
- externes Backupziel und Restore-Test etablieren
- ergänzendes Image- und Secret-Scanning etablieren
- ausstehende Ubuntu-Paketupdates im Wartungsfenster installieren

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
VPS aus. Der Caddy-Wechsel von 2.10 auf 2.11 wird separat getestet. Der automatisch
vorgeschlagene PostgreSQL-Wechsel von 17 auf 18 wurde abgelehnt, weil dafür eine
geplante Major-Migration erforderlich ist.

## Produktionsreife

Die Kerndienste sind funktionsfähig. Vollständig belastbare Produktionsreife wird
erst angenommen, wenn ein externes Backup und ein erfolgreicher Restore-Test
dokumentiert sind. Ein VPS-Snapshot allein erfüllt diese Anforderung nicht.

## Nächste Schritte

1. Backupziel, Aufbewahrung und Restore-Test umsetzen.
2. ausstehende Ubuntu-Paketupdates kontrolliert installieren.
3. Caddy 2.11 separat validieren und ausrollen.
4. regelmäßige Image- und Secret-Scans ergänzen.
5. Authentik-Docker-Socket anhand der Outpost-Nutzung minimieren.
6. SSO-Integration, Migration und Benutzer-Onboarding fortführen.
