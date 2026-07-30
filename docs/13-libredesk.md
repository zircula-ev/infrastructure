# 13 – LibreDesk IT-Support

## Zweck und Abgrenzung

LibreDesk ist der produktive, verbindliche Kanal für konkrete interne
IT-Supportanfragen. Es ist ein Ticket- und Kommunikationssystem, kein
allgemeiner Chat, Aufgabenplaner oder Dateiarchiv.

- Supportanfragen gehen per E-Mail an `itsupport@zircula.org`.
- Antworten und Status werden im Ticket nachvollziehbar.
- dauerhafte Anleitungen und Organisationswissen gehören in Collectives.
- Projektaufgaben gehören in Deck oder die vereinbarte Arbeitsstruktur.
- produktive Dateien und Medien gehören in Nextcloud und werden im Ticket nur
  verlinkt, soweit das sinnvoll ist.
- Slack `#it-support` bleibt nur als befristeter Übergangskanal bis zur
  Abschaltung von Slack bestehen; neue Fälle gehören in LibreDesk.

## Technischer Teststand

Am 30.07.2026 wurden auf dem VPS erfolgreich geprüft:

- interner und öffentlicher Healthcheck einschließlich TLS,
- gehärteter Betrieb als UID/GID 1000 ohne Hostport,
- eigener authentifizierter Redis und getrennte PostgreSQL-Datenbank,
- IMAP-Abruf und SMTP-Versand über `mail.manitu.de`,
- Zuordnung einer Antwort zur bestehenden Konversation,
- Agenten- und Teamzuordnung sowie sichtbarer Absendername,
- Authentik-OIDC über den Provider-Slug `libre-desk`,
- Zugriffsbinding an `LibreDesk Agents` und MFA für diese Gruppe,
- unveränderte lokale LibreDesk-Adminrolle nach dem SSO-Login,
- unabhängiger lokaler `System`-Break-Glass-Login.

Die Root URL in **Administration → General** ist
`https://support.zircula.org`. Sie ist maßgeblich für die generierte
OIDC-Callback-URL und weitere absolute Anwendungslinks.

## Nutzererlebnis

Reguläre Nutzer:innen benötigen kein LibreDesk-Konto. Eine E-Mail erzeugt ein
Ticket; Antworten bleiben im selben Thread. Nur bearbeitende Agent:innen
verwenden die Weboberfläche. Dieses Modell bleibt bei einem späteren Wechsel von
Slack zu Nextcloud Talk unverändert.

## Zugriff und Rollen

- `System`: lokales, offline verwahrtes Break-Glass-Konto
- LibreDesk-Administrator:innen: technischer kleinster Personenkreis
- Agent:innen: Bearbeitung zugewiesener Supporttickets
- Kontakte: anfragende Personen ohne Backend-Zugang

Agent:innen werden manuell in LibreDesk mit derselben verifizierten E-Mail wie in
Authentik angelegt. OIDC übernimmt nur Anmeldung, nicht Kontoerstellung, Rolle
oder Teamzuordnung. Die Anwendung wird ausschließlich an `LibreDesk Agents`
gebunden; für diese Gruppe gilt MFA. `LibreDesk Admins` ist eine Teilmenge zur
Governance, vergibt aber keine lokale LibreDesk-Adminrolle. Administrator:innen
müssen Mitglied beider Gruppen sein. Offboarding umfasst Authentik und
LibreDesk.

## Datenschutz und Governance

Tickets können Namen, Kontaktdaten, Geräteinformationen, Zugriffsprobleme und
Anhänge enthalten. Deshalb gelten:

- nur notwendige Daten erfragen,
- Passwörter, MFA-Codes und produktive Secrets niemals per Ticket anfordern,
- sensible Anhänge vermeiden und geschützte Nextcloud-Freigaben verwenden,
- interne Notizen klar von ausgehenden Antworten unterscheiden,
- Zugriff nur für tatsächlich zuständige Agent:innen,
- Aufbewahrungs- und Löschfristen festlegen und regelmäßig prüfen,
- Exporte und Backups wie vertrauliche Vereinsdaten behandeln,
- Aktivitätsprotokolle regelmäßig stichprobenartig prüfen.

## Technischer Aufbau

- `docker/libredesk`: Anwendung als UID/GID 1000
- `docker/libredesk-redis`: ausschließlich anwendungseigener Redis
- zentrale PostgreSQL-Instanz mit getrennter Rolle und Datenbank `libredesk`
- Caddy unter `support.zircula.org`
- Authentik-OIDC für Agent:innen
- Uploads unter `/srv/zircula/libredesk/uploads`
- keine öffentlichen Hostports außer dem vorhandenen Caddy
- Blackbox-Prüfung des öffentlichen `/health`-Endpunkts

## Betrieb und regelmäßige Prüfungen

Der produktive Grundbetrieb ist technisch abgenommen. Wiederkehrend beziehungsweise
nach relevanten Änderungen werden geprüft:

1. interner und öffentlicher Healthcheck,
2. lokaler Break-Glass-Zugang,
3. OIDC, Gruppenbindung und MFA für `LibreDesk Agents`,
4. IMAP, SMTP, Antwort-Threading, Anhänge und Umlaute,
5. Trennung interner Notizen von ausgehenden Antworten,
6. Rollen, Teams und Offboarding,
7. Datenbankdump, Upload-Backup und Anwendungsschlüssel,
8. isolierter Restore einschließlich Login und Testanhang,
9. Aufbewahrungs-, Lösch- und Zugriffsregeln.

Der erfolgreiche Backup-Smoke-Test vom 30.07.2026 prüfte den lesbaren
PostgreSQL-Dump, das lesbare Uploadarchiv und SHA-256-Prüfsummen. Ein isolierter
Vollrestore bleibt eine wichtige Betriebsprüfung, blockiert aber nicht die
Nutzung des bereits getesteten Dienstes.

## Migration von Slack

Der bisherige Slack-Kanal wird nicht pauschal importiert. Relevante Lösungen
werden redaktionell in Collectives überführt; offene Fälle können manuell als
Tickets angelegt werden. Slack wird nur noch mit einem
angepinnten Übergangshinweis weitergeführt und mit der Abschaltung von Slack
geschlossen. Es ist kein gleichwertiger paralleler Supportkanal.

## Backup und Rückbau

Ein Sicherungsstand besteht aus logischem PostgreSQL-Dump, Upload-Verzeichnis,
verschlüsseltem Secret-Backup einschließlich Anwendungsschlüssel sowie
Repository-Commit und Image-Version. Redis ist keine primäre
Wiederherstellungsquelle.

Der Dienst kann unabhängig wiederhergestellt oder zurückgebaut werden: Caddy- und Monitoringroute
entfernen, beide LibreDesk-Stacks stoppen, Authentik-Anwendung und DNS entfernen
und Daten nach beschlossener Frist sichern oder datenschutzgerecht löschen.
Containerentfernung allein löscht keine produktiven Daten.

## Betriebsnotizen

- Der Authentik-Anwendungsname erzeugte automatisch den Slug `libre-desk`; die
  Discovery-/Issuer-URL lautet daher
  `https://auth.zircula.org/application/o/libre-desk/`.
- LibreDesk erzeugt die OIDC-Callback-URL aus `app.root_url`. Ein verbliebener
  Wert `http://localhost:9000` führt nach erfolgreicher Authentik-Anmeldung zu
  einer Rückleitung auf localhost.
- Für IMAP und SMTP ist `mail.manitu.de` einzutragen. Die ähnlich aussehende,
  aber falsche Domain `mail.manitu.org` löst beim Versand einen Verbindungsfehler
  aus.
