# Docker-Netzwerke

Die gemeinsamen Docker-Netzwerke werden einmalig auf dem Host erstellt und von
den getrennten Compose-Stacks als externe Netzwerke verwendet.

## `zircula_frontend`

Für Verbindungen zwischen Caddy und den öffentlich angebundenen Anwendungen:

- Caddy
- Nextcloud
- Collabora
- Authentik-Server
- Talk HPB

Ein Container im Frontend ist nicht automatisch öffentlich erreichbar. Dafür ist
zusätzlich eine Caddy-Route oder eine explizite Hostport-Freigabe erforderlich.

## `zircula_backend`

Für interne Daten- und Anwendungszugriffe:

- PostgreSQL
- Redis
- Nextcloud
- Authentik

Das Backend ist ein gemeinsames Vertrauensnetz und keine vollständige
Sicherheitsgrenze. Dienste benötigen weiterhin eigene Zugangsdaten und
Least-Privilege-Benutzer. Deshalb verwendet Redis zusätzlich ein Passwort und jede
Anwendung einen eigenen PostgreSQL-Benutzer.

Talk HPB benötigt in der aktuellen Architektur keine Verbindung zum Backend.

## Erstellung

```bash
docker network create zircula_frontend
docker network create zircula_backend
```

Vor dem Erstellen prüfen:

```bash
docker network ls
```

## Kontrolle

```bash
docker network inspect zircula_frontend
docker network inspect zircula_backend
```

Netzwerk-CIDRs werden nicht ungeprüft fest in Anwendungsdokumentationen übernommen,
da Docker sie bei einer Neuerstellung anders vergeben kann.

