# Werkblatt-Pilot

Dieser Stack integriert die eigenständige Open-Source-Anwendung Werkblatt in die
Zircula-Infrastruktur. Die Software selbst bleibt im Repository
`IndieStu/Werkblatt`; dieses Verzeichnis enthält ausschließlich die
Zircula-spezifische Betriebsintegration.

## Festgelegter Softwarestand

Der Build-Kontext ist unveränderlich auf Werkblatt-Commit
`cf1b749899790fc977327609c2703817756b458b` festgelegt. Das resultierende lokale
Image erhält den Commit als Tag. Buildversion `0.1.0-dev.cf1b749` und commitgenaue
Quellcode-URL werden in Anwendung und OCI-Labels ausgewiesen. Build, Image-ID
und kontrollierter Rollout sind unten dokumentiert; der vollständige
synthetische E2E bleibt eine gesonderte Betriebsprüfung.
PostgreSQL ist sichtbar auf Version 17.11 und zusätzlich unveränderlich auf den
geprüften Image-Digest
`sha256:67f41722b7a8cbdb868a44a4995c846eddfdc2973bccb291ce937dce88ad5675`
festgelegt. Major-Upgrades werden nicht über einen regulären Dependabot-PR
ausgerollt, sondern benötigen einen eigenen Migrations- und Restoreplan.
Das Minor-Update von 17.10 wurde am 5. September 2026 nach erfolgreichem
zentralem Backup und Preflight durch Austausch ausschließlich des
Datenbankcontainers ausgerollt. Webcontainer, Caddy, Netzwerke und Volumes
blieben unverändert. PostgreSQL-Version, Migrationen, interne Readiness,
öffentlicher Healthcheck, Statistik, CSV-Export und Logs wurden geprüft.

Der vorherige Pilotstand war Commit
`7c0f9755c495ac416d76565098292f3999b6bf77` mit Image-ID
`sha256:8b6c540b855494126bfa0b02c9f1b5065f3e6446d7292062fe93d28efb81f83e`.
Der am 22. September 2026 ausgerollte Stand ergänzt einen konfigurierbaren
Pretix-Importstichtag,
tenantgebundene Pretix-Veranstaltungsregeln, Workshopfilter und reversible
Sichtbarkeit. Zusätzlich aktualisiert er den PDF-Renderer wegen
`CVE-2026-55073` auf WeasyPrint 70. Er enthält die Migrationen `workshops.0003`
und `documents.0004`; Caddy, Netzwerke und Persistenzpfade bleiben unverändert.

Der isolierte VPS-Build des vorherigen Release Candidates ergab Image-ID
`sha256:edde2bb7f70456dbaac257131dba49e06ac29c45ac0a1bf369859389f7e84e92`.
Der RC ergänzt gegenüber dem laufenden Stand insbesondere reversible
Pretix-Absagen, Workshopkalender und Supply-Chain-/Lizenzdrift-Gates. Er enthält
die additive Migration `workshops.0004_workshop_lifecycle_status`. Der laufende
Pin bleibt bis zur Abnahme als Rollbackgrundlage erhalten:
`ed861f38c64f26c2fd3fcbfef71a40be20039629` mit Image-ID
`sha256:e35b1ea14ac6d7be90fb439d720dd33b7fae9813c2fe1da2539917b15f006dd4`.

Der isolierte VPS-Build von RC2 ergab Image-ID
`sha256:16daa59c54706ca977deee655409e932f835790d23c786d9cda5909033adb134`.
RC2 ergänzt die persönliche Kalender-/Listenpräferenz und unterscheidet bei
manuell erfassten Teilnehmenden spontane Teilnahme von einer Anmeldung
außerhalb Pretix. Er enthält die additive Migration
`identities.0004_user_preferred_workshop_view`. Der laufende RC1-Pin bleibt
bis zur Abnahme die Rollbackgrundlage.

RC2 wurde am 25. September 2026 nach erfolgreichem zentralem Backup und
Repository-Preflight ausgerollt. Die Migration wurde separat angewendet und
ausschließlich der Webcontainer ersetzt. PostgreSQL behielt Container-ID,
Image, Startzeit und Restart-Zähler; Caddy, Netzwerke, Secrets und Persistenz
blieben unverändert. Interne Readiness, öffentlicher Healthcheck, Login und
OIDC-Einstieg waren erfolgreich; der Webcontainer blieb gesund und ohne
Restarts.

