# 22 – Werkblatt Phase 4a: VPS-Preflight

Stand: 22. September 2026. Dieser Bericht dokumentiert Preflight und den
kontrollierten Rollout des isolierten Zircula-Piloten. Er erteilt keine Freigabe
für weitere Organisationen oder einen öffentlichen Release.

## 1. Geprüfter Commit

Der ausgerollte Anwendungspin ist
`762faba8f4b03d01c5db734250470cf0f19c9b6c`; seine Image-ID ist
`sha256:76f4406d4ece378c2418a8e17f705808941a86d986d8d9f38b950cf2840b7ed7`.
Der produktive Infrastructure-Checkout wurde mit sauberem Arbeitsbaum per
Fast-forward auf `f13d6e5661b68f5bf5842751b2fc43fc82f2c2d5` aktualisiert.

Der seit 23. September 2026 laufende Anwendungspin ist
`20f8bffaf78f33cef58a502d41403508482fe717` mit isoliert gebauter Image-ID
`sha256:f58d78024cb2c489f8a4c427c9d7a8b4ca7aed4423967a2eeda9e5f2ebe93ee6`.
Er behandelt `WEBDAV_ROOT` als organisationsbezogenen Zielordner und entfernt
die interne Organisations-UUID aus dem sichtbaren Ablagepfad. Für Zircula ist
`ZIRCULA Intern/Workshopdokumentation/<Jahr>/<Dateiname>.pdf` festgelegt. Das
Image wurde nach erfolgreichem zentralem Backup und Preflight durch Austausch
ausschließlich des Webcontainers gestartet. PostgreSQL, Caddy, Netzwerke und
Persistenz blieben unverändert. Interner und öffentlicher Healthcheck antworteten
mit 200; Restart- und Fehlerzähler blieben bei null. Das vorhandene Pilot-PDF
wurde zunächst in den neuen Jahresordner kopiert, mit 98.921 Byte gegen den
Datensatz verifiziert, auf den neuen Storage-Key umgestellt und erst danach am
alten Ort entfernt. Ein abschließender WebDAV-HEAD bestätigte das neue Ziel mit
200 und den alten Pfad mit 404.

Der seit 24. September 2026 laufende Anwendungspin ist
`4e28a642e2e46df38ad42ffc25d1d7d750d56383` mit isoliert gebauter Image-ID
`sha256:7a39c6ac648935ec942459291fe95b71a1184dfefd949eab1a5ac0a98c323261`.
Er ergänzt die native Workshopanlage und -bearbeitung für alle Rollen mit
Dokumentationsrecht und benötigt keine Migration. Vor dem Rollout waren
zentraler Backup-Lauf und Repository-Preflight erfolgreich. Ausschließlich der
Webcontainer wurde ersetzt; PostgreSQL behielt Container-ID, Image und Startzeit.
Caddy, Netzwerke, Persistenz und Konfiguration blieben unverändert. Interner und
öffentlicher Healthcheck antworteten mit 200, Restart- und Fehlerzähler blieben
bei null.

Der seit 24. September 2026 laufende AGPL-Anwendungspin ist
`ed861f38c64f26c2fd3fcbfef71a40be20039629` mit isoliert gebauter Image-ID
`sha256:e35b1ea14ac6d7be90fb439d720dd33b7fae9813c2fe1da2539917b15f006dd4`.
Er setzt die freigegebene Lizenzierung des Programmcodes unter
`AGPL-3.0-or-later` um, grenzt das vorbehaltene Brand System ab und liefert
Lizenz-, Rechte- und Third-Party-Hinweise sowie den commitgenauen Quellcode-Link
aus. Vor dem Rollout meldeten zentraler Backup-Service und Repository-Preflight
Erfolg. Der separate Migrationslauf meldete keine anzuwendenden Migrationen.
Ausschließlich der Webcontainer wurde ersetzt; PostgreSQL behielt Container-ID,
Image, Startzeit und Restart-Zähler. Caddy, Netzwerke, Secrets und Persistenz
blieben unverändert. Interne Readiness, öffentlicher Healthcheck und der
tatsächliche Login-Einstieg antworteten mit 200; Webcontainer und Datenbank
blieben ohne Restart, die geprüften Startlogs ohne Fehlermuster.

