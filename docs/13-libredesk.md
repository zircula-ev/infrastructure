# 13 – LibreDesk IT-Support

## Zweck und Abgrenzung

LibreDesk wird als möglicher Nachfolger des Slack-Kanals `#it-support` erprobt.
Es ist ein Ticket- und Kommunikationssystem für konkrete Supportanfragen, kein
allgemeiner Chat, Aufgabenplaner oder Dateiarchiv.

- Supportanfragen gehen per E-Mail an `itsupport@zircula.org`.
- Antworten und Status werden im Ticket nachvollziehbar.
- dauerhafte Anleitungen und Organisationswissen gehören in Collectives.
- Projektaufgaben gehören in Deck oder die vereinbarte Arbeitsstruktur.
- produktive Dateien und Medien gehören in Nextcloud und werden im Ticket nur
  verlinkt, soweit das sinnvoll ist.
- Slack bleibt bis zur ausdrücklichen organisatorischen Ablösung bestehen.

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
gebunden; für diese Gruppe gilt MFA. Offboarding umfasst Authentik und LibreDesk.

## Datenschutz und Governance

Tickets können Namen, Kontaktdaten, Geräteinformationen, Zugriffsprobleme und
Anhänge enthalten. Deshalb gelten:

- nur notwendige Daten erfragen,
- Passwörter, MFA-Codes und produktive Secrets niemals per Ticket anfordern,
- sensible Anhänge vermeiden und geschützte Nextcloud-Freigaben verwenden,
- interne Notizen klar von ausgehenden Antworten unterscheiden,
- Zugriff nur für tatsächlich zuständige Agent:innen,
- Aufbewahrungs- und Löschfrist vor dem Produktivstart beschließen,
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

## PoC-Gates

LibreDesk wird erst zum verbindlichen Supportkanal, wenn:

1. interner und öffentlicher Healthcheck stabil sind,
2. das lokale Break-Glass-Konto getestet ist,
3. OIDC mit berechtigtem Agent und Ablehnung ohne Binding getestet ist,
4. MFA für `LibreDesk Agents` aktiv ist,
5. Mail, Antwort, Threading, Anhänge und Umlaute getestet sind,
6. interne Notizen nicht an externe Empfänger gelangen,
7. Rollen und Teams mit mindestens zwei Testkonten geprüft sind,
8. Offboarding in Authentik und LibreDesk geprüft ist,
9. Datenbankdump, Upload-Backup und Anwendungsschlüssel vollständig sind,
10. ein isolierter Restore einschließlich Login und Testanhang funktioniert,
11. Datenschutz, Aufbewahrung und Verantwortlichkeit beschlossen sind,
12. eine vereinbarte Beobachtungsphase parallel zu Slack bestanden ist.

## Migration von Slack

Der bisherige Slack-Kanal wird nicht pauschal importiert. Relevante Lösungen
werden redaktionell in Collectives überführt; offene Fälle können manuell als
Tickets angelegt werden. Nach der Freigabe wird Slack zunächst mit einem
angepinnten Übergangshinweis weitergeführt und später archiviert.

## Backup und Rückbau

Ein Sicherungsstand besteht aus logischem PostgreSQL-Dump, Upload-Verzeichnis,
verschlüsseltem Secret-Backup einschließlich Anwendungsschlüssel sowie
Repository-Commit und Image-Version. Redis ist keine primäre
Wiederherstellungsquelle.

Der PoC kann unabhängig zurückgebaut werden: Caddy- und Monitoringroute
entfernen, beide LibreDesk-Stacks stoppen, Authentik-Anwendung und DNS entfernen
und Daten nach beschlossener Frist sichern oder datenschutzgerecht löschen.
Containerentfernung allein löscht keine produktiven Daten.
