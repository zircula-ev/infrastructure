# Werkblatt-Pilot

Dieser Stack integriert die eigenständige Open-Source-Anwendung Werkblatt in die
Zircula-Infrastruktur. Die Software selbst bleibt im Repository
`IndieStu/Werkblatt`; dieses Verzeichnis enthält ausschließlich die
Zircula-spezifische Betriebsintegration.

## Festgelegter Softwarestand

Der Build-Kontext ist unveränderlich auf Werkblatt-Commit
`82d9a7a80f2c5ca60e395adcdef21d9e62fd13d6` festgelegt. Das resultierende lokale
Image erhält denselben Commit als Tag. Build und Image-ID sind unten
dokumentiert; der vollständige synthetische E2E bleibt Teil des Phase-4a-Gates.
PostgreSQL ist auf den
bereits geprüften Image-Digest
`sha256:0af65001d05296a2ead57ac4a6412433d8913d1bb5d0c88435a7d1e1ee5cb04b`
festgelegt.

Der vorherige Pilotstand war Commit
`8ac48f88fa5ee508ac3e617a195c82ee254358a4` mit Image-ID
`sha256:9d63cbc58ca8cc842f2c7386f59e0f36ecb545caad7ce3fd94294a3e7f69bc21`.
Der neue Stand ergänzt das freigegebene responsive Werkblatt-Hintergrundasset
auf der öffentlichen Loginseite einschließlich Dark-Mode-Ableitung. Er enthält
keine neue Migration; Datenbank und Caddy bleiben beim Containerwechsel
unverändert. Der Webcontainer wurde am 31. August 2026 nach erfolgreichem
Preflight und Migrationsabgleich aktualisiert. Interner Healthcheck,
`/health/`, `/ready/` und der Abruf des neuen statischen Assets waren
erfolgreich.

Der isolierte VPS-Build des neuen Pins ergab Image-ID
`sha256:964c51c87236dae8b0a83463e388e17058af8a2fc1696d62a04213433976dca7`.
Die synthetischen Renderer-Prüfungen waren zweimal byte-identisch:

- Teilnahmeliste: `e1d49e7a2374a388ddeb5e12504cc24164471d190feb3144f157af5309244b8f`
- Abschlussbericht: `894ce7bafe95cf4f8c4abb963e815e75d02c50f0774e6794ccf6816785b6d4e5`

Der isolierte Stacktest bestätigte PostgreSQL-Initialisierung unter UID 999 und
read-only RootFS, alle Migrationen, Organisations-Bootstrap, HTTP-Readiness 200,
einen logischen Custom-Dump sowie dessen Restore in eine leere Testdatenbank.
Beide Container hatten keine veröffentlichten Ports.

## Architektur und Ressourcen

- `werkblatt`: Django/Gunicorn, 2 CPU, 1536 MiB RAM, 256 MiB tmpfs;
- `werkblatt-db`: eigener PostgreSQL-17-Container, 1 CPU, 1024 MiB RAM und
  256 MiB Shared Memory;
- nur der Webcontainer hängt an `zircula_frontend` und ist für Caddy erreichbar;
- App und Datenbank teilen ausschließlich `werkblatt_internal`;
- keine veröffentlichten Hostports;
- Medien unter `/srv/zircula/werkblatt/media`, PostgreSQL unter
  `/srv/zircula/werkblatt/postgres`;
- Root-Dateisysteme read-only, keine Capabilities, `no-new-privileges` und
  rotierende JSON-Logs.

Der VPS hatte beim Preflight 8 vCPU, 15 GiB RAM, rund 9 GiB verfügbaren RAM und
205 GiB freien Plattenplatz. Es existiert kein Swap. WeasyPrint-Spitzen und der
parallele Backup-Lauf werden deshalb beim Pilot beobachtet.

## Einmalige Vorbereitung

Phase 4b darf erst nach ausdrücklicher Freigabe beginnen. Dann werden die Pfade
mit den Container-UIDs vorbereitet:

```bash
sudo install -d -o 10001 -g 10001 -m 700 /srv/zircula/werkblatt/media
sudo install -d -o 999 -g 999 -m 700 /srv/zircula/werkblatt/postgres
install -d -m 700 secrets
cp .env.example .env
chmod 600 .env
```

Die sechs gemounteten Secret-Dateien werden interaktiv erstellt, jeweils mit
Modus 600. Das Datenbankpasswort liegt als identische, aber getrennt
berechtigte Kopie für beide Container vor:

- `secrets/django_secret_key`
- `secrets/postgres_password_web` (UID 10001)
- `secrets/postgres_password_db` (UID 999)
- `secrets/oidc_client_secret`
- `secrets/pretix_api_token`
- `secrets/webdav_password`

Alle übrigen Secret-Dateien gehören UID 10001. Die Trennung ist notwendig, da
Compose dateibasierte Secrets als Bind-Mount mit den Host-Dateirechten
bereitstellt. Die beiden Passwortdateien sind keine unabhängigen Werte und
müssen bei einer Rotation atomar aus derselben neuen Quelle ersetzt werden.

