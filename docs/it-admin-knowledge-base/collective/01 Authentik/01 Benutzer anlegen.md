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
2. Auf dem Dashboard unter **Schnellaktionen** die Aktion
   **Benutzer verwalten** öffnen.
3. **Neu** beziehungsweise **Benutzer hinzufügen** wählen.
4. Benutzernamen, Namen und E-Mail-Adresse eintragen.
5. Den vorgeschlagenen Standard im Feld **Pfad** beibehalten, sofern keine
   abgestimmte organisatorische Abweichung benötigt wird.
6. Das Konto als aktiv markieren, wenn die Person sich jetzt anmelden darf.
7. Die Attribute als ein gemeinsames Dictionary eintragen.
8. Benutzer speichern.
9. Erst danach die abgestimmten Gruppen zuweisen.

Alternativ führt auch **Verzeichnis → Benutzer** zur gleichen Benutzerverwaltung.

Beispiel:

```yaml
email_verified: true
nextcloud_user_id: vornameNachname
```

## Der Pfad

Der Pfad sortiert Benutzerkonten innerhalb von Authentik. Er erteilt keine
Berechtigungen und muss für normale Konten nicht zwingend auf `zircula`
geändert werden. Zugriffe entstehen durch die ausdrücklich zugewiesenen Gruppen.

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
