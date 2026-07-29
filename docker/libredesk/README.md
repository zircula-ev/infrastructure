# LibreDesk

Dieser Stack stellt zunächst einen isolierten Proof of Concept für das interne
IT-Support-Ticketing bereit. Er ersetzt Slack nicht automatisch und wird erst
nach erfolgreichem Mail-, OIDC-, Backup- und Rechte-Test organisatorisch
freigegeben.

## Architektur

- LibreDesk 2.5.0 unter `support.zircula.org`
- keine veröffentlichten Hostports; Zugriff ausschließlich über Caddy
- getrennte Datenbank und Rolle in der zentralen PostgreSQL-Instanz
- eigener Stack `libredesk-redis`; keine Nutzung des Nextcloud-Redis
- Uploads unter `/srv/zircula/libredesk/uploads`
- Authentik über OIDC nur für zuvor in LibreDesk angelegte Agent:innen
- Anfragen regulärer Nutzer:innen per E-Mail ohne LibreDesk-Konto

LibreDesk ist ein vergleichsweise junges Projekt. Der erste Rollout bleibt daher
ein rückbaubarer PoC. Slack `#it-support` wird nicht abgeschaltet, bevor der
Betrieb über einen vereinbarten Zeitraum stabil war.

## Secrets

Die lokale `.env` enthält den Anwendungsschlüssel sowie die getrennten
PostgreSQL- und Redis-Passwörter. Sie wird niemals committet und erhält Modus
600. Der Anwendungsschlüssel verschlüsselt gespeicherte Integrationsdaten. Sein
Verlust kann gesicherte Mailbox-Zugangsdaten unbrauchbar machen; er gehört in das
verschlüsselte Secret-Backup.

```bash
cp .env.example .env
chmod 600 .env

openssl rand -hex 16
openssl rand -hex 32
openssl rand -hex 32
```

Die Werte werden direkt in `.env` eingetragen und nicht in Chats, Tickets oder
Shell-Befehle kopiert.

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
  ./libredesk --set-system-user-password --config ""
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

1. Authentik-Gruppe `LibreDesk Agents` anlegen und MFA verpflichten.
2. OAuth2/OpenID-Provider als vertraulichen Client mit Authorization Code
   erstellen.
3. Scopes `openid`, `profile` und `email` freigeben.
4. Anwendung ausschließlich an `LibreDesk Agents` binden.
5. In LibreDesk unter **Administration → Security → SSO** einen generischen
   Provider mit `https://auth.zircula.org/application/o/libredesk/` anlegen.
6. die angezeigte Callback-URL in Authentik als strikte Redirect-URI ergänzen.
7. berechtigten Login, lokalen Break-Glass-Login und Ablehnung eines Kontos ohne
   Binding jeweils in frischer privater Sitzung testen.

OIDC ersetzt weder LibreDesk-Rolle noch Teamzuordnung. Offboarding umfasst daher
das Entfernen des Authentik-Bindings und das Deaktivieren des Agentenkontos.

## Mailbox

Das dedizierte Postfach ist `itsupport@zircula.org`:

| Richtung | Server | Port | Transport |
|---|---|---:|---|
| Posteingang | `mail.manitu.de` | 993 | IMAP über SSL/TLS |
| Postausgang | `mail.manitu.de` | 465 | SMTP über SSL/TLS |

Die Einrichtung erfolgt unter **Administration → Inboxes**. Das
Mailbox-Passwort wird nicht in die Stack-`.env` übernommen.

Vor der Freigabe testen:

1. neue externe E-Mail erzeugt genau ein Ticket,
2. Antwort erreicht nur die anfragende Person,
3. weitere Antwort wird demselben Ticket zugeordnet,
4. CC/BCC, Anhänge und Umlaute funktionieren,
5. Fehlzustellung und Verbindungsausfall sind sichtbar,
6. interne Notiz wird niemals als E-Mail versendet,
7. Absendername, Signatur und Datenschutztext sind korrekt.

## Veröffentlichung

Erst nach erfolgreichem internen Test:

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
