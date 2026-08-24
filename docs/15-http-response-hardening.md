# HTTP-Antwortheader und Versionsoffenlegung

## Ziel

Öffentliche Antworten sollen keine unnötigen Produkt- oder Versionshinweise aus
den Anwendungscontainern weitergeben. Dies ist eine ergänzende Härtung und kein
Ersatz für zeitnahe Sicherheitsupdates.

## Umsetzung

Caddy entfernt bei allen öffentlichen virtuellen Hosts die Antwortheader
`Server` und `X-Powered-By`. Die bestehende HSTS-Richtlinie wird gemeinsam mit
diesen Regeln über das Snippet `security_headers` eingebunden. Die expliziten
CalDAV- und CardDAV-Weiterleitungen bleiben davon unberührt.

Der Nextcloud-Container lädt zusätzlich zwei schreibgeschützte Konfigurationen:

- `apache/security.conf` setzt `ServerTokens Prod` und
  `ServerSignature Off`.
- `php/conf.d/security.ini` setzt `expose_php=Off`.

Die Einstellungen reduzieren die interne Offenlegung ebenfalls. Caddy bleibt
die maßgebliche äußere Schutzschicht und entfernt die Header unabhängig vom
jeweiligen Upstream.

## Rollout

Vor dem Rollout werden beide Compose-Konfigurationen und die Caddy-Konfiguration
geprüft:

```bash
cd /opt/zircula/git/infrastructure/docker/nextcloud
docker compose config --quiet

cd ../caddy
docker compose config --quiet
docker compose run --rm --no-deps \
  --entrypoint caddy \
  caddy \
  validate \
  --config /etc/caddy/Caddyfile
```

Anschließend werden zuerst Nextcloud und danach Caddy neu erstellt:

```bash
cd /opt/zircula/git/infrastructure/docker/nextcloud
docker compose up -d --force-recreate nextcloud

cd ../caddy
docker compose up -d --force-recreate caddy
```

## Prüfung

```bash
cd /opt/zircula/git/infrastructure/docker/nextcloud

docker compose exec -T nextcloud apache2ctl -t
docker compose exec -T nextcloud php -i | grep '^expose_php'

for endpoint in \
  https://cloud.zircula.org/status.php \
  https://auth.zircula.org/-/health/ready/ \
  https://monitoring.zircula.org/api/health \
  https://vault.zircula.org/alive \
  https://support.zircula.org/health
do
  printf '\n=== %s ===\n' "$endpoint"

  if curl -fsSI "$endpoint" | grep -Eiq '^(server|x-powered-by):'; then
    echo "FEHLER: unerwünschter Antwortheader vorhanden"
    exit 1
  fi

  echo "Keine unerwünschten Produktheader"
done
```

Zusätzlich werden die regulären Dienst-Healthchecks, der Nextcloud-Status und
die HTTPS-Ziele der CalDAV-/CardDAV-Discovery geprüft. Ein fehlender
Versionsheader allein ist kein ausreichender Funktionsnachweis.

## Rollback

Der Rollback erfolgt durch Rücknahme des zugehörigen Git-Commits, erneute
Validierung und Neuerstellung von Nextcloud und Caddy. Persistente Nutz- und
Datenbankdaten werden durch diese Konfiguration nicht verändert.
