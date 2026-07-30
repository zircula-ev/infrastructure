# 12 – Vaultwarden

## Ziel und Grenze

Vaultwarden soll persönliche und organisatorische Zugangsdaten verwalten. Wo ein
Anbieter persönliche Konten, Rollen und MFA anbietet, werden diese weiterhin
bevorzugt. Gemeinsame Einträge sind für tatsächlich gemeinsame Konten,
Recovery-Codes, lokale Geräte, technische Servicekonten und vergleichbare Fälle
vorgesehen.

Vaultwarden übernimmt nicht die Identitätsquelle: Benutzer, Passwörter für
Authentik und MFA werden in Authentik verwaltet. Der Master-Schlüssel des Vaults
bleibt jedoch clientseitig; OIDC ersetzt weder Master-Passwort noch Geräteschlüssel.

## Umsetzungsstand

Der technische PoC ist auf dem VPS unter `vault.zircula.org` bereitgestellt,
aber noch nicht für den allgemeinen organisatorischen Einsatz freigegeben.

Erfolgreich geprüft wurden Container-Hardening, persistente SQLite-Daten,
öffentliche TLS-Erreichbarkeit, Authentik-OIDC mit verifizierter E-Mail,
Master-Passwort, regulärer Neustart sowie SMTP-Anmeldung über den technischen
Absender `noreply@nextcloud.zircula.org`. Am 29.07.2026 wurde das
Sicherheitsupdate auf Vaultwarden 1.37.0 erfolgreich ausgerollt. Am 30.07.2026
folgte das Wartungsupdate auf 1.37.1. Für beide Updates lagen vollständige
Vorher-Backups vor; Datenbank, SSO/MFA, Master-Passwort, Vault-Operationen,
Synchronisation, erneute Anmeldung, SMTP und die öffentliche Health-Route wurden
erfolgreich nachgetestet. Temporäre Debug-Konfigurationen wurden entfernt;
erweitertes Logging und SSO-Token-Logging sind deaktiviert.

Der Rollout bleibt Phase zwei nach der Nextcloud-Migration. Bis dahin werden
Organisationen, Collections, Gruppen, zweiter Owner, Clients, Offboarding,
Uptime-Kuma-Monitor sowie ein verschlüsseltes externes Backup mit isoliertem
Restore-Test abgeschlossen.

## Freigabegates

Vor produktiven Geheimnissen müssen alle Punkte erfüllt sein:

- verschlüsseltes externes Backup vorhanden
- vollständiger Restore auf isolierter Testinstanz erfolgreich
- mindestens zwei namentlich verantwortliche Owner dokumentiert
- Authentik-OIDC, Entzug und lokale Notfallwiederherstellung getestet
- MFA-Regel für alle Vaultwarden-Berechtigten beschlossen
- Onboarding, Offboarding und Rotation organisatorisch zugewiesen
- Clients auf Web, Desktop und Mobil getestet
- Datenschutz- und Aufbewahrungsentscheidung protokolliert

Bis dahin bleibt der Dienst Proof of Concept ohne produktive Secrets.

## Organisationen und Collections

Vorgesehene Organisationen:

- `Zircula e.V.`
- `WERK e.V.`
- `Objekt 218 GmbH`
- `Plattformbetrieb`

Collections werden nach Funktion statt nach Personen aufgebaut, beispielsweise
`Vorstand`, `Angestellte`, `Öffentlichkeitsarbeit`, `Buchhaltung`,
`Lokale Geräte` und `Recovery`. Vaultwarden-Gruppen tragen möglichst dieselben
Namen wie die bestehenden Authentik-Gruppen. Die Funktion wird von Vaultwarden
derzeit weiterhin als Beta mit bekannten Einschränkungen gekennzeichnet. Deshalb
sind Gruppen-, Collection-, Entzugs- und Client-Tests ein ausdrückliches PoC-Gate;
bei nicht zuverlässigem Verhalten werden Rechte zunächst direkt pro Mitglied
zugewiesen und die Gruppenfunktion nicht produktiv verwendet.

Authentik-Gruppen werden durch Vaultwardens natives OIDC nicht automatisch in
Vaultwarden-Gruppen oder Collections synchronisiert. Das erste Betriebsmodell ist
deshalb bewusst zweistufig:

1. Benutzer und Authentik-Gruppen zentral anlegen.
2. Organisationsmitgliedschaft, Vaultwarden-Gruppe und Collection-Rechte in
   Vaultwarden bestätigen.

Eine spätere Synchronisation über Directory Connector oder eine eng begrenzte API
ist ein eigenes Projekt mit Test-, Lösch- und Rollbackkonzept. Sie ist keine
Voraussetzung für den PoC.

