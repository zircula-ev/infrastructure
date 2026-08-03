# Nutzer:innen-Onboarding

Dieses Verzeichnis enthält die versionierte Ausgangsfassung des allgemeinen
WERK-×-ZIRCULA-Onboardings. Die Inhalte richten sich an Menschen, die die
gemeinsamen Dienste im Alltag verwenden. Technische Betriebsdetails bleiben in
den übrigen Dokumenten unter `docs/`.

## Verzeichnisstruktur

`collective/` ist direkt für den Import in Nextcloud Collectives vorbereitet:

- Markdown-Dateien auf der obersten Ebene werden zu Hauptseiten.
- Unterverzeichnisse werden zu Elternseiten.
- Die jeweilige `README.md` liefert den Inhalt der Elternseite.
- weitere Markdown-Dateien im Unterverzeichnis werden zu Unterseiten.
- numerische Präfixe halten Kapitel und Seiten in einer stabilen Reihenfolge.

Die Struktur entspricht der Importlogik von Collectives 4.x. Interne Links und
relative Anhänge werden beim Import durch Collectives angepasst.

## Inhaltliche Grundsätze

- kurze, verständliche Sprache statt technischer Betriebsdetails
- konkrete Alltagsschritte statt vollständiger Produktdokumentation
- keine Passwörter, MFA-Codes, App-Passwörter oder personenbezogenen Daten
- verbindliche Trennung von Kommunikation, Wissen, Aufgaben und Dateien
- Screenshots nur sparsam verwenden, weil Oberflächen sich mit Updates ändern
- noch nicht eingeführte Dienste ausschließlich im Ausblick nennen

Git ist die gepflegte Ausgangsversion. Das veröffentlichte Collective ist die
Lesefassung. Inhaltliche Änderungen werden zuerst hier geprüft und anschließend
kontrolliert veröffentlicht.

## Testimport

Vor der Veröffentlichung wird in ein leeres Test-Collective importiert. Die
Importquelle muss im Nextcloud-Container lesbar sein.

```bash
cd /opt/zircula/git/infrastructure/docker/nextcloud

docker compose exec nextcloud \
  mkdir -p /tmp/zircula-onboarding

docker compose cp \
  ../../docs/onboarding/collective/. \
  nextcloud:/tmp/zircula-onboarding/

docker compose exec -T --user www-data nextcloud \
  php occ collectives:import:markdown \
    --collective-id='<COLLECTIVE-ID>' \
    --user-id='<USER-ID>' \
    --parent-id=0 \
    --no-interaction \
    /tmp/zircula-onboarding
```

Anschließend werden Hierarchie, Seitentitel, Links, Mobilansicht und
Berechtigungen geprüft. Der produktive Import erfolgt erst aus einem in `main`
gemergten Stand.

## Redaktionell vor Veröffentlichung prüfen

- Ist Nextcloud Mail für die Zielgruppe freigeschaltet und gewünscht?
- Welche Personen müssen ArbeitszeitCheck verbindlich nutzen?
- Werden Stempeluhr, manuelle Einträge, Abwesenheiten und Monatsabschluss
  tatsächlich eingesetzt?
- Wer ist für Freigaben und nachträgliche Korrekturen zuständig?
- Sind alle Organisationskalender für die richtigen Teams freigegeben?
- Sind die Standardlimits nach der Kalendereinrichtung wiederhergestellt?
- Ist Slack weiterhin Übergangskanal oder bereits abgeschaltet?
- Stimmen Supportadresse und öffentliche Dienstadressen?
