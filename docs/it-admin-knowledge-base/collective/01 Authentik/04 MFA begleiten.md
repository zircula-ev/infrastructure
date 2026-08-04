# MFA begleiten

MFA bedeutet, dass neben dem Passwort ein zweiter Nachweis erforderlich ist.
Damit reicht ein gestohlenes Passwort allein nicht für die Anmeldung.

## Geeignete Möglichkeiten

- **Passkey:** meist die bequemste Variante auf einem persönlichen Gerät
- **TOTP-App:** zeitbasierter sechsstelliger Code, zum Beispiel mit Ente Auth,
  2FAS, Aegis oder auch Google Authenticator
- **Statische Einmalcodes:** eine vorab erzeugte TAN-Liste für begründete Fälle,
  wenn Smartphone und Sicherheitsschlüssel nicht praktikabel sind

Statische Codes werden nur abgestimmt eingerichtet, sicher übergeben und nach
Benutzung einzeln gestrichen. Sie gehören nicht in Tickets oder ungeschützte
Dokumente.

## Gruppen mit verpflichtender MFA

MFA ist insbesondere für administrative und besonders schützenswerte Gruppen
vorgesehen, darunter die vorhandenen Gruppen für:

- Grafana-Administration
- Nextcloud-Administration
- die Vorstände von Werk und Zircula
- Objekt 218 GmbH
- Vaultwarden-Nutzung

Maßgeblich ist die aktuell in Authentik konfigurierte Gruppenregel.

## Unterstützung bei der Einrichtung

1. Person normal über Authentik anmelden lassen.
2. Einrichtung des zweiten Faktors vollständig abschließen lassen.
3. Ab- und wieder anmelden.
4. Gemeinsam prüfen, dass der zweite Faktor funktioniert.
5. Wenn möglich eine zweite sichere Wiederherstellungsmöglichkeit einrichten.

MFA wird nicht deaktiviert, nur um ein Anmeldeproblem kurzfristig zu umgehen.
Bei Geräteverlust wird der Vorfall an die verantwortliche Administration
eskaliert.