## Rechteprinzip

- `Owner`: nur die kleinste notwendige, namentlich dokumentierte Gruppe
- `Admin`: Mitglieder- und Collection-Verwaltung, soweit organisatorisch nötig
- `User`: nur benötigte Collections
- `Manager`: nur für klar verantwortete Collection-Pflege
- persönliche Tresore nicht als Ablage für Organisationsgeheimnisse verwenden
- besonders kritische Recovery- und Infrastrukturwerte in getrennte Collections
  mit minimalem Personenkreis legen
- Freigaben regelmäßig prüfen; keine pauschale Vollsicht für technische Admins

Das Entfernen eines Benutzers verhindert künftigen Zugriff, kann aber bereits
gesehene oder exportierte Geheimnisse nicht zurückholen. Beim Offboarding werden
deshalb betroffene gemeinsame Passwörter, Tokens und Recovery-Codes rotiert.

## Authentik und MFA

Authentik-Anwendung:

- Name: `Vaultwarden`
- Slug: `vaultwarden`
- Provider: OAuth2/OpenID Connect, confidential
- Grants: Authorization Code und Refresh Token
- PKCE: aktiv
- Redirect URI, strikt:
  `https://vault.zircula.org/identity/connect/oidc-signin`
- Authority:
  `https://auth.zircula.org/application/o/vaultwarden/`
- Scopes: `openid profile email offline_access`
- Access-Code-Laufzeit: eine Minute
- Access-Token-Laufzeit: mindestens zehn Minuten
- Zugriff: nur gebundene Organisationsgruppen

`SSO_SIGNUPS_MATCH_EMAIL=true` darf nur zusammen mit verifizierten,
organisatorisch kontrollierten E-Mail-Adressen verwendet werden.
`SSO_ALLOW_UNKNOWN_EMAIL_VERIFICATION=false` bleibt zwingend, um unsichere
Kontoverknüpfungen zu verhindern. Da authentik seit Version 2025.10 den Claim
`email_verified` im Standard-Mapping bewusst auf `false` setzt, verwendet nur
der Vaultwarden-Provider ein eigenes Scope-Mapping `Vaultwarden verified email`
mit Scope-Name `email`:

```python
return {
    "email": request.user.email,
    "email_verified": request.user.attributes.get("email_verified", False),
}
```

Das Benutzerattribut `email_verified: true` wird erst nach organisatorischer
Prüfung der Adresse gesetzt. Das Standard-`email`-Mapping wird im
Vaultwarden-Provider durch dieses Mapping ersetzt; andere Anwendungen bleiben
unverändert.

Die bereitgestellte PoC-Konfiguration verwendet aussperrungssicher
`SSO_ONLY=false`.
Damit bleibt ein lokaler Login technisch möglich und Authentik-MFA könnte
umgangen werden. Vor Produktion muss eine der folgenden Varianten beschlossen und
getestet werden:

1. `SSO_ONLY=true` und dokumentierter Authentik-/Host-Rollback als Notfallweg.
2. lokaler Login bleibt möglich, aber Vaultwarden-native MFA wird für sämtliche
   Konten verbindlich erzwungen.

Für einen Passwortmanager wird MFA für alle Benutzer empfohlen. Ohne Smartphone
können WebAuthn-Sicherheitsschlüssel genutzt werden; fehlende Smartphones sind
kein Grund, besonders sensible Vault-Zugänge ohne MFA zu betreiben.

## Break Glass

Die serverweite Vaultwarden-`/admin`-Konsole ist absichtlich deaktiviert. Sie
ist kein Zugriff auf entschlüsselte Vault-Inhalte und kein geeigneter
Break-Glass-Weg.

Der Notfallweg besteht aus:

- zwei getrennten, persönlichen Ownern
- offline verwahrten Recovery-Codes und Hardware-Schlüsseln
- verschlüsseltem, getesteten Backup
- dokumentiertem Authentik- und Caddy-Rollback
- optional einem streng kontrollierten lokalen Vault-Konto, falls
  `SSO_ONLY=false` als Produktionsentscheidung bestehen bleibt

Keine gemeinsame Owner-Anmeldung und kein Root-Passwort im Vault selbst.

## SMTP

SMTP wird nur für Einladungen, Verifikation und Sicherheitsmeldungen verwendet.
Als Übergang nutzt der PoC den bereits vorhandenen technischen Absender
`noreply@nextcloud.zircula.org`; Kennwort und weitere SMTP-Zugangsdaten bleiben
in der lokalen `.env` und werden nie in Git dokumentiert. Vor dem Regelbetrieb
wird nach Möglichkeit ein eigener Vaultwarden-Absender mit getrennten
Zugangsdaten eingerichtet.

