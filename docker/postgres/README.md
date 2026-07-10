# PostgreSQL

Zentrale PostgreSQL-Instanz der Zircula-Infrastruktur.

## Aufgabe

Bereitstellung von Datenbanken für Anwendungen.

## Netzwerke

- zircula_backend

## Persistente Daten

/srv/zircula/postgres

## Hinweise

- PostgreSQL veröffentlicht keine Ports nach außen.
- Anwendungen kommunizieren ausschließlich über das Docker-Netzwerk.
- Jede Anwendung erhält einen eigenen Datenbankbenutzer.
