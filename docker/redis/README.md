# Redis

Zentrale Redis-Instanz der Zircula-Infrastruktur.

## Aufgabe

Bereitstellung eines In-Memory-Datenspeichers für Anwendungen.

## Netzwerke

- zircula_backend

## Persistente Daten

/srv/zircula/redis

## Hinweise

- Redis veröffentlicht keine Ports nach außen.
- Anwendungen kommunizieren ausschließlich über das Docker-Netzwerk.
- Redis wird zunächst ohne Authentifizierung betrieben, da es ausschließlich im internen Docker-Netz erreichbar ist.
