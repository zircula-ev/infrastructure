# 01 – VPS-Ersteinrichtung

## Ziel

Vor der Installation von Docker und weiteren Diensten wurde der Server auf einen sicheren und wartbaren Grundzustand gebracht.

## Durchgeführte Schritte

- Ubuntu 26.04 LTS überprüft und aktualisiert
- Server neu gestartet und ein Basissnapshot erstellt
- Hostname auf `vps.zircula.org` gesetzt
- Persönlichen Administrator `timo` mit `sudo`-Rechten angelegt
- SSH-Zugang per Public Key eingerichtet und getestet
- Verzeichnisstruktur unter `/opt/zircula` vorbereitet
- Git installiert und konfiguriert
- Automatische Sicherheitsupdates (`unattended-upgrades`) geprüft
- UFW-Firewall eingerichtet und aktiviert

## Verzeichnisstruktur

```
/opt/zircula
├── backups
├── docker
├── docs
├── git
└── scripts
```

## Sicherheitskonzept

- Jeder Administrator erhält einen eigenen Linux-Benutzer.
- Administratoren authentifizieren sich ausschließlich per SSH-Schlüssel.
- Der Root-Account bleibt zunächst als Rückfallebene bestehen.
- Die Firewall blockiert standardmäßig alle eingehenden Verbindungen. Aktuell ist ausschließlich SSH freigegeben.

## Aktueller Stand

Der Server ist nun für die Installation der eigentlichen Infrastruktur vorbereitet.

Die folgenden Komponenten werden in den nächsten Schritten eingerichtet:

- Docker Engine
- Docker Compose
- GitHub-Infrastrukturrepository
- Caddy
- PostgreSQL
- Redis
- Nextcloud
- Nextcloud Talk High Performance Backend
