# Integrationscheckliste

## Vor der Aktivierung

- Arbeitsbaum des VPS prüfen und keine lokalen Änderungen überschreiben.
- Branding-Branch auf den aktuellen Monitoring- beziehungsweise späteren
  Main-Stand aktualisieren.
- Authentik-Image `2026.5.4` und laufende Container-Version bestätigen.
- persönliche Admin-Sitzung und Authentik-Break-Glass-Zugang bereithalten.
- aktuellen Brand vollständig außerhalb von Git exportieren und Modus 600 setzen.
- vorhandene Brand-Attribute, Default-Status und Flow-Zuweisungen prüfen.
- VPS-Snapshot vor dem Aktivierungsdeployment erstellen.
- Caddy- und Authentik-Compose-Konfiguration rendern und validieren.

## Anpassung

- Brand über `domain: auth.zircula.org` identifizieren.
- nur ausdrücklich gewünschte Felder in Blueprint-`attrs` aufnehmen.
- vorhandene `attributes` bewusst zusammenführen, nicht blind ersetzen.
- CSS aus `css/authentik-custom.css` unverändert in den Blueprint einbetten.
- CSS-Synchronisationsprüfung erfolgreich ausführen.
- ausschließlich versionierte Assetnamen verwenden.
- Blueprint nur read-only in den Worker mounten.
- Assets nur read-only in Caddy mounten.
- keine neue Domain, keinen Container und keinen öffentlichen Port ergänzen.

## Kontrolliertes Deployment

- Aktivierung als eigenständigen Commit vorbereiten.
- zuerst Asset-URLs über Caddy bereitstellen und direkt prüfen.
- Blueprint-Schema und YAML validieren.
- ausschließlich Caddy sowie Authentik Server/Worker gezielt behandeln.
- keine Monitoring-, Nextcloud-, Datenbank- oder Redis-Container neu erstellen.
- Worker-Logs auf Blueprint-Discovery und erfolgreiche Anwendung prüfen.
- aktuelle Brand-API auf Titel, Logo, Favicon und nicht leeres CSS prüfen.
- Funktionstests in einem privaten Browserfenster durchführen.

## Funktionstests

- Login, Logout, erneute Anmeldung und falsches Passwort
- Recovery, Safe Mode, Passwortänderung und Einladung
- MFA-Auswahl, WebAuthn und TOTP
- User Library mit null, einer, vier und vielen Anwendungen
- Nextcloud- und Grafana-OIDC
- Suche, Einstellungen, Benachrichtigungen und Benutzermenü
- 320 px, 390 px, Tablet und Desktop
- Tastaturfokus, Kontrast und reduzierte Bewegung
- Browserkonsole, CSP und Asset-Fehler
- Adminoberfläche bleibt funktional und nahe am Standard

## Rollback

- Blueprint-Reconciliation zuerst durch Entfernen des Worker-Mounts beenden.
- Worker gezielt neu erstellen; keine anderen Stacks anfassen.
- vorherige Brand-Werte aus dem lokalen, geschützten Export wiederherstellen.
- Login, Recovery, MFA und Safe Mode prüfen.
- danach Caddy-Aktivierung revertieren und Caddy gezielt neu erstellen.
- Asset-URLs dürfen erst verschwinden, wenn die Brand sie nicht mehr referenziert.
