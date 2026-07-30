# LibreDesk

Dieser Stack stellt das produktive interne IT-Support-Ticketing bereit. Der
VPS-Rollout sowie Mail, OIDC, MFA, Rollen, lokaler Break-Glass-Zugang und
Backup-Smoke-Test wurden erfolgreich geprüft. Slack `#it-support` bleibt bis
zur vollständigen Slack-Ablösung als Übergangskanal bestehen; neue Supportfälle
sollen regulär über LibreDesk und `itsupport@zircula.org` bearbeitet werden.

## Architektur

- LibreDesk 2.5.0 unter `support.zircula.org`
- keine veröffentlichten Hostports; Zugriff ausschließlich über Caddy
- getrennte Datenbank und Rolle in der zentralen PostgreSQL-Instanz
- eigener Stack `libredesk-redis`; keine Nutzung des Nextcloud-Redis
- Uploads unter `/srv/zircula/libredesk/uploads`
- Authentik über OIDC nur für zuvor in LibreDesk angelegte Agent:innen
- Anfragen regulärer Nutzer:innen per E-Mail ohne LibreDesk-Konto

LibreDesk ist ein vergleichsweise junges Projekt und wird deshalb eng
überwacht, regelmäßig gesichert und vor Updates besonders sorgfältig geprüft.
Slack `#it-support` bleibt nur für die Übergangszeit bis zur vollständigen
Slack-Ablösung erreichbar und ist kein paralleles Datei- oder Wissensarchiv.

## Secrets

Die versionierte `config.toml` enthält ausschließlich unkritische
Laufzeitwerte. Die lokale `.env` überschreibt darin den Anwendungsschlüssel
sowie die getrennten PostgreSQL- und Redis-Passwörter. Sie wird niemals committet und erhält Modus
600. Der Anwendungsschlüssel verschlüsselt gespeicherte Integrationsdaten. Sein
Verlust kann gesicherte Mailbox-Zugangsdaten unbrauchbar machen; er gehört in das
verschlüsselte Secret-Backup.

```bash
cp .env.example .env
chmod 600 .env
chmod 644 config.toml

openssl rand -hex 16
openssl rand -hex 32
openssl rand -hex 32
```

Die Werte werden direkt in `.env` eingetragen und nicht in Chats, Tickets oder
Shell-Befehle kopiert. `config.toml` enthält keine Secrets und benötigt Modus 644,
damit der Containerprozess mit UID 1000 sie auch dann lesen kann, wenn der
Deploymentbenutzer auf dem Host eine andere UID besitzt. Modus 600 führt in
diesem Fall absichtlich zu einem Preflight-Fehler.

## PostgreSQL vorbereiten

LibreDesk erhält die Rolle und Datenbank `libredesk`. Das Passwort wird in einer
interaktiven PostgreSQL-Sitzung gesetzt und muss anschließend exakt in
`docker/libredesk/.env` stehen.

```bash
cd /opt/zircula/git/infrastructure/docker/postgres
docker compose exec postgres sh -c 'psql -U "$POSTGRES_USER"'
```

In `psql`:

```sql
CREATE ROLE libredesk LOGIN;
\password libredesk
CREATE DATABASE libredesk OWNER libredesk;
REVOKE ALL ON DATABASE libredesk FROM PUBLIC;
\q
```

Falls Rolle oder Datenbank bereits existieren, wird nichts blind erneut
angelegt. Zuerst Eigentümer und Berechtigungen prüfen.

## Persistenz und Preflight

Das Image wird absichtlich als UID/GID 1000 betrieben:

```bash
sudo install -d -o 1000 -g 1000 -m 700 \
  /srv/zircula/libredesk/uploads

cd /opt/zircula/git/infrastructure/docker/libredesk
bash scripts/preflight.sh
```

## Startreihenfolge

1. PostgreSQL-Rolle und Datenbank anlegen.
2. `libredesk-redis` starten und authentifizierten Zugriff prüfen.
3. LibreDesk intern starten.
4. lokales System-/Break-Glass-Passwort setzen.
5. internen Healthcheck durchführen.
6. erst danach DNS und Caddy aktivieren.
7. Authentik-OIDC und Mailbox einrichten.
8. Negativ-, Backup- und Restore-Tests durchführen.

Start:

```bash
docker compose pull
docker compose up -d
docker compose ps
docker compose logs --tail=100 libredesk
```

Der Start führt die idempotente Installation und erforderliche
Datenbankmigrationen aus. Ein Containerstart ersetzt trotzdem weder ein
Vorher-Backup noch die Prüfung der Release Notes.

## Lokaler Break-Glass-Zugang

Nach dem ersten erfolgreichen Start wird das Passwort des lokalen
`System`-Kontos interaktiv gesetzt:

```bash
docker compose exec -it libredesk \
  ./libredesk --set-system-user-password --config /libredesk/config.toml
```

Das Passwort wird nicht als dauerhafte Umgebungsvariable hinterlegt. Es wird
offline verwahrt und in einer privaten Sitzung getestet, bevor OIDC aktiviert
wird.

## Interner Test

Vor Caddy und DNS:

```bash
docker run --rm --network zircula_frontend \
  curlimages/curl:8.16.0 \
  --fail --silent http://libredesk:9000/health

docker compose exec libredesk id

docker inspect --format \
  'user={{.Config.User}} privileged={{.HostConfig.Privileged}} readonly={{.HostConfig.ReadonlyRootfs}} ports={{json .NetworkSettings.Ports}}' \
  libredesk
```

Erwartet werden ein erfolgreicher Health-Endpunkt, UID/GID 1000, kein Hostport,
kein privilegierter Betrieb und ein schreibgeschütztes Root-Dateisystem.

## Authentik-OIDC

LibreDesk unterstützt keine automatische Agentenregistrierung über OIDC.
Agent:innen werden zuerst in LibreDesk mit derselben verifizierten E-Mail-Adresse
wie in Authentik angelegt.

Empfohlener Ablauf:

1. Authentik-Gruppen `LibreDesk Agents` und `LibreDesk Admins` anlegen.
2. Alle Administrator:innen zusätzlich in `LibreDesk Agents` aufnehmen.
3. OAuth2/OpenID-Provider als vertraulichen Client mit Authorization Code,
   UUID-basiertem Subject und den Scopes `openid`, `profile` und `email`
   erstellen.
4. Anwendung ausschließlich an `LibreDesk Agents` binden und diese Gruppe an
   der vorhandenen MFA-Stufe von `zircula-authentication` verpflichten.
5. In LibreDesk unter **Administration → General** die Root URL ohne
   abschließenden Slash auf `https://support.zircula.org` setzen.
6. Unter **Administration → Security → SSO** einen generischen Provider mit
   `https://auth.zircula.org/application/o/libre-desk/` anlegen. Authentik hat
   aus dem Anwendungsnamen den Slug `libre-desk` erzeugt.
7. Die von LibreDesk erzeugte Callback-URL
   `https://support.zircula.org/api/v1/oidc/1/finish` in Authentik ausschließlich
   als strikte Authorization-Redirect-URI hinterlegen; temporäre localhost-URIs
   entfernen.
8. berechtigten Login mit MFA, unveränderte lokale Rolle und den lokalen
   Break-Glass-Login jeweils in frischer privater Sitzung testen.

OIDC ersetzt weder LibreDesk-Rolle noch Teamzuordnung. `LibreDesk Admins` ist
eine Governance-Gruppe und vergibt keine lokale LibreDesk-Rolle. Offboarding
umfasst daher das Entfernen aus `LibreDesk Agents` und das Deaktivieren des
Agentenkontos in LibreDesk.

## Mailbox

Das dedizierte Postfach ist `itsupport@zircula.org`:

| Richtung | Server | Port | Transport |
|---|---|---:|---|
| Posteingang | `mail.manitu.de` | 993 | IMAP über SSL/TLS |
| Postausgang | `mail.manitu.de` | 465 | SMTP über SSL/TLS |

Die Einrichtung erfolgt unter **Administration → Inboxes**. Das
Mailbox-Passwort wird nicht in die Stack-`.env` übernommen.

Getestet wurden IMAP-Abruf, SMTP-Versand, sichtbarer Absendername und
Antwort-Threading. Ein versehentlich als `mail.manitu.org` eingetragener
SMTP-Host löste reproduzierbar `connection refused` aus; korrekt ist in beiden
Richtungen ausschließlich `mail.manitu.de`.

Regelmäßig sowie nach relevanten Änderungen testen:

1. neue externe E-Mail erzeugt genau ein Ticket,
2. Antwort erreicht nur die anfragende Person,
3. weitere Antwort wird demselben Ticket zugeordnet,
4. CC/BCC, Anhänge und Umlaute funktionieren,
5. Fehlzustellung und Verbindungsausfall sind sichtbar,
6. interne Notiz wird niemals als E-Mail versendet,
7. Absendername, Signatur und Datenschutztext sind korrekt.

## Veröffentlichung

Nach Änderungen an Caddy oder der LibreDesk-Route:

```bash
cd /opt/zircula/git/infrastructure/docker/caddy

docker compose exec caddy \
  caddy validate --config /etc/caddy/Caddyfile

docker compose up -d --force-recreate caddy
docker compose logs --since=2m caddy

curl -fsS https://support.zircula.org/health
```

## Backup, Update und Rollback

Zusammengehörig zu sichern sind der logische Dump der Datenbank `libredesk`,
`/srv/zircula/libredesk/uploads`, die lokale `.env` im verschlüsselten
Secret-Backup und die Image-Version. Redis ist keine primäre
Wiederherstellungsquelle.

Vor jedem Update Release Notes lesen, Datenbank und Uploads sichern und danach
nur diesen Stack aktualisieren:

```bash
bash scripts/preflight.sh
docker compose pull
docker compose up -d
docker compose ps
docker compose logs --tail=100 libredesk
```

Danach Healthcheck, lokaler Login, OIDC, Mailabruf, Versand, Threading, Anhänge
und Berechtigungen testen. Ein bloßes Image-Downgrade nach einer
Datenbankmigration ist kein sicherer Rollback; Datenbankdump, Uploads und Image
werden gemeinsam auf den vorherigen Stand gebracht.
