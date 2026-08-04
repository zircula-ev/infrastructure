# 🔑 MFA und Passkeys

**MFA** bedeutet Mehr-Faktor-Authentifizierung. Neben deinem Passwort wird ein
zweiter Nachweis verlangt. Ein gestohlenes oder erratenes Passwort reicht dann
allein nicht für eine Anmeldung.

Für besonders schützenswerte Rollen ist MFA verpflichtend. Für andere Konten
kann sie freiwillig angeboten werden. Wenn MFA für deine Rolle erforderlich
ist und noch kein Faktor eingerichtet wurde, führt authentik dich bei der
Anmeldung durch die Einrichtung.

## Welche Möglichkeiten gibt es?

### Passkey

Ein Passkey nutzt die sichere Anmeldung deines Geräts, zum Beispiel Touch ID,
Face ID, Windows Hello oder einen FIDO2-Sicherheitsschlüssel. Du bestätigst die
Anmeldung am Gerät und musst keinen zusätzlichen Zahlencode abtippen.

Ein Passkey ist für viele Menschen die bequemste Methode. Richte nach
Möglichkeit einen zweiten zulässigen Faktor oder Wiederherstellungsweg ein,
damit ein verlorenes oder defektes Gerät dich nicht aussperrt.

### Authenticator-App (TOTP)

Eine Authenticator-App erzeugt ungefähr alle 30 Sekunden einen neuen
sechsstelligen Code. Das funktioniert auch ohne Mobilfunk und normalerweise
ohne Internetverbindung. **TOTP** ist der technische Name dieses Verfahrens.

Geeignete Apps sind zum Beispiel:

- [Ente Auth](https://ente.com/auth/) für iPhone, Android, Computer und Web –
  Open Source, auf Wunsch mit Ende-zu-Ende-verschlüsselter Synchronisation,
- [2FAS Auth](https://2fas.com/download/) für iPhone und Android – Open Source
  und ohne verpflichtendes Benutzerkonto nutzbar,
- [Aegis Authenticator](https://getaegis.app/) für Android – Open Source mit
  lokal verschlüsseltem Speicher und Sicherungsmöglichkeit,
- [Google Authenticator](https://support.google.com/accounts/answer/1066447)
  für iPhone und Android – ebenfalls kompatibel, aber nicht Open Source.

Auch andere Apps funktionieren, wenn sie den verbreiteten TOTP-Standard
unterstützen. Du musst für authentik keine bestimmte Hersteller-App verwenden.

### Statische Einmalcodes (TAN-Liste)

Wenn ein Passkey oder eine Authenticator-App für dich nicht praktikabel ist,
kann der IT-Support eine Liste statischer Einmalcodes einrichten. Jeder Code
kann genau einmal verwendet werden und wird danach gestrichen.

Bewahre diese Liste wie ein Passwort sicher und getrennt vom Arbeitsgerät auf.
Fotografiere sie nicht und speichere sie nicht ungeschützt in Nextcloud, E-Mail
oder Chat. Ist die Liste verloren, verbraucht oder möglicherweise kopiert
worden, melde dich beim IT-Support.

## Authenticator-App einrichten

1. Installiere vor der Einrichtung eine geeignete Authenticator-App.
2. Wähle in authentik die Einrichtung eines **TOTP-Authentikators**.
3. Scanne den angezeigten QR-Code mit der Authenticator-App.
4. Trage den aktuell erzeugten sechsstelligen Code in authentik ein.
5. Vergib einen verständlichen Namen wie „Diensthandy“, falls du danach gefragt
   wirst.
6. Schließe die Einrichtung ab und teste die Anmeldung einmal in einem privaten
   Browserfenster.

Der QR-Code enthält das Geheimnis, aus dem alle späteren Codes entstehen. Teile
ihn nicht, verschicke keinen Screenshot und scanne ihn nur mit deiner eigenen
Authenticator-App.

## Passkey einrichten

Wenn authentik dich zur Einrichtung auffordert:

1. Wähle die Einrichtung eines Passkeys oder WebAuthn-Geräts.
2. Folge der Abfrage deines Browsers oder Betriebssystems.
3. Vergib einen verständlichen Gerätenamen, etwa „Dienstlaptop“.
4. Prüfe die Anmeldung einmal in einem neuen privaten Browserfenster.

Nutze kein gemeinsam verwendetes Gerät als einzigen Faktor. Wenn du ein Gerät
wechselst oder den zweiten Faktor verlieren könntest, richte rechtzeitig einen
neuen Faktor ein oder melde dich beim IT-Support.
