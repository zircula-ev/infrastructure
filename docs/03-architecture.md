## Netzwerkübersicht

```mermaid
graph TD

Internet --> Caddy

Caddy --> Website
Caddy --> Nextcloud
Caddy --> Talk

Nextcloud --> PostgreSQL
Nextcloud --> Redis

Talk --> Redis

```
