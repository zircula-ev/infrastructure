# 04 – Current Status

## Ziel

Aufbau einer produktiven, selbst gehosteten digitalen Infrastruktur für Zircula e.V., WERK e.V. und die Objekt 218 GmbH.

Die Plattform soll langfristig Dokumentenmanagement, Zusammenarbeit, Wissensmanagement und weitere Dienste zentral unter einer gemeinsamen Infrastruktur vereinen.

---

# Infrastruktur

## Basis

- Ubuntu Server
- SSH-Schlüssel und Benutzerverwaltung
- Docker CE
- Docker Compose
- GitHub Repository
- Gemeinsame Docker-Netzwerke
  - `zircula_frontend`
  - `zircula_backend`

---

# Dienste

## Caddy

- Reverse Proxy
- HTTPS über Let's Encrypt
- Automatische Zertifikatsverwaltung
- Produktive Domainstruktur

## PostgreSQL

- Eigener Docker-Stack
- Persistente Daten unter `/srv/zircula/postgres`

## Redis

- Eigener Docker-Stack
- Persistente Daten unter `/srv/zircula/redis`

---

# Anwendungen

## Nextcloud Hub

- Eigener Docker-Stack
- PostgreSQL
- Redis
- Reverse Proxy über Caddy
- Produktive Domain vorbereitet (`cloud.zircula.org`)

### Konfiguriert

- Cron
- SMTP
- OPcache
- Team Folders
- Collectives
- Deck
- Office
- Collabora Online
- Standard-Apps bereinigt

## Collabora Online

- Eigener Docker-Stack
- Reverse Proxy über Caddy
- Eigene Domain (`office.zircula.org`)
- WOPI vollständig eingerichtet

---

# Architektur

## Infrastruktur

Jeder Dienst besitzt einen eigenen Docker-Stack.

Produktive Daten liegen unter

```
/srv/zircula
```

Die komplette Infrastruktur wird versioniert unter

```
/opt/zircula/git/infrastructure
```

---

## Domainstrategie

Produktive Dienste werden unabhängig von ihrer technischen Implementierung benannt.

Beispiele:

- `cloud.zircula.org`
- `office.zircula.org`
- `vps.zircula.org`

Dadurch bleibt die URL unabhängig von der eingesetzten Software.

---

## Berechtigungsmodell

Die gemeinsame Datenstruktur basiert auf Team Folders.

- klare organisatorische Trennung
- gemeinsamer Besitz der Daten
- ACLs nur dort, wo notwendig
- keine privaten Administrator-Ordner als Datenbasis

---

# Migration

## Vorbereitungen abgeschlossen

- neue Ordnerstruktur erstellt
- Berechtigungskonzept definiert
- Team Folders eingerichtet
- rclone eingerichtet
- Migration der Alt-Clouds vorbereitet

Die eigentliche Datenmigration wurde aus organisatorischen Gründen verschoben, bis beide bisherigen Clouds eingefroren sind.

---

# Dokumentation

Die Infrastruktur wird fortlaufend dokumentiert.

Bereits dokumentiert sind unter anderem:

- Docker
- Caddy
- Nextcloud
- Collabora
- rclone

---

# Offene Arbeiten

## Migration

- WERK-Cloud migrieren
- Zircula-Cloud migrieren
- Kalender übernehmen
- Daten in neue Struktur überführen

## Nextcloud

- Collectives aufbauen
- Benutzer-Onboarding
- Arbeitsabläufe dokumentieren
- App-Auswahl weiter optimieren

## Infrastruktur

- Backupkonzept nach `nctest`
- Restore-Dokumentation
- Monitoring
- Hardening (z. B. Fail2ban)

## Langfristig

- Identity Management (Authentik evaluieren)
- Single Sign-On
- Weitere Dienste in die Infrastruktur integrieren

---

# Projektstatus

Die technische Infrastruktur kann bereits produktiv betrieben werden.

Der aktuelle Schwerpunkt liegt nicht mehr auf der Serverinstallation, sondern auf

- Migration der bestehenden Daten
- organisatorischer Einführung
- Dokumentation
- Optimierung der Arbeitsabläufe

Der Übergang in den Produktivbetrieb erfolgt nach Abschluss der Datenmigration.
