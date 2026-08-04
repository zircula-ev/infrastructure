# Dienstadressen

## Öffentliche Administrationsoberflächen

| Dienst | Adresse | Anmeldung |
|---|---|---|
| Authentik | https://auth.zircula.org | persönliches Authentik-Konto |
| Grafana | https://monitoring.zircula.org | zentrale Anmeldung über Authentik |
| LibreDesk | https://support.zircula.org | zentrale Anmeldung über Authentik |

## Interne Administrationsoberfläche

| Dienst | Adresse | Voraussetzung |
|---|---|---|
| Uptime Kuma | https://nctest.tailf7eaa5.ts.net:8443 | verbundenes Tailscale-Gerät und eigenes Uptime-Kuma-Konto mit TOTP |

Die Uptime-Kuma-Adresse ist nicht im öffentlichen DNS veröffentlicht. Port 3001
ist ausschließlich an localhost auf nctest gebunden. Eine Adresse wie
`http://192.168.178.39:3001` ist daher bewusst kein vorgesehener Zugangsweg.

## Merksatz

Tailscale bringt das Gerät bis zur internen Oberfläche. Die Anmeldung in der
jeweiligen Anwendung bleibt trotzdem erforderlich.
