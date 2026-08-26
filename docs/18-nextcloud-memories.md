# Nextcloud Memories

## Zweck

Memories stellt Bilder und Videos aus der bestehenden Nextcloud-Dateiablage
in einem nach Aufnahmedatum sortierten Zeitstrahl dar. Der erste produktive
Anwendungsfall ist das Medienarchiv für Öffentlichkeitsarbeit und
Vereinsmitglieder.

Memories ersetzt weder die Ordnerstruktur noch die Nextcloud-Berechtigungen.
Benutzer:innen sehen ausschließlich Dateien, auf die sie bereits Zugriff
haben.

## Aktueller Stand

- Nextcloud Memories 8.1.0
- Nextcloud Photos 7.0.0
- Preview Generator 5.14.0
- Pilotpfad: `WERK-Haus Allgemein/Medienarchiv/Zircula`
- Recognize ist aus Ressourcen- und Datenschutzgründen nicht installiert.
- Gesichtserkennung ist nicht aktiviert.
- Video-Transcoding ist nicht eingerichtet.

Das vollständige Arbeitsarchiv bleibt in den dafür vorgesehenen
Team-Ordnern. Für Mitglieder werden nur entsprechend freigegebene Bereiche
oder kuratierte Alben verwendet.

## Bildvorschauen

Nextcloud 34.0.3 registrierte auf dieser Installation ohne explizite
Konfiguration keine normalen Bild-Preview-Provider. Dadurch zeigte Memories
graue Platzhalter, obwohl die Originaldateien lesbar waren.

`docker/nextcloud/config/previews.config.php` aktiviert deshalb ausdrücklich
nur konservative Rasterbild-Provider:

- JPEG
- PNG
- GIF
- BMP
- XBitmap
- WebP

PDF-, Office- und weitere Provider werden dadurch nicht zusätzlich
freigeschaltet. HEIC und HEIF werden wegen der bekannten Einschränkungen der
ImageMagick-Provider in Nextcloud 34 vorerst nicht ausdrücklich aktiviert.

## Preview Generator

Die produktive Konfiguration wird in der Nextcloud-App-Konfiguration
gespeichert:

```bash
php occ config:app:set previewgenerator squareSizes \
  --value='64 256'

php occ config:app:set previewgenerator fillWidthHeightSizes \
  --value='256 1024'

php occ config:app:set previewgenerator coverWidthHeightSizes \
  --value='256'

php occ config:app:set previewgenerator widthSizes \
  --value=''

php occ config:app:set previewgenerator heightSizes \
  --value=''

php occ config:app:set previewgenerator job_max_execution_time \
  --type=integer \
  --value=300

php occ config:app:set previewgenerator job_max_previews \
  --type=integer \
  --value=0
```

Der bestehende Nextcloud-Cron verarbeitet neue Preview-Einträge. Ein
zusätzlicher System-Cronjob für `preview:pre-generate` ist derzeit nicht
notwendig.

Statuskontrolle:

```bash
php occ preview:queue-stats
```

## Memories-Index

Neue Dateien werden über die Nextcloud-Hintergrundjobs erfasst. Ein
begrenzter manueller Index kann für einen einzelnen Pfad gestartet werden:

```bash
php occ memories:index \
  --user=timohecken \
  --path='WERK-Haus Allgemein/Medienarchiv/Zircula'
```

Es soll nicht ungeprüft die gesamte Nextcloud-Dateiablage indexiert oder mit
Vorschauen vorgeneriert werden.

## Verifikation

Nach Änderungen sind mindestens folgende Prüfungen erforderlich:

```bash
php occ status
php occ preview:queue-stats
php occ config:system:get enabledPreviewProviders
```

Zusätzlich werden der Memories-Zeitstrahl, einige JPEG-/PNG-Dateien,
Aufnahmedaten, Drehung, Unterordner und ein Album in der Weboberfläche
geprüft.