Der unmittelbar vorherige Pilotstand war
`7c0f9755c495ac416d76565098292f3999b6bf77` mit Image-ID
`sha256:8b6c540b855494126bfa0b02c9f1b5065f3e6446d7292062fe93d28efb81f83e`.
Der neue Pin ergänzt Pretix-Veranstaltungsregeln, Workshopfilter, reversible
Sichtbarkeit und den installationsbezogenen Importstichtag. Er enthält die
Migrationen `workshops.0003` und `documents.0004` und aktualisiert WeasyPrint
wegen `CVE-2026-55073` auf Version 70. Datenbankcontainer, Persistenz, Netzwerke
und Caddy blieben unverändert; der Webcontainer wurde erst nach Backup und
erfolgreicher bewusster Migration ersetzt.

Der isolierte Build des neuen Pins auf dem VPS war erfolgreich und ergab
Image-ID `sha256:76f4406d4ece378c2418a8e17f705808941a86d986d8d9f38b950cf2840b7ed7`.
Vor dem Start meldete der zentrale Backup-Service `Result=success`; der
Repository-Preflight war erfolgreich. `documents.0004` und `workshops.0003`
wurden separat angewendet, der bestehende Organisations-Bootstrap blieb
idempotent und ausschließlich der Webcontainer wurde ersetzt. Interner und
öffentlicher Healthcheck antworteten mit 200, die Login-Weiterleitung war
korrekt, Restart- und Fehlerzähler blieben bei null.

## 2. Zielarchitektur auf dem VPS

Werkblatt erhält einen eigenen Web- und PostgreSQL-17-Container. Nur der
Webcontainer hängt an `zircula_frontend`; beide teilen das isolierte Netz
`werkblatt_internal`. Es gibt keine Hostports und keine Änderung an der
zentralen PostgreSQL-Instanz. Persistenz liegt unter `/srv/zircula/werkblatt`.

## 3. Container-, Volume- und Netzwerkressourcen

Web: 2 CPU, 1536 MiB RAM, 256 MiB tmpfs, 256 PIDs. Datenbank: 1 CPU, 1024 MiB
RAM, 256 MiB Shared Memory, 256 PIDs. Beide Root-Dateisysteme sind read-only,
ohne Capabilities und mit `no-new-privileges`. Der VPS besitzt 8 vCPU, 15 GiB
RAM, rund 9 GiB verfügbaren RAM, 205 GiB freien Speicher und keinen Swap.

## 4. Reverse Proxy, DNS und TLS

Manitu veröffentlicht autoritativ A `195.90.217.88` und AAAA
`2a00:6800:3:1128::1`; Cloudflare und Google lieferten beim letzten Check bereits
beide neuen Werte. Der lokale Resolver hielt die alten Werte noch bis zum
TTL-Ablauf im Cache. Caddy erhält ausschließlich den Host
`werkblatt.zircula.org`, die vorhandenen Security-Header und
`reverse_proxy werkblatt:8000`. A und AAAA zeigen auf den VPS; Caddy stellte nach
Validierung und kontrolliertem Recreate ein gültiges Zertifikat bereit.
`https://werkblatt.zircula.org/health/` antwortete mit 200. Nextcloud, Authentik,
Vaultwarden und LibreDesk antworteten nach dem Caddy-Recreate ebenfalls mit 200.

Der laufende Caddy-Container sah nach dem Git-Fast-forward noch den alten Inode
der einzeln bind-gemounteten `Caddyfile`. Ein Reload meldete deshalb korrekt
„config is unchanged“ und kannte die Werkblatt-Route nicht. Host-Datei und
Container-Datei wurden per SHA-256 und Routenprüfung verglichen. Das in
`docker/caddy/README.md` dokumentierte kontrollierte Caddy-Recreate übernahm
anschließend den aktuellen Mount. Persistente ACME-Daten blieben erhalten.