Der isolierte VPS-Build von RC3 ergab Image-ID
`sha256:cbb46e322193625d07f2cc80bc8fab15048ea0efb6dbd8161af8e8ee0e5c6858`.
Der Hotfix aktualisiert Zusatzfelder unmittelbar nach der Vorlagenauswahl,
erhält bereits eingegebene Dokumentationsdaten, bietet neuere Vorlagenstände
bewusst an und ermöglicht dynamisch beliebig viele Zusatzfelder. RC3 enthält
keine Datenbankmigration. Der laufende RC2-Pin bleibt bis zur Abnahme die
Rollbackgrundlage.

RC3 wurde anschließend kontrolliert ausgerollt und ist die Rollbackgrundlage
für den nächsten Pilotstand. Der isolierte Build des neuen Stands ergab
Image-ID
`sha256:29ffbfbf000943a4e517970f2ef81e5d396e1c11ad06e39d6ada08187ba57aaa`.
Er ergänzt die geführte Erstellung und Veröffentlichung einfacher
Pretix-Veranstaltungen aus Werkblatt. Presets und Fördertexte sind
organisationsgebunden; die Pretix-Vorlage wird vor Nutzung schreibgeschützt
geprüft. Der Stand enthält die additive Migration
`workshops.0005_pretix_event_creation`. Bis Backup, Preflight, Migration und
synthetischer E2E abgeschlossen sind, bleibt RC3 unverändert laufende
Rollbackgrundlage.

Der RC wurde am 24. September 2026 nach erfolgreichem zentralem Backup und
Repository-Preflight ausgerollt. Die additive Migration
`workshops.0004_workshop_lifecycle_status` wurde getrennt angewendet und
ausschließlich der Webcontainer ersetzt. PostgreSQL behielt Container-ID,
Image, Startzeit und Restart-Zähler; Caddy, Netzwerke, Secrets und
Persistenzpfade blieben unverändert. Interne Readiness, öffentlicher
Healthcheck und Login-Einstieg antworteten mit 200; der Webcontainer blieb
gesund und ohne Restarts. Der erste reguläre Abgleich meldete 28 aktive und
3 abgesagte Workshops sowie 47 aktive Anmeldungen.

Der erste Timerstand verwendete irrtümlich `/run/lock` und scheiterte vor
Docker- und Pretix-Zugriff mit `Permission denied`. Der Timer wurde gestoppt
und der Lockpfad auf das von systemd verwaltete Runtime-Verzeichnis
`/run/zircula-werkblatt` umgestellt. Kontrollierter Dienststart und der beim
erneuten Aktivieren ausgelöste Timerlauf endeten anschließend jeweils mit
`Result=success` und `ExecMainStatus=0`; der nächste Lauf wurde regulär geplant.

Der AGPL-Pin wurde am 24. September 2026 nach einem erfolgreichen zentralen
Backup (`Result=success`, `ExecMainStatus=0`) und Repository-Preflight
ausgerollt. Der getrennte Django-Migrationslauf meldete keine anzuwendenden
Migrationen. Ersetzt wurde ausschließlich der Webcontainer; er startete mit
der dokumentierten Image-ID, meldete interne Readiness 200 und blieb ohne
Restart oder Fehlermuster. Der öffentliche Healthcheck und der tatsächliche
Login-Einstieg antworteten mit 200. Der commitgenaue Quellcode-Link wurde auf
der öffentlichen Loginseite verifiziert. PostgreSQL behielt Container-ID,
Image, Startzeit und Restart-Zähler; Caddy, Netzwerke, Secrets und Persistenz
blieben unverändert.

Der vorherige WebDAV-Pin war
`20f8bffaf78f33cef58a502d41403508482fe717` mit Image-ID
`sha256:f58d78024cb2c489f8a4c427c9d7a8b4ca7aed4423967a2eeda9e5f2ebe93ee6`.
Dieser entfernte die interne Organisations-UUID aus dem menschenlesbaren
WebDAV-Pfad und wurde am 23. September 2026 erfolgreich ausgerollt.
Der neue Pin wurde am 24. September 2026 nach erfolgreichem zentralem Backup
und Preflight durch Austausch ausschließlich des Webcontainers ausgerollt.
PostgreSQL behielt Container-ID, Image und Startzeit; Caddy, Netzwerke,
Persistenz und Konfiguration blieben unverändert. Interner und öffentlicher
Healthcheck antworteten mit 200, Restart- und Fehlerzähler blieben bei null.
Nach erfolgreichem zentralem Backup und Preflight wurden `documents.0004` und
`workshops.0003` separat angewendet und ausschließlich der Webcontainer ersetzt.
PostgreSQL, Caddy, Netzwerke und Persistenz blieben unverändert. Interner und
öffentlicher Healthcheck antworteten mit 200; der Container blieb ohne Restart
und ohne Fehler im Startzeitraum. Der reguläre Pretix-Sync vom 23. September
2026 ab dem Zircula-Stichtag `2026-08-25` verarbeitete anschließend 27 Workshops
und 42 bestätigte Anmeldungen. Bereits vorhandene synthetische Pilotdaten blieben
erhalten.

