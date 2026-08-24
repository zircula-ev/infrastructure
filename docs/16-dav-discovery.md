# CalDAV- und CardDAV-Erkennung

## Fehlerbild

Direkte DAV-Anfragen an `/remote.php/dav/`, den Benutzer-Principal und das
Kalender-Home funktionieren. Die automatische Erkennung über
`/.well-known/caldav` beziehungsweise `/.well-known/carddav` lieferte dagegen
einen absoluten Redirect mit `http://`. Einige Clients, darunter Apple Kalender,
brachen die Erkennung deshalb ohne Kalender-Home ab.

## Ursache und Lösung

Caddy terminiert TLS und spricht intern unverschlüsselt mit Apache. Die
Well-known-Weiterleitung wurde zuvor vom Nextcloud-Apache beantwortet und dabei
aus der internen HTTP-Verbindung als absoluter HTTP-Redirect aufgebaut.

Caddy beantwortet nun ausschließlich diese vier exakten Discovery-Pfade selbst:

- `/.well-known/caldav`
- `/.well-known/caldav/`
- `/.well-known/carddav`
- `/.well-known/carddav/`

Das Ziel ist jeweils
`https://cloud.zircula.org/remote.php/dav/` mit Status 301. Reguläre DAV-Pfade
werden weiterhin unverändert an Nextcloud weitergereicht. Authentik ist an
diesem Pfad nicht beteiligt; DAV-Clients verwenden ein persönliches
Nextcloud-App-Passwort.

Die Änderung setzt bewusst weder `overwritehost` noch `overwriteprotocol`.
Diese globalen Overrides sind nicht erforderlich, solange die übrige
Nextcloud-Proxyerkennung korrekt funktioniert.

## Validierung

Vor dem Rollout:

```bash
cd /opt/zircula/git/infrastructure/docker/caddy

docker compose config --quiet

docker compose run --rm --no-deps \
  --entrypoint caddy \
  caddy \
  validate \
  --config /etc/caddy/Caddyfile
```

Nach der Neuerstellung von Caddy:

```bash
for path in \
  /.well-known/caldav \
  /.well-known/carddav
do
  curl -fsSI "https://cloud.zircula.org${path}" \
    | sed -n -E '/^HTTP\//p;/^[Ll]ocation:/p'
done
```

Beide Antworten müssen Status 301 und folgendes Ziel liefern:

```text
https://cloud.zircula.org/remote.php/dav/
```

Danach werden die bereits bekannten PROPFIND-Prüfungen auf
`/remote.php/dav/`, den Benutzer-Principal und das Kalender-Home wiederholt.
Zum Abschluss wird das Konto in einem CalDAV-/CardDAV-Client mit einem
Nextcloud-App-Passwort getestet.