## 5. Authentik

Benötigt werden Application/Provider `Werkblatt`, confidential Authorization
Code mit PKCE S256, die exakte Callback-URL und ausschließlich die Gruppen
`Werkblatt Users`, `Werkblatt Editors` und `Werkblatt Admins`. Provider,
Application, Claim-Mapping, User- und Admin-Gruppe wurden nach geprüftem
Authentik-Backup additiv angelegt. Die leere Editor-Gruppe wurde anschließend
ebenfalls additiv angelegt; bestehende Mitgliedschaften blieben unverändert. Eine
bewusste Testzuweisung ist erst für den abschließenden OIDC-Rollentest notwendig.
Discovery bestätigt den anwendungsspezifischen Issuer und PKCE S256. Das Secret
liegt ausschließlich auf dem Host. User-, Editor-, Admin- und Ablehnungsfall
bleiben als Browserprüfungen offen.

## 6. Pretix

Verwendet werden der kanonische Ursprung `https://pretix.eu`, Organizer `werk`, ein eigener
read-only Token und ein explizit benanntes synthetisches Testmode-Event. Ein in
anderen Anwendungen vorhandenes Credential wird weder gelesen noch
wiederverwendet. Testmode-Import ohne explizite Referenz wird von Werkblatt
abgewiesen. Der begrenzte Import von `blanko` synchronisierte erfolgreich genau
einen synthetischen Workshop und eine synthetische aktive Anmeldung; Namen
wurden bei der technischen Verifikation nicht ausgegeben.

Vor dem ersten regulären Sync wurden ausschließlich Veranstaltungsmetadaten
geprüft. Die offenen Reihen `Naehwerk` und `zirculalabs` wurden durch
organisationsgebundene, reversible Regeln vom Import ausgeschlossen und als
nicht dokumentationspflichtig markiert. Der anschließend ausdrücklich
freigegebene Sync vom 23. September 2026 ab `2026-08-25` verarbeitete 27
Workshops und 42 bestätigte Anmeldungen. Die aggregierte Nachkontrolle ergab
keine importierte ausgeschlossene Reihe, keinen Workshop vor dem Stichtag und
keine organisationsfremde Zuordnung.

## 7. WebDAV/Nextcloud

Ein eigener technischer Benutzer, ein App-Passwort und der dedizierte Ordner
`/Werkblatt` wurden angelegt. Schreiben, Lesen und idempotentes Überschreiben
einer synthetischen Probe waren erfolgreich und byte-identisch. Der vollständige
PDF-Upload aus Werkblatt und ein absichtlich fehlgeschlagener Upload mit Retry
bleiben Bestandteil des E2E. Finalisierung und externer Storage bleiben fachlich
getrennt.

## 8. Secret-Handling

`.env` enthält keine Secrets, hat Modus 600 und gehört dem dedizierten
Deploymentbenutzer. Sechs einzelne, ignorierte
Secret-Dateien haben ebenfalls Modus 600 und werden als Compose-Secrets
read-only gemountet. Das identische Datenbankpasswort wird wegen der
dateibasierten Bind-Mount-Rechte getrennt für Web-UID 10001 und DB-UID 999
bereitgestellt; die übrigen Secrets gehören UID 10001. Direkter und
`*_FILE`-Wert gleichzeitig wird von Werkblatt abgewiesen. Werte erscheinen
weder in Git, Chat, Screenshots noch Logs.

## 9. Backup und Restore

Der tägliche Restic-Lauf und externe Spiegel waren beim Preflight gesund. Der
Branch ergänzt einen PostgreSQL-Custom-Dump der Werkblatt-Datenbank; rohe
Werkblatt-PostgreSQL-Dateien werden als primäre Restore-Quelle ausgeschlossen.
Ein logischer Dump und Restore in eine leere isolierte Testdatenbank war
erfolgreich; die synthetische Organisation war danach vorhanden. Ein
Restoretest aus dem tatsächlichen Restic-Lauf einschließlich Medien bleibt nach
dem ersten vollständigen synthetischen Backup auszuführen.