Die Renderer-Prüfungen des vorherigen Pilotstands waren zweimal byte-identisch:

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

Bei einer Neuinstallation werden die Pfade mit den Container-UIDs vorbereitet:

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
wird nicht verwendet. Reguläre Importe sind installationsseitig auf Termine ab
`2026-08-25` begrenzt. Der Stichtag ist eine Zircula-Betriebseinstellung und
keine allgemeine Werkblatt-Produktvorgabe. Vor dem ersten regulären Import
werden die stabilen Pretix-Event-Slugs geprüft und notwendige Reihenregeln in
Werkblatt angelegt. Für den Pilot sind `Naehwerk` und `zirculalabs` reversibel
vom Import ausgeschlossen und als nicht dokumentationspflichtig markiert. Ein
Testmode-Event wird ausschließlich mit expliziter Referenz importiert:

```bash
docker compose run --rm web python manage.py sync_pretix \
  --include-test-events --workshop-reference SYNTHETIC-TEST-EVENT
```

Nextcloud erhält einen technischen Werkblatt-Benutzer, ein App-Passwort und
einen dedizierten Zielordner. Der End-to-End-Test verwendet ausschließlich
synthetische Personen und Dokumente.

## Periodischer Pretix-Abgleich

Der reguläre Pretix-Abgleich läuft nach erfolgreichem RC-Rollout als gehärteter
systemd-Oneshot alle 15 Minuten mit bis zu zwei Minuten zufälliger Verzögerung.
Ein nicht blockierender `flock` in dem von systemd verwalteten, privaten
Runtime-Verzeichnis `/run/zircula-werkblatt` verhindert überlappende Läufe. Der
Dienst verwendet ausschließlich den bereits laufenden Webcontainer und dessen
geschützte Konfiguration; Secrets werden weder kopiert noch als Argumente
übergeben.

```bash
sudo install -o root -g root -m 0755 \
  scripts/sync-pretix /usr/local/sbin/zircula-werkblatt-pretix-sync
sudo install -o root -g root -m 0644 \
  systemd/zircula-werkblatt-pretix-sync.service \
  systemd/zircula-werkblatt-pretix-sync.timer \
  /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now zircula-werkblatt-pretix-sync.timer
```

Vor Aktivierung wird der Dienst einmal manuell gestartet und mit
`systemctl show`, `journalctl` und der Werkstattliste geprüft. Fehler bleiben
im Journal sichtbar und werden nicht durch einen erfolgreichen Timerstatus
verdeckt.

## Preflight, Migration und Start

```bash
# Bereits in Phase 4a erfolgt und nur bei bewusstem neuen Gate zu wiederholen:
docker compose build --pull web
docker image inspect werkblatt:7bb3eca8a111b083ca2dd4cfd67d069b8f8ef90f \
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

PostgreSQL-Minor-Updates innerhalb Version 17 erfolgen erst nach erfolgreichem
zentralem Backup. Vor dem Austausch werden alter Container, Image-ID und
Datenbankversion festgehalten. Nach `docker compose up -d --no-deps db` werden
Container-Health, `SELECT version()`, Werkblatt-Readiness und öffentlicher
Healthcheck geprüft. Der vorherige Digest bleibt bis zur Abnahme lokal als
Rollbackstand verfügbar.

## Phase-4a-Abnahme

Vor Phase 4b müssen erfolgreich dokumentiert sein: DNS/TLS/Header, Authentik
User/Admin/Ablehnung, Pretix-Testimport, Nextcloud-Schreiben und -Lesen,
vollständiger synthetischer Ablauf bis PDF/WebDAV/Download sowie ein isolierter
Backup-Restore. Ohne diese Ergebnisse bleibt der Pilot gestoppt.
