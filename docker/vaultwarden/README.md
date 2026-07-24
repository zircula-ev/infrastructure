# Vaultwarden

Dieser Stack bereitet einen gehärteten, selbst gehosteten Passwortmanager unter
`vault.zircula.org` vor. Maßgeblich für Governance, Authentik-OIDC, Organisationen,
Backup und Rollback ist `../../docs/11-vaultwarden.md`.

Vaultwarden ist eine Bitwarden-kompatible, aber nicht von Bitwarden angebotene
Serverimplementierung. Vor der produktiven Aufnahme von Geheimnissen sind ein
verschlüsseltes externes Backup und ein erfolgreicher Restore-Test zwingend.

## Sicherheitsprofil

- fest gepinntes Image `vaultwarden/server:1.36.0`
- Prozess als UID/GID 1000, nicht als root
- interner unprivilegierter Port 8080
- kein Host-Port; Veröffentlichung ausschließlich über Caddy
- read-only Root-Dateisystem und begrenztes `/tmp`
- `no-new-privileges`, `cap_drop: ALL`, kein Docker-Socket
- einzig schreibbarer Hostpfad: `/srv/zircula/vaultwarden/data`
- SQLite mit WAL für die kleine erste Ausbaustufe
- Selbstregistrierung im Normalbetrieb und serverweite Admin-Konsole deaktiviert
- Sends, Passwort-Hinweise, E-Mail-Änderungen und externe Icon-Downloads deaktiviert
- Einladungen nur durch Organisationsadministratoren
- OIDC mit PKCE; unsichere Zuordnung bei unbekanntem E-Mail-Verifikationsstatus
  ausdrücklich deaktiviert

Root und Mitglieder der Docker-Gruppe können Container-Umgebung und Datenpfad
weiterhin lesen. Diese Hostrollen bleiben daher hochprivilegiert.

## Dateien und Daten

- `compose.yaml` – Container und Hardening
- `.env.example` – Platzhalter ohne produktive Geheimnisse
- `.env` – lokale Werte; nicht versioniert, Modus 600
- `scripts/preflight.sh` – ausgabearme Erstprüfung
- `/srv/zircula/vaultwarden/data` – Datenbank, Schlüssel und Anhänge

## Erstvorbereitung

Noch nicht starten, solange `.env` Platzhalter enthält oder Authentik nicht
vorbereitet ist.

```bash
cd /opt/zircula/git/infrastructure/docker/vaultwarden

sudo install -d -o 1000 -g 1000 -m 700 \
  /srv/zircula/vaultwarden/data

cp .env.example .env
chmod 600 .env
```

Danach in Authentik eine vertrauliche OAuth2/OIDC-Anwendung mit Authorization
Code, Refresh Token und PKCE erstellen. Die strikte Redirect-URI lautet:

```text
https://vault.zircula.org/identity/connect/oidc-signin
```

Issuer/Authority:

```text
https://auth.zircula.org/application/o/vaultwarden/
```

Scopes: `openid profile email offline_access`. In den erweiterten
Provider-Einstellungen wird die Access-Code-Laufzeit bei einer Minute belassen,
die Access-Token-Laufzeit aber auf mindestens zehn Minuten gesetzt. Zugriff
nur an ausdrücklich berechtigte Authentik-Gruppen binden. Client-ID und
Client-Secret kommen ausschließlich in die lokale `.env`.

## SMTP

Der getestete Übergangsabsender ist ein eigenständiges Manitu-Postfach:

```text
Host: mail.manitu.de
Port: 465
Sicherheit: force_tls
Absender/Benutzername: noreply@nextcloud.zircula.org
Timeout: 15 Sekunden
```

Port 465 verwendet implizites TLS und darf in Vaultwarden nicht mit
`starttls` kombiniert werden. Als Benutzername wird die vollständige,
explizit dem lokalen Postfach zugeordnete E-Mail-Adresse verwendet. Nur das
Postfachkennwort bleibt geheim in der lokalen `.env`.

Vor der Aktivierung wird TLS und Anmeldung unabhängig von Vaultwarden geprüft.
Danach werden Anmeldung, neues Gerät, Verifikation und Einladung über
Vaultwarden getestet. Ein SMTP-Fehler kann Registrierung oder Anmeldung bis zum
Timeout blockieren.