## 10. Monitoring und Healthchecks

Docker prüft `/ready/` mit Datenbankzugriff und simuliert dabei den vom
vertrauenswürdigen Reverse Proxy gesetzten HTTPS-Header; Blackbox prüft öffentlich
`/health/` ohne Datenbank. Logs rotieren bei 10 MiB mit fünf Dateien;
Gunicorn-Accesslogs sind deaktiviert. PII, Dokumentinhalte, Tokens und komplette
WebDAV-Pfade dürfen nicht als Logs oder Labels erscheinen.

Die lokale `.env` wurde nach Merge des Infrastructure-Pins um die nicht geheimen
Kooperationsangaben sowie `OIDC_EDITOR_GROUPS` ergänzt; `OIDC_ALLOWED_GROUPS`
enthält nun Admin-, Editor- und Workshop-User-Gruppe. Dabei wurden keine
Secret-Werte gelesen oder ausgegeben. Der laufende Altcontainer blieb
unverändert und übernimmt diese Werte erst bei einem ausdrücklich freigegebenen
kontrollierten Update.

## 11. Migration und Rollback

Das neue Image wird zuerst gebaut und per Image-ID dokumentiert. Vor Update
werden Custom-Dump, Medien-Checkpoint und vorheriges Image festgehalten.
Migrationen laufen einmalig mit exakt dem neuen Image, getrennt vom Webstart.
Nach nicht rückwärtskompatibler Migration werden Datenbank und Medien gemeinsam
aus demselben Pre-Update-Stand restauriert; ein Image-Downgrade allein ist kein
Rollback.

Der Werkblatt-PostgreSQL-Container bleibt innerhalb Major-Version 17. Das
Minor-Update von 17.10 auf 17.11 benötigt laut Upstream weder `pg_upgrade` noch
Dump/Restore, wird aber erst nach erfolgreichem zentralem Backup und mit
festgehaltenem vorherigem Digest ausgerollt. Werkblatt verwendet weder
`btree_gist` noch `ltree` oder GIN-Indizes; die für 17.11 genannten besonderen
Nacharbeiten treffen diesen Datenbestand daher nicht.

Der Rollout erfolgte am 5. September 2026 nach erfolgreichem zentralem Backup
und Preflight. Der Datenbankcontainer wurde vom vorherigen Digest
`sha256:0af65001d05296a2ead57ac4a6412433d8913d1bb5d0c88435a7d1e1ee5cb04b`
auf PostgreSQL 17.11 mit Digest
`sha256:67f41722b7a8cbdb868a44a4995c846eddfdc2973bccb291ce937dce88ad5675`
ersetzt. Der Webcontainer behielt ID und Startzeit. Datenbank-Health,
`SELECT version()`, 30 angewendete Migrationen, Django-Migrationscheck, interne
Readiness, öffentlicher Healthcheck, authentifizierte Statistik und CSV-Export
sowie die Logprüfung waren erfolgreich.

## 12. Synthetischer End-to-End-Test

Lokale Fach-, Security-, Static-, PDF- und Storage-Tests sowie Compose-, Caddy-
und isolierter VPS-Imagebuild sind erfolgreich. PostgreSQL-Initialisierung,
Migration, Bootstrap, logischer Dump/Restore, interne Readiness 200, öffentlicher
HTTPS-Healthcheck 200 und der reale Pretix-Testimport waren unter den
vorgesehenen Containerrestriktionen erfolgreich; es gab keine Hostports. Die zwei PDF-Durchläufe waren
für Teilnahmeliste und Abschlussbericht jeweils byte-identisch. Der reale Weg
Login → Workshop → Teilnehmende → Vorlage → Dokumentation → Finalisierung →
WeasyPrint-PDF → WebDAV → Download bleibt bis zu den Authentik-Browserprüfungen
und der vollständigen Dokumenterzeugung offen. Er wird nicht durch Mocks
als Produktions-E2E ersetzt.

## 13. Verbleibende Risiken

- reale OIDC-Rollen einschließlich Editor- und Ablehnungsfall noch nicht
  vollständig per Browser abgenommen;