## Datenbank und Persistenz

Für die kleine erste Ausbaustufe wird SQLite mit WAL gewählt. Das vermeidet ein
zusätzliches Datenbankkonto und hält Restore und isolierte Tests übersichtlich.
Die Datenbank wird mit der expliziten URL `sqlite:///data/db.sqlite3`
konfiguriert; dadurch führen Neuaufbau und Restore nicht zu einem unbeabsichtigten
Datenbank-Fallback. Der vollständige Zustand liegt unter
`/srv/zircula/vaultwarden/data`.

Der Container läuft als UID/GID 1000. Der Datenpfad wird vor dem Start mit Modus
700 angelegt. Fehlende Pfade werden nicht automatisch durch Compose erzeugt.

## Backup und Restore

Ein konsistentes Backup besteht aus zwei Teilen:

1. Vaultwardens eingebauter Datenbank-Snapshot:
   ```bash
   docker compose exec vaultwarden \
     /vaultwarden backup
   ```
2. verschlüsselte Sicherung des vollständigen Datenpfads einschließlich
   erzeugtem DB-Snapshot, Anhängen, Sends-Verzeichnis (auch wenn deaktiviert),
   RSA-Schlüsseln und Konfiguration.

Live-Dateien `db.sqlite3`, `db.sqlite3-wal` und `db.sqlite3-shm` werden nicht
anstelle des erzeugten Snapshots als Datenbankbackup behandelt. Backups enthalten
hochwertige Secrets, werden nie in Git abgelegt und benötigen restriktive Rechte.

Restore-Test:

1. isoliertes Verzeichnis und isoliertes Docker-Netz verwenden
2. vollständigen Datenpfad entschlüsselt wiederherstellen
3. DB-Snapshot als `db.sqlite3` einsetzen; WAL/SHM nicht übernehmen
4. gleiche getestete Image-Version verwenden
5. ohne öffentliche Route starten
6. Healthcheck, Login, Entsperrung, Einträge, Collections und Anhänge prüfen
7. Testinstanz und Klartext-Arbeitsdaten sicher entfernen
8. Datum, Version und Ergebnis dokumentieren

Ein Manitu-Snapshot ist nur eine kurzfristige zusätzliche Rückfallebene.

## Monitoring

Prometheus prüft öffentlich `https://vault.zircula.org/alive`. Nach Deployment
wird in Uptime Kuma zusätzlich ein HTTPS-Monitor mit demselben Ziel, gültigem TLS,
30–60 Sekunden Timeout und Slack-Benachrichtigung angelegt. Der Test erfolgt mit
einem ungefährlichen, temporär falschen Ziel; der Produktivcontainer wird dafür
nicht gestoppt.

Logs dürfen keine Tokens, Master-Passwörter oder Vault-Inhalte enthalten.
Debug-/SSO-Token-Logging und erweitertes Request-Logging bleiben deaktiviert.

## Sichere Deploymentreihenfolge

1. DNS setzen, aber Caddy-Route noch nicht aktiv schalten.
2. Branch und Konfiguration prüfen; VPS-Snapshot nur ergänzend erstellen.
3. Datenpfad und lokale `.env` anlegen.
4. Authentik-Provider und Bindings erstellen.
5. Vaultwarden intern starten und Rootless-/Health-Prüfung durchführen.
6. Caddy validieren und Vaultwarden veröffentlichen.
7. ersten PoC-Owner über den an die Gruppe `Vaultwarden Users` gebundenen
   Authentik-Provider anlegen; die normale Registrierung bleibt geschlossen.
8. Organisationen erstellen, danach `ORG_CREATION_USERS=none`.
9. Testbenutzer einladen und Rechte-/Entzugsmatrix prüfen.
10. Monitoring aktivieren.
11. Backup und Restore-Test durchführen.
12. Erst nach bestandenem Gate produktive Geheimnisse aufnehmen.

## Rollback

- vor Veröffentlichung: Stack stoppen; keine übrigen Stacks verändern
- Routingfehler: Vaultwarden-Block aus Caddy entfernen und Caddy neu laden
- OIDC-Fehler: lokale PoC-Anmeldung beziehungsweise Authentik-Konfiguration auf
  dokumentierten Stand zurücksetzen
- fehlerhaftes Imageupdate: nicht blind downgraden; vorherigen vollständigen
  Datenstand und zuvor getestete Image-Version restaurieren
- kompromittiertes System: Secrets und gemeinsame Zugangsdaten als kompromittiert
  behandeln und nach sauberer Wiederherstellung rotieren
