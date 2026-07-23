# WERK × ZIRCULA – Authentik-Branding

Dieses Verzeichnis enthält das versionierte Branding für Authentik. Die Dateien
allein verändern die laufende Instanz nicht; Laufzeitwirkung entsteht erst durch
den dokumentierten Caddy- und Authentik-Deployment-Schritt.

## Stand und Ziel

- Zielinstanz: `https://auth.zircula.org`
- geprüfte Image-Version: `ghcr.io/goauthentik/server:2026.5.4`
- Gestaltung für Login- und Enrollment-Flows sowie die User Library
- Adminoberfläche möglichst nah am Authentik-Standard
- Bezeichnung: „Zentrale Anmeldung“
- keine zusätzlichen Webfonts, bis deren Lizenz für Webfont-Self-Hosting geklärt ist

## Inhalt

- `assets/werk-x-zircula.v1.png` – versioniertes Wort-/Bildlogo
- `assets/favicon.v1.svg` – eigenständiges quadratisches Favicon
- `css/tokens.css` – zentrale Design-Tokens
- `css/authentik-custom.css` – aktive, versionierte Quelle für `branding_custom_css`
- `preview/index.html` – lokale Login-Vorschau
- `preview/dashboard.html` – lokale User-Library-Vorschau
- `docs/` – Quellen, technische Grenzen, Rollout- und Rollback-Prüfung

Die Vorschauen simulieren das Design und sind keine exakte Kopie des
Authentik-DOM. Sie dürfen lokal geöffnet werden und haben keine Laufzeitwirkung.

## Bereitstellung

Die Assets sollen ohne zusätzlichen Container und ohne neuen öffentlichen Port
über den vorhandenen Caddy bereitgestellt werden:

```text
https://auth.zircula.org/branding/werk-x-zircula.v1.png
https://auth.zircula.org/branding/favicon.v1.svg
```

Die versionierte Aktivierung mountet die Assets read-only in Caddy, liefert nur
`/branding/*` statisch aus und mountet den file-basierten Blueprint read-only in
den Authentik-Worker. Das CSS ist in `branding_custom_css` eingebettet;
`scripts/check-css-sync.sh` prüft deterministisch, dass Quelle und Blueprint
übereinstimmen.

Der Blueprint identifiziert die vorhandene Brand über
`domain: auth.zircula.org` und verwendet `state: present`. Er darf vorhandene
Flow-Zuweisungen, Zertifikate, die Default Application oder andere nicht
ausdrücklich freigegebene Felder nicht verwalten.

## Sicherheitsgrenzen

Vor der Aktivierung werden die aktuellen Brand-Werte lokal auf dem VPS exportiert.
Der Export enthält insbesondere Flow-Zuweisungen und Attribute, bleibt außerhalb
von Git und erhält Modus 600. Produktive Secrets oder `.env`-Dateien gehören
nicht in dieses Verzeichnis.

Die Aktivierung erfolgt erst nach:

- Prüfung von `docker compose config --quiet`
- Validierung des Blueprints gegen Authentik 2026.5.4
- vorbereitetem Revert des Aktivierungscommits
- verfügbarer persönlicher Admin- und Break-Glass-Sitzung
- erfolgreichem Test der statischen Asset-URLs

## Tests nach Aktivierung

- Login, Logout und fehlgeschlagener Login
- Recovery und Safe Mode
- Enrollment und Passwortänderung
- MFA mit WebAuthn und TOTP
- User Library und Application Dashboard
- leere, kleine und größere Anwendungsauswahl
- 320 px, 390 px, Tablet und Desktop
- Tastaturnavigation, Fokus, Kontrast und reduzierte Bewegung
- Browserkonsole, CSP und fehlende Assets
- Nextcloud- und Grafana-OIDC

## Abnahme vom 23.07.2026

Das Branding wurde auf Authentik 2026.5.4 produktionsnah abgenommen:

- Anmeldung am persönlichen Authentik-Konto einschließlich WebAuthn/MFA
- Nextcloud-Anmeldung über Authentik
- Grafana-Anmeldung über Authentik einschließlich Rollenabbildung
- Darstellung bei schmalem Viewport
- getrennte lokale Break-Glass-Zugänge

Die Brand erzwingt das helle Farbschema, verwendet Deutsch als bevorzugte
Oberflächensprache und behält den nativen zweistufigen Authentik-Login bei.
Authentifizierungs-, MFA- und OIDC-Flows wurden für das Branding nicht verändert.

Die HTML-Dateien unter `preview/` bleiben Designreferenzen. Authentik kapselt
Teile der Formularfelder in nicht exportiertem Shadow DOM; deshalb bleiben die
nativen Eingabefelder erhalten. Das produktive CSS nähert Layout, Farben,
Abstände, Logo und Karte der Referenz an, ohne fragile Eingriffe in die
Anmeldelogik.

## Rollback

Das Entfernen der Blueprint-Datei setzt die veränderte Brand nicht zurück.
Deshalb wird zuerst die Blueprint-Reconciliation beendet, anschließend der
vorherige lokale Brand-Export wiederhergestellt und erst danach die statische
Caddy-Route entfernt. Der genaue, getestete Ablauf wird im Aktivierungscommit
dokumentiert.