- WebDAV-Vertrag geprüft, aber vollständiger Werkblatt-PDF-Upload und Fehler-Retry offen;
- Werkblatt-Restore auf dem VPS noch nicht durchgeführt;
- kein Swap, daher Ressourcenbeobachtung bei WeasyPrint und Backup;
- Open-Source-Lizenzentscheidung mit Werkblatt-Commit
  `ed861f38c64f26c2fd3fcbfef71a40be20039629` abgeschlossen:
  Programmcode `AGPL-3.0-or-later`, Werkblatt Brand System ausdrücklich
  vorbehalten; vollständiger Lizenztext, Notices, Third-Party-Inventar,
  Buildversion und exakter Source-Link werden im Image beziehungsweise in der
  Anwendung ausgeliefert.

## 14. Schritte bis und für Phase 4b

1. Alle weiteren Infrastructure-Änderungen weiterhin ausschließlich per PR
   mergen; produktiver Checkout bleibt auf `main`.
2. Öffentliche Security-Header abschließend bestätigen und Monitoringprobe ergänzen.
3. Persistenz, Secrets, Images und IDs sind vorbereitet; vor jedem Update erneut prüfen.
4. Vorhandene additive Authentik-Konfiguration mit drei Berechtigungsfällen testen.
5. Dedizierte Pretix-/Nextcloud-Zugänge sind hinterlegt; nur im E2E verwenden.
6. Datenbank, Migration und Organisations-Bootstrap sind erfolgt; Zustand vor
   dem E2E erneut prüfen.
7. Vollständigen synthetischen E2E durchführen.
8. Werkblatt-Backup erzeugen und isoliert wiederherstellen.
9. Den finalen Phase-4a-Bericht vorlegen und stoppen.
10. Erst nach erneuter ausdrücklicher Freigabe den Zircula-Pilot als Phase 4b
    produktiv schalten.

## 15. Phase-4b-Rollout von `v0.1.0-rc.1`

Der kontrollierte Zircula-Pilot wurde am 24. September 2026 auf den
veröffentlichten Werkblatt-Prerelease `v0.1.0-rc.1`, Commit
`884d7e0dfbf6fd9f604a0818f09f5a1f4e2b985f`, aktualisiert. Vor dem Rollout
lief der zentrale Backup-Service um 14:56 CEST mit `Result=success` und
`ExecMainStatus=0`; anschließend bestand der commit- und Image-ID-gebundene
Repository-Preflight.

Der Migrationsplan enthielt ausschließlich die additive Migration
`workshops.0004_workshop_lifecycle_status`. Sie wurde separat mit dem neuen
Image angewendet. Danach wurde nur der Webcontainer ersetzt. Der
PostgreSQL-Container behielt ID, Image, Startzeit und Restart-Zähler. Caddy,
Netzwerke, Secrets und Persistenzpfade wurden nicht verändert. Interne
Readiness, öffentlicher Healthcheck und Login-Einstieg antworteten mit 200;
Image-ID, Release-/Commitangabe, Source-URL und `AGPL-3.0-or-later`-Label
stimmten mit dem freigegebenen Stand überein.

Der erste reguläre Pretix-Abgleich synchronisierte 28 aktive und 3 abgesagte
Workshops sowie 47 aktive Anmeldungen. Der neu installierte 15-Minuten-Timer
scheiterte zunächst vor Docker- und Pretix-Zugriff an einem nicht
beschreibbaren Lockpfad unter `/run/lock`. Er wurde gestoppt, per PR auf das
private systemd-`RuntimeDirectory` `/run/zircula-werkblatt` korrigiert und erst
danach wieder aktiviert. Kontrollierter Diensttest und erster
timer-ausgelöster Lauf endeten jeweils erfolgreich; das Runtime-Verzeichnis
wurde nach dem Oneshot entfernt und der nächste Lauf regulär geplant. Der
Werkblatt-Webcontainer blieb gesund und ohne Restarts.

## 16. Rollout von `v0.1.0-rc.2`

