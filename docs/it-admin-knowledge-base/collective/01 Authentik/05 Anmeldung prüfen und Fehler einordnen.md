# Anmeldung prüfen und Fehler einordnen

## Nach einem neuen Konto prüfen

- Die Person kann sich bei Authentik anmelden.
- Bei vorgeschriebener MFA erscheint die Einrichtung oder Abfrage.
- Nextcloud öffnet sich über **Mit Authentik anmelden**.
- Anzeigename und E-Mail-Adresse stimmen.
- Nur die vorgesehenen Bereiche und Teamordner sind sichtbar.
- Weitere freigegebene Anwendungen lassen sich öffnen.

## Typische Ursachen

**Nextcloud-Konto fehlt:**  
Das ist vor der ersten erfolgreichen Authentik-Anmeldung normal.

**Falsche oder fehlende Ordner:**  
Zuerst Gruppenzugehörigkeiten in Authentik prüfen. Nicht parallel direkte
Nextcloud-Gruppen vergeben.

**Zweites vermeintliches Konto:**  
Nicht weiterprobieren. `nextcloud_user_id`, Benutzername und bisherigen
Anmeldeweg prüfen und eskalieren.

**Recovery-Mail fehlt:**  
E-Mail-Adresse, Spam-Ordner und Versandzeit prüfen. Keine Zugangsdaten manuell
verschicken.

**MFA-Gerät verloren:**  
Identität der Person über einen abgestimmten Weg prüfen und den Fall
eskalieren. MFA nicht ungeprüft entfernen.

## Dokumentation

Im zugehörigen LibreDesk-Ticket nur Ergebnis und notwendige organisatorische
Informationen festhalten. Keine Passwörter, Tokens, Recovery-URLs oder
TAN-Listen dokumentieren.