Der reguläre Betrieb erfolgt ausschließlich mit `docker compose up -d` aus
diesem Verzeichnis. Dateien unter `/tmp/vaultwarden-*.override.yaml` sind nur
kurzlebige Diagnosehilfen, gehören nicht ins Repository und dürfen nicht Teil
des dauerhaften Startbefehls sein. Nach einer Diagnose wird der Container mit
der regulären Compose-Konfiguration neu erstellt.

Debug-, erweitertes Request- und SSO-Token-Logging bleiben deaktiviert. Voller
Debug-Level kann OAuth-Access- und Refresh-Tokens ausgeben.

## Kontrollierter Erst-Owner

Vaultwarden besitzt ohne Admin-Konsole und bei geschlossener Registrierung noch
kein Konto. Für genau den ersten Owner ist deshalb ein kurzes Bootstrap-Fenster
nötig:

1. Caddy vorübergehend mit einem `remote_ip`-Matcher auf die aktuelle Admin-IP
   begrenzen; alle anderen Anfragen an `vault.zircula.org` mit 403 beantworten.
2. `VAULTWARDEN_SIGNUPS_ALLOWED=true` setzen und nur Vaultwarden neu erstellen.
3. den persönlichen ersten Owner anlegen und E-Mail bestätigen.
4. sofort `VAULTWARDEN_SIGNUPS_ALLOWED=false` setzen und neu erstellen.
5. von einem zweiten Netz prüfen, dass Registrierung geschlossen ist.
6. den temporären IP-Matcher entfernen und Caddy neu laden.

Das Bootstrap-Fenster wird nicht offengelassen und nicht für reguläres
Onboarding verwendet. Weitere Benutzer werden ausschließlich von einer
Organisation eingeladen.

## Preflight und interner Start

```bash
./scripts/preflight.sh
docker compose pull
docker compose up -d
docker compose ps
docker compose logs --tail=100 vaultwarden

docker compose exec vaultwarden id
docker compose exec vaultwarden /healthcheck.sh
```

Vor der Caddy-Veröffentlichung intern aus dem Frontend-Netz prüfen:

```bash
docker run --rm --network zircula_frontend \
  curlimages/curl:8.16.0 \
  --fail --silent http://vaultwarden:8080/alive
```

Erwartet werden UID/GID 1000, ein gesunder Container und kein Host-Port.

## Veröffentlichung und Nachtest

Erst nach dem internen Test Caddy validieren und neu laden:

```bash
cd ../caddy
docker compose exec caddy caddy validate --config /etc/caddy/Caddyfile
docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile

curl -fsS https://vault.zircula.org/alive
```

Danach prüfen:

1. Registrierung ist geschlossen.
2. OIDC-Login mit berechtigtem Testkonto funktioniert.
3. Konto ohne Authentik-Binding wird abgewiesen.
4. Einladung, Bestätigung und Vault-Entsperrung funktionieren.
5. Organisations- und Collection-Rechte funktionieren mit einem Testeintrag.
6. Entzug in Authentik verhindert eine neue SSO-Anmeldung.
7. Entzug in Vaultwarden entfernt Organisations- und Collection-Zugriff.
8. WebSocket-Synchronisation funktioniert in Web-, Desktop- und Mobil-Client.
9. SMTP-Test, neues Gerät und Einladungsmail kommen an.
10. `/admin` ist nicht nutzbar.

Nach dem Erstellen der vorgesehenen Organisationen
`VAULTWARDEN_ORG_CREATION_USERS=none` setzen und nur Vaultwarden neu erstellen.

## Update

Release Notes und Security Advisories lesen; insbesondere OIDC-, Web-Vault- und
Datenbankänderungen prüfen. Vor dem Update Backup und Restore-Fähigkeit bestätigen.

```bash
./scripts/preflight.sh
docker compose pull
docker compose up -d
docker compose ps
docker compose logs --tail=100 vaultwarden
docker compose exec vaultwarden /healthcheck.sh
```

Danach OIDC, Vault-Entsperrung, Synchronisation, Organisationen, Collections,
Anhänge, SMTP und öffentliche `/alive`-Probe testen.

## Rollback

Bei Fehlern zuerst die Caddy-Route wieder entfernen oder auf den zuvor getesteten
Commit wechseln. Ein Image-Downgrade nach einer Datenmigration ist kein sicherer
Rollback. Datenbank und kompletter Datenpfad werden aus dem vor dem Update
erstellten Backup wiederhergestellt. Details stehen in
`../../docs/11-vaultwarden.md`.
