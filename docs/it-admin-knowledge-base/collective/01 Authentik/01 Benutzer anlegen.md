# Benutzer:in anlegen

## Vorher klären

Du brauchst:

- vollständigen Namen
- Vereins- oder Organisationszugehörigkeit
- gültige E-Mail-Adresse
- die ausdrücklich benötigten Gruppen
- einen dauerhaften Benutzernamen

## Vorgehen

1. Authentik öffnen und mit dem persönlichen Administrationskonto anmelden.
2. **Verzeichnis → Benutzer** öffnen.
3. Den Pfad **zircula** auswählen.
4. **Benutzer erstellen** wählen.
5. Benutzernamen, Namen und E-Mail-Adresse eintragen.
6. Das Konto als aktiv markieren, wenn die Person sich jetzt anmelden darf.
7. Die Attribute als ein gemeinsames Dictionary eintragen.
8. Benutzer speichern.
9. Erst danach die abgestimmten Gruppen zuweisen.

Beispiel:

```yaml
email_verified: true
nextcloud_user_id: vornameNachname
```

## Benutzernamen und Nextcloud-ID

Beide Werte sollen kurz, lesbar und dauerhaft sein: Kleinbuchstaben, keine
Leerzeichen und möglichst keine Umlaute oder Sonderzeichen. Bestehende
Namenskonventionen werden fortgeführt.

`nextcloud_user_id` darf nach der ersten Nextcloud-Anmeldung nicht mehr
geändert werden. Ein später geänderter Anzeigename oder eine neue E-Mail-Adresse
ändert diese technische Identität nicht.

## Häufiger Eingabefehler

Das Attributfeld erwartet genau ein YAML- oder JSON-Dictionary. Schlüssel dürfen
nicht doppelt vorkommen. Nicht mehrfach `attributes:` eintragen.
