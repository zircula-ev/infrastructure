# 22 – Werkblatt Phase 4a: VPS-Preflight

Stand: 29. August 2026. Dieser Bericht dokumentiert die laufende Prüfung des
isolierten Piloten. Er erteilt keine Freigabe für Phase 4b.

## 1. Geprüfter Commit

Die Anwendung ist auf
`b0618d34ac97f2384bac59ef632cbaa4e7746429` festgelegt. Der aktuell auf dem VPS
geprüfte Infrastructure-Commit ist
`d4913ae2616b2ba74d9a68a9562bcd452680cd2b`.

Werkblatt-CI Run 22 war für diesen Commit vollständig erfolgreich. Der isolierte VPS-Build ergab Image-ID
`sha256:a01cd9ddc1f72b7bc4347047005a1c597b4af609e745cb6a039a6fee94bf0012`.

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
`Werkblatt Users` und `Werkblatt Admins`. Provider, Application, Claim-Mapping
und beide Gruppen wurden nach geprüftem Authentik-Backup additiv angelegt.
Discovery bestätigt den anwendungsspezifischen Issuer und PKCE S256. Das Secret
liegt ausschließlich auf dem Host. User-, Admin- und Ablehnungsfall bleiben als
Browserprüfungen offen.

## 6. Pretix

Verwendet werden der kanonische Ursprung `https://pretix.eu`, Organizer `werk`, ein eigener
read-only Token und ein explizit benanntes synthetisches Testmode-Event. Ein in
anderen Anwendungen vorhandenes Credential wird weder gelesen noch
wiederverwendet. Testmode-Import ohne explizite Referenz wird von Werkblatt
abgewiesen. Der begrenzte Import von `blanko` synchronisierte erfolgreich genau
einen synthetischen Workshop und eine synthetische aktive Anmeldung; Namen
wurden bei der technischen Verifikation nicht ausgegeben.

## 7. WebDAV/Nextcloud

Ein eigener technischer Benutzer, ein App-Passwort und der dedizierte Ordner
`/Werkblatt` wurden angelegt. Schreiben, Lesen und idempotentes Überschreiben
einer synthetischen Probe waren erfolgreich und byte-identisch. Der vollständige
PDF-Upload aus Werkblatt und ein absichtlich fehlgeschlagener Upload mit Retry
bleiben Bestandteil des E2E. Finalisierung und externer Storage bleiben fachlich
getrennt.

## 8. Secret-Handling

`.env` enthält keine Secrets und hat Modus 600. Sechs einzelne, ignorierte
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

## 11. Migration und Rollback

Das neue Image wird zuerst gebaut und per Image-ID dokumentiert. Vor Update
werden Custom-Dump, Medien-Checkpoint und vorheriges Image festgehalten.
Migrationen laufen einmalig mit exakt dem neuen Image, getrennt vom Webstart.
Nach nicht rückwärtskompatibler Migration werden Datenbank und Medien gemeinsam
aus demselben Pre-Update-Stand restauriert; ein Image-Downgrade allein ist kein
Rollback.

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

- reale OIDC-Rollen- und Ablehnungsfälle noch nicht per Browser abgenommen;
- WebDAV-Vertrag geprüft, aber vollständiger Werkblatt-PDF-Upload und Fehler-Retry offen;
- Werkblatt-Restore auf dem VPS noch nicht durchgeführt;
- kein Swap, daher Ressourcenbeobachtung bei WeasyPrint und Backup;
- endgültige Open-Source-Lizenzentscheidung weiterhin offen.

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