Der veröffentlichte Prerelease `v0.1.0-rc.2`, Commit
`ffb675bd6d547d30c3ed729082b0e58e1f60aeb5`, wurde auf dem VPS isoliert als
Image
`sha256:16daa59c54706ca977deee655409e932f835790d23c786d9cda5909033adb134`
gebaut. Der zu diesem Zeitpunkt laufende RC1-Container wurde dabei nicht
ersetzt und blieb gesund.

Vor dem Rollout lief der zentrale Backup-Service am 25. September 2026 um
10:40 CEST mit `Result=success` und `ExecMainStatus=0`; danach bestand der
commit- und Image-ID-gebundene Repository-Preflight. Die additive Migration
`identities.0004_user_preferred_workshop_view` wurde separat mit dem neuen
Image angewendet und ausschließlich der Webcontainer ersetzt.

PostgreSQL behielt Container-ID, Image, Startzeit und Restart-Zähler. Caddy,
Netzwerke, Secrets und Persistenzpfade wurden nicht verändert. Interne
Readiness, öffentlicher Healthcheck und Login antworteten mit 200; der
OIDC-Einstieg leitete korrekt zu Authentik weiter. Buildversion, commitgenaue
Source-URL und `AGPL-3.0-or-later`-Label stimmten. Der neue Webcontainer war
gesund, hatte null Restarts und keine Fehlermuster im geprüften Startzeitraum.
Der Pretix-Timer blieb aktiv. Die beiden vorhandenen User erhielten durch die
Migration datenschutzneutral den Kalender als Standardansicht.

## 17. Vorbereiteter Hotfix-Rollout von `v0.1.0-rc.3`

Der veröffentlichte Prerelease `v0.1.0-rc.3`, Commit
`7bb3eca8a111b083ca2dd4cfd67d069b8f8ef90f`, wurde auf dem VPS isoliert als
Image
`sha256:cbb46e322193625d07f2cc80bc8fab15048ea0efb6dbd8161af8e8ee0e5c6858`
gebaut. Der laufende RC2-Container wurde dabei nicht ersetzt und blieb gesund.

RC3 enthält keine Migration. Vor dem Rollout sind zentraler Backup-Lauf und
Repository-Preflight erneut erfolgreich auszuführen. Danach wird ausschließlich
der Webcontainer ersetzt. PostgreSQL, Caddy, Netzwerke, Secrets und
Persistenzpfade bleiben unverändert. Nach dem Start werden Readiness,
öffentlicher Healthcheck, Login sowie der unmittelbare Vorlagenwechsel mit
synthetischen Daten geprüft.

## 18. Vorbereiteter Pilotstand mit Pretix-Erstellungsassistent

Werkblatt-Commit `cf1b749899790fc977327609c2703817756b458b` wurde auf dem
VPS isoliert als Image
`sha256:29ffbfbf000943a4e517970f2ef81e5d396e1c11ad06e39d6ada08187ba57aaa`
gebaut. Der zu diesem Zeitpunkt laufende RC3-Webcontainer wurde dabei nicht
verändert und blieb gesund. Der neue Stand enthält die additive Migration
`workshops.0005_pretix_event_creation`.

Der reale Test erfolgt erst nach erfolgreichem zentralem Backup, Preflight und
separatem Migrationslauf. In der Zircula-Organisation wird ein Admin-Preset für
die verborgene Pretix-Vorlage `blanko` angelegt und vor Nutzung über Werkblatt
schreibgeschützt verifiziert. Anschließend wird ausschließlich mit eindeutig
synthetischen Angaben eine Veranstaltung erstellt, veröffentlicht und sowohl in
Pretix als auch als tenantgebundener Werkblatt-Workshop geprüft. Erweiterte
Ticketarten, Pflichtfragen und E-Mail-Konfiguration bleiben bewusst im
Pretix-Control-Interface. Der Test darf keine realen Teilnehmerdaten enthalten.

Bis zur Abnahme bleibt RC3 die Rollbackgrundlage. Caddy, PostgreSQL-Container,
Netzwerke, Secrets und Persistenzpfade werden für dieses Update nicht verändert.
