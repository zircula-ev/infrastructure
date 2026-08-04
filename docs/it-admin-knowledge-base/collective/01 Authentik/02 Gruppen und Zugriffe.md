# Gruppen und Zugriffe

Gruppen bilden Rollen und Zugehörigkeiten ab. Sie steuern unter anderem den
Zugriff auf Nextcloud-Teamordner und weitere Anwendungen.

## Vorgehen

1. Benutzerkonto in Authentik öffnen.
2. Den Bereich für Gruppenmitgliedschaften aufrufen.
3. Nur die im Onboarding abgestimmten Gruppen hinzufügen.
4. Namen sorgfältig prüfen und speichern.
5. Nach der ersten Anmeldung den tatsächlichen Zugriff stichprobenartig prüfen.

Verwende immer die vorhandenen vollständigen Gruppennamen in der Oberfläche,
beispielsweise die Gruppen für:

- Zircula e.V. Mitglieder:innen, Angestellte oder Vorstand
- Werk e.V. Mitglieder:innen oder Vorstand
- Objekt 218 GmbH

Durch die bestehende Gruppenstruktur können übergeordnete Mitgliedschaften
weitere wirksame Zugehörigkeiten mitbringen. Deshalb werden nicht zusätzlich
vorsorglich ähnliche Gruppen angeklickt.

## Besonders geschützte Gruppen

Administrative oder besonders weitreichende Gruppen werden nur mit eindeutiger
Freigabe vergeben. Dazu gehören insbesondere Gruppen für:

- Authentik-Administration
- Nextcloud-Administration
- Grafana-Administration
- Vaultwarden
- Vorstände und Objekt 218 GmbH

Normale Nextcloud-Zugriffe werden nicht direkt in Nextcloud nachgebaut, wenn sie
durch Authentik-Gruppen vorgesehen sind.
