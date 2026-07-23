# Grafana

Grafana visualisiert die von Prometheus gespeicherten Metriken. Der Dienst ist
unter `https://monitoring.zircula.org` über Caddy erreichbar und verwendet
authentik als OpenID-Connect-Provider.

## Architektur und Zugriff

- Caddy erreicht `grafana:3000` über `zircula_frontend`.
- Grafana erreicht Prometheus über `zircula_monitoring`.
- Grafana veröffentlicht keinen Hostport.
- Die Prometheus-Datenquelle und Basisdashboards werden aus Git provisioniert.
- Normale Benutzer werden ausschließlich über authentik angelegt.
- Ein getrenntes lokales Grafana-Konto bleibt als Break-Glass-Zugang bestehen.

OAuth-Auto-Login bleibt zunächst deaktiviert. Dadurch bleiben Authentik-Login und
lokales Break-Glass-Formular gleichzeitig erreichbar. Das lokale Konto erhält
einen von Authentik abweichenden Benutzernamen und ein offline verwahrtes langes
Passwort.

## Authentik-Konfiguration

Anwendung und Provider:

- Anwendung: `Grafana`
- Slug: `grafana`
- Provider: OAuth2/OpenID Connect, `Confidential`
- Grant Type: Authorization Code
- Strict Authorization Redirect URI:
  `https://monitoring.zircula.org/login/generic_oauth`
- Logout URI: `https://monitoring.zircula.org/logout`
- Logout Method: Front-channel
- Signing Key: vorhandener Authentik Signing Key
- Scopes: `openid`, `profile`, `email`, `entitlements`

Anwendungsspezifische Entitlements:

- `Grafana Admins`
- optional später `Grafana Editors`
- optional später `Grafana Viewers`

Ohne eines dieser Entitlements verweigert Grafanas striktes Rollen-Mapping die
Anmeldung. Ein `Grafana Admins`-Entitlement erzeugt nur die Organisationsrolle
`Admin`, nicht den globalen Grafana-Serveradministrator. Der lokale Break-Glass-
Benutzer bleibt Serveradministrator.

Vor dem Go-live wird die Authentik-Anwendung ausschließlich an die vorgesehenen
Gruppen gebunden. Für Administratoren gilt die bestehende MFA-Policy.

## Vorbereitung

```bash
sudo install -d -o 472 -g 472 -m 750 /srv/zircula/grafana/data

cp .env.example .env
chmod 600 .env
```

Der Daten-Bind-Mount verwendet `create_host_path: false`. Fehlt das vorbereitete
Verzeichnis, bricht Compose ab, statt es unbemerkt als `root:root` anzulegen.
Grafana schreibt im Container als UID/GID 472 nach `/var/lib/grafana`.

Client ID, Client Secret und Break-Glass-Zugangsdaten werden nur in der lokalen
`.env` eingetragen. `GRAFANA_SECRET_KEY` wird einmalig mit mindestens 32
zufälligen Bytes erzeugt und danach nicht ohne geplante Migration geändert:

```bash
openssl rand -base64 48
```

Das initiale Admin-Passwort wird von Grafana nur bei einer frischen Datenbank
übernommen; spätere Änderungen erfolgen kontrolliert in Grafana beziehungsweise
über die dokumentierte Admin-CLI.

## Validierung und Start

Vor dem öffentlichen Routing:

```bash
docker compose config --quiet
docker compose up -d
docker compose ps
docker compose logs --tail=100 grafana
```

Interner Test im Frontend-Netz:

```bash
docker run --rm --network zircula_frontend curlimages/curl:8.16.0 \
  --fail --silent --show-error http://grafana:3000/api/health
```

Das temporäre Curl-Image wird nur für den Test verwendet und ist kein Bestandteil
des Stacks.

Danach Caddy-Konfiguration validieren und neu laden. In getrennten privaten
Browserfenstern werden geprüft:

1. lokaler Grafana-Break-Glass-Login
2. Authentik-Login mit `Grafana Admins`
3. Abweisung eines Authentik-Benutzers ohne Grafana-Entitlement
4. Rollenentzug und erneute Anmeldung
5. Logout aus Grafana und Authentik
6. Anzeige des provisionierten VPS-Dashboards

## Update und Rollback

```bash
docker compose pull
docker compose up -d
docker compose ps
docker compose logs --tail=100 grafana
```

Vor größeren Grafana-Updates werden Release Notes und ein Backup von
`/srv/zircula/grafana/data` geprüft. Ein Rollback stellt die vorherige Image-
Version wieder her und löscht keine Daten.
