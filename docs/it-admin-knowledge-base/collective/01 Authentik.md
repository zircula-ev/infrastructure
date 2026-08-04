# Authentik

Authentik ist unsere zentrale Anmeldung und die maßgebliche Stelle für normale
Benutzerkonten, Gruppenzugehörigkeiten, Passwörter und MFA.

Ein Konto wird deshalb grundsätzlich zuerst in Authentik angelegt. Nextcloud
erstellt das zugehörige Konto bei der ersten erfolgreichen Anmeldung
automatisch.

## Typische Aufgaben

- Benutzer:in anlegen und aktivieren
- freigegebene Organisationsgruppen zuweisen
- Einladungs- oder Recovery-Mail auslösen
- bei der ersten Anmeldung und MFA-Einrichtung unterstützen
- ein Konto bei einem Austritt deaktivieren

## Wichtige Grenze

Gruppen bestimmen Zugriffe auf Anwendungen und Inhalte. Eine falsche
Gruppenzuweisung kann daher mehr Daten freigeben als beabsichtigt. Insbesondere
administrative Gruppen werden nie nur „zum Testen“ vergeben.

Änderungen an Flows, Stages, Providern, Anwendungen, Brands, Sources und
Property Mappings gehören nicht zur normalen Benutzerverwaltung.