Kein Wert wird in Git, Chat, Shell-History oder Logs ausgegeben. `.env` enthält
nur nicht geheime Werte, bleibt aufgrund der Betriebsinformationen dennoch
root-only beziehungsweise nur für den Deploymentbenutzer lesbar.

## Authentik

Benötigt werden eine Application `Werkblatt`, ein eigener confidential
OAuth2/OIDC-Provider mit Authorization Code und PKCE S256 sowie:

- Redirect: `https://werkblatt.zircula.org/auth/oidc/callback/`
- Issuer: `https://auth.zircula.org/application/o/werkblatt/`
- Scopes: `openid email profile groups`
- `Werkblatt Users` → Workshop User
- `Werkblatt Editors` → Editor
- `Werkblatt Admins` → Organization Admin

Editoren dürfen Dokumentvorlagen und dokumentbezogene Assets verwalten sowie
Organisationslogos in Vorlagen verwenden. Organisationsprofil und
Organisationsbranding bleiben ausschließlich administrierbar. Bei mehreren
Gruppen gilt die Rollenpriorität Admin vor Editor vor Workshop User.

Nur Werkblatt-spezifische Gruppen dürfen Zugriff gewähren. Provider und Gruppen
werden nach verifiziertem Authentik-Backup additiv angelegt. Das Client-Secret
wird direkt in die lokale Secret-Datei übernommen.

## Pretix und Nextcloud

Pretix erhält einen dedizierten read-only Token für Organizer `werk`. Der
kanonische API-Ursprung ist `https://pretix.eu`; die umleitende www-Variante
wird nicht verwendet. Ein
Testmode-Event wird ausschließlich mit expliziter Referenz importiert:

```bash
docker compose run --rm web python manage.py sync_pretix \
  --include-test-events --workshop-reference SYNTHETIC-TEST-EVENT
```

Nextcloud erhält einen technischen Werkblatt-Benutzer, ein App-Passwort und
einen dedizierten Zielordner. Der End-to-End-Test verwendet ausschließlich
synthetische Personen und Dokumente.

## Preflight, Migration und Start

```bash
# Bereits in Phase 4a erfolgt und nur bei bewusstem neuen Gate zu wiederholen:
docker compose build --pull web
docker image inspect werkblatt:82d9a7a80f2c5ca60e395adcdef21d9e62fd13d6 \
  --format '{{.Id}}'

# Phase 4b muss exakt die dokumentierte Image-ID vorfinden:
bash scripts/preflight.sh
docker compose up -d db
docker compose run --rm web python manage.py migrate --noinput
docker compose run --rm web python manage.py bootstrap_organization \
  --name "Zircula e.V."
docker compose up -d web
docker compose ps
```

Migrationen laufen bewusst separat mit exakt dem neuen Image. Erst nach internem
Readiness-Test werden Caddy und der öffentliche synthetische Test aktiviert.

## Healthchecks und Logging

- `/health/`: Liveness ohne Datenbank;
- `/ready/`: Readiness mit Datenbankabfrage;
- Docker prüft `/ready/` intern mit dem vertrauenswürdigen HTTPS-Proxy-Header;
- Prometheus/Blackbox prüft öffentlich `/health/`;
- Gunicorn-Accesslogs sind deaktiviert; Fehlerlogs dürfen weder PII noch
  Dokumentinhalte, Secrets oder vollständige WebDAV-Pfade enthalten.

## Backup, Restore und Rollback

Der VPS-Backup-Lauf erzeugt vor dem Restic-Snapshot einen Custom-Dump
`werkblatt.pgdump`. Rohe PostgreSQL-Dateien sind ausgeschlossen. Medien,
Konfiguration und Secrets werden verschlüsselt über den bestehenden
`/srv/zircula`-/Infrastruktur-Schutzumfang gesichert.

Vor jedem Update werden zusätzlicher Werkblatt-Dump, Medien-Checkpoint,
vorheriger Image-Tag und Image-ID festgehalten. Ein isolierter Restore verwendet
eine temporäre Datenbank und einen temporären Medienpfad. Geprüft werden
Migrationen, Snapshot-Hashes und der Abruf einer synthetischen PDF-Datei.

Nach einer nicht rückwärtskompatiblen Migration genügt kein Image-Downgrade:
Datenbank und Medien werden gemeinsam aus demselben Pre-Update-Stand
wiederhergestellt. Erst danach wird der vorherige Image-Tag gestartet.

## Phase-4a-Abnahme

Vor Phase 4b müssen erfolgreich dokumentiert sein: DNS/TLS/Header, Authentik
User/Admin/Ablehnung, Pretix-Testimport, Nextcloud-Schreiben und -Lesen,
vollständiger synthetischer Ablauf bis PDF/WebDAV/Download sowie ein isolierter
Backup-Restore. Ohne diese Ergebnisse bleibt der Pilot gestoppt.
