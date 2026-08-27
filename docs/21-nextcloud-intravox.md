# 21 – Nextcloud IntraVox

## Ziel

IntraVox dient als interne, leicht zugängliche Start- und Informationsoberfläche
für die tägliche Arbeit. Es ergänzt die vorhandenen Nextcloud-Anwendungen,
ersetzt aber weder Team Folders noch Collectives:

- IntraVox: redaktionell gepflegte, organisationsweite Information und Navigation
- Collectives: gemeinsam bearbeitete Anleitungen und Wissensbestände
- Team Folders: verbindliche Arbeitsdateien und Medien
- Talk: laufende Kommunikation

Die App wurde am 26.08.2026 über die Nextcloud-Oberfläche installiert und am
27.08.2026 ohne Demo-Inhalte für den vorgesehenen internen Nutzerkreis
eingerichtet. Der produktive Stand ist weiter unten dokumentiert.

## Architektur

IntraVox läuft als Nextcloud-App im bestehenden Nextcloud-Container. Seiten
werden als Ordner und JSON-Dateien in einem Team Folder gespeichert und erben
damit Nextcloud-Freigaben, Versionierung und ACLs. Es wird kein zusätzlicher
Docker-Stack, Hostport, Reverse-Proxy-VHost oder eigener Datenbankdienst
eingeführt.

Voraussetzungen:

- kompatible IntraVox-Version für Nextcloud 34
- aktivierte App Team Folders
- mindestens 512 MiB PHP-Arbeitsspeicher für Einrichtung und größere Seiten
- Redis und Nextcloud-Cron wie im bestehenden Betrieb
- konsistente Sicherung von Nextcloud-Daten, App-Verzeichnis und Datenbank

Optionale Erweiterungen wie MetaVox werden im Pilot nicht installiert.

## Sicherheits- und Organisationsentscheidungen

Für den produktiven Betrieb gelten folgende Vorgaben:

1. zunächst genau ein deutscher Inhaltsbaum,
2. keine Demo-Daten im produktiven Bereich,
3. keine öffentlichen Freigabelinks,
4. keine externen Feed-, Video- oder Skriptquellen ohne Einzelprüfung,
5. minimale Redaktionsgruppen statt pauschaler Nextcloud-Adminrechte,
6. Kommentare und Reaktionen werden nur dort eingesetzt, wo redaktionelle
   Betreuung und Aufbewahrung geklärt sind,
7. keine vertraulichen Vorstands-, Personal-, Finanz- oder Mitgliederdaten auf
   allgemein sichtbaren Seiten,
8. bestehende Inhalte werden verlinkt, nicht unkontrolliert dupliziert.

Vorgesehene Rollen:

- **IntraVox Admins**: technische und redaktionelle Gesamtverantwortung
- **IntraVox Editors**: ausgewählte Beschäftigte beziehungsweise
  Öffentlichkeitsarbeit mit Erstellen- und Schreibrechten
- **IntraVox Users**: interne Leseberechtigung

Automatisch angelegte Gruppen und Mitgliedschaften werden vor der Nutzung
geprüft. Nextcloud-Administratoren erhalten nicht allein wegen ihrer technischen
Rolle dauerhaft redaktionelle Verantwortung.

## Diagnose der zunächst fehlerhaften Administrationsseite

Am 26.08.2026 wurde IntraVox 2.5.0 über die App-Oberfläche installiert.
Die App deklariert Nextcloud 32 bis 34 und PHP ab 8.2; Nextcloud 34.0.3 ist
damit formal unterstützt. Der Aufruf von
`/settings/admin/intravox` lieferte dennoch HTTP 500.

Die protokollierte Ursache ist kein Versionskonflikt:

```text
IntraVox folder not found. Please check that you have access to the
IntraVox GroupFolder.
```

Der Fehler entsteht in `PageService::getIntraVoxFolder()`, weil die reine
App-Installation den erwarteten Team Folder beziehungsweise dessen
Initialisierung noch nicht bereitgestellt hat. IntraVox versucht bereits beim
Rendern der Adminseite den Sprach- und Inhaltsstatus aus diesem Ordner zu
lesen. Dass eine noch nicht initialisierte Installation statt eines
Einrichtungsdialogs HTTP 500 liefert, wird als App-Verhalten dokumentiert und
nicht durch eine Änderung an Nextcloud-Core oder App-Dateien umgangen.

Vor dem Setup werden Hilfe und vorhandener Zustand geprüft:

```bash
cd /opt/zircula/git/infrastructure/docker/nextcloud

docker compose exec -T --user www-data nextcloud \
  php occ intravox:setup --help

docker compose exec -T --user www-data nextcloud \
  php occ groupfolders:list

docker compose exec -T --user www-data nextcloud \
  php occ group:list --output=json \
  | jq 'with_entries(
      select(.key | test("IntraVox"; "i"))
    )'
```

Die Prüfung der installierten Version 2.5.0 ergab:

- kein vorhandener Team Folder `IntraVox`,
- keine Gruppen mit `IntraVox` im Namen,
- `intravox:setup` unterstützt ausdrücklich `--skip-demo`,
- `--language` nennt in dieser Version nur `nl` und `en` und bezieht sich
  auf den Demo-Import.

Daher erfolgt die leere Initialisierung ohne Sprachoption:

```bash
cd /opt/zircula/git/infrastructure/docker/nextcloud

docker compose exec -T --user www-data nextcloud \
  php occ intravox:setup \
    --skip-demo \
    --no-interaction \
    -vv
```

Anschließend werden Team Folder, Gruppen, ACLs, App-Status und Logs geprüft,
bevor Mitgliedschaften oder Inhalte angelegt werden. Deutsche Inhalte entstehen
danach kontrolliert über die Oberfläche. Optionen wie `--force-demo`,
Reinstall oder Clean Start sind ausdrücklich nicht Teil dieses
Initialisierungsschritts.

## Preflight nach der GUI-Installation

Die Prüfung ist lesend und verändert keine Inhalte:

```bash
set -Eeuo pipefail

cd /opt/zircula/git/infrastructure/docker/nextcloud

printf '\n=== App-Versionen ===\n'
docker compose exec -T --user www-data nextcloud \
  php occ app:list --output=json \
  | jq '{
      intravox: (
        .enabled.intravox
        // .disabled.intravox
        // "nicht installiert"
      ),
      groupfolders: (
        .enabled.groupfolders
        // .disabled.groupfolders
        // "nicht installiert"
      )
    }'

printf '\n=== IntraVox-Appkonfiguration ===\n'
docker compose exec -T --user www-data nextcloud \
  php occ config:list intravox \
    --private \
    --output=json \
  | jq 'del(
      .. | objects
      | with_entries(
          select(
            (.key | ascii_downcase | test("secret|password|token|key")) | not
          )
        )
    )'

printf '\n=== Verfügbare IntraVox-Kommandos ===\n'
docker compose exec -T --user www-data nextcloud \
  php occ list \
  | grep -E '^  intravox:' \
  || true

printf '\n=== Team Folders ===\n'
docker compose exec -T --user www-data nextcloud \
  php occ groupfolders:list \
  || true

printf '\n=== Relevante Gruppen ===\n'
docker compose exec -T --user www-data nextcloud \
  php occ group:list --output=json \
  | jq 'with_entries(
      select(.key | test("IntraVox"; "i"))
    )'

printf '\n=== PHP-Limit ===\n'
docker compose exec -T nextcloud \
  php -r 'printf("memory_limit=%s\\n", ini_get("memory_limit"));'

printf '\n=== Nextcloud ===\n'
docker compose exec -T --user www-data nextcloud \
  php occ status

curl -fsS https://cloud.zircula.org/status.php
printf '\n'
```

Ausgaben aus `config:list --private` werden auch nach Filterung nicht
ungeprüft veröffentlicht. Im Zweifel werden nur einzelne bekannte Schlüssel
abgefragt.


## Ergebnis der Initialisierung am 26.08.2026

Die Initialisierung mit `intravox:setup --skip-demo` legte erfolgreich an:

- Team Folder `IntraVox` (ID 19),
- die Gruppen `IntraVox Admins`, `IntraVox Editors` und `IntraVox Users`,
- die Standard-Startseite,
- die Ordner `_resources` und `_templates`,
- sieben englische Standardvorlagen.

`--skip-demo` verhindert damit die Demo-Inhalte, nicht jedoch die für den
Betrieb vorgesehenen Start- und Vorlagenstrukturen. Hinweise zu nicht
vorhandenen Sprachordnern `fr` und `nl` waren Warnungen beim Vorlagenimport;
sieben englische Vorlagen wurden erfolgreich installiert.

Die SSH-Verbindung wurde unmittelbar nach der Ausgabe
`Default templates installation completed: 7 installed, 0 skipped`
unterbrochen. Die anschließende Prüfung ergab keinen laufenden Setup-Prozess,
keine neue Fehlermeldung und einen gesunden Nextcloud-Status. Deshalb wird das
Setup nicht vorsorglich erneut ausgeführt.

IntraVox hat bei der Initialisierung alle vorhandenen Nextcloud-Administratoren
automatisch der Gruppe `IntraVox Admins` zugeordnet. Am geprüften Stand waren
dies:

- `timohecken`,
- `nextcloudadmin`,
- `b1ff86a3-c6c2-4163-8558-a5f210a29c20`.

Diese automatische Zuordnung ist vor dem Pilot organisatorisch zu prüfen. Eine
technische Nextcloud-Adminrolle soll nicht ungeprüft redaktionelle
IntraVox-Verantwortung begründen. Dabei ist zusätzlich zu testen, ob IntraVox
entfernte Nextcloud-Administratoren bei App-Aktivierung oder Setup erneut
hinzufügt.


### Deutscher Inhaltsbaum

Am 27.08.2026 wurde der bereits vorhandene, aber leere Sprachordner `de/`
ohne Demoimport initialisiert. Als Formatvorlage diente ausschließlich die von
IntraVox selbst erzeugte englische `home.json`. Angelegt wurden:

- `de/home.json` mit der Pilot-Startseite „Heute bei WERK × ZIRCULA“,
- `de/_resources/`,
- `de/_templates/`.

Der anschließende Lauf von `occ groupfolders:scan 19` erfasste den Team Folder
ohne Fehler. Nextcloud blieb erreichbar, der Wartungsmodus blieb deaktiviert
und es bestand kein Datenbank-Upgradebedarf. Die zunächst aus der älteren Setup-Vorlage abgeleitete `home.json` reichte
allein nicht aus: Ihr fehlte die von IntraVox 2.5.0 zur Seitenerkennung
verwendete `uniqueId`. Zusätzlich erwartete die App `navigation.json` und
`footer.json`. Diese drei Bestandteile wurden anschließend exakt nach den
Schemaerzeugern `getCleanStartHomeContent()`,
`getCleanStartNavigationContent()` und `getCleanStartFooterContent()` der
installierten Version 2.5.0 ergänzt. Nach erneutem Team-Folder-Scan zeigte
IntraVox die deutsche Startseite, Navigation und den unterstützten Editor
korrekt an. Es wurden weiterhin keine Demo-Inhalte importiert.

## Produktivstand am 27.08.2026

IntraVox ist ohne Demo-Import für den vorgesehenen internen Nutzerkreis
freigegeben. Der produktive Stand umfasst:

- die deutsche Startseite „Heute bei WERK × ZIRCULA“,
- eine Linksammlung zu häufig genutzten Bereichen der Cloud,
- Kalenderwidgets für Termine sowie Ausleihen und Buchungen,
- das vorhandene WERK-×-ZIRCULA-Branding über unterstützte App- und
  Nextcloud-Oberflächen,
- die Rollen `IntraVox Admins`, `IntraVox Editors` und `IntraVox Users`.

Die Gruppenzuordnung erfolgt über gleichnamige Gruppen in Authentik und
Nextcloud. Konten ohne IntraVox-Gruppe sehen die unkonfigurierte
Einrichtungsansicht und erhalten damit keinen Inhaltszugriff. Die vorgesehenen
Nutzerkonten wurden den passenden Gruppen zugeordnet. Timo und Jonas bleiben
für den aktuellen Betrieb in `IntraVox Admins`.

Geprüft wurden die Administrationsseite, die Inhaltsansicht, Navigation,
Kalender- und Linkwidgets sowie die Darstellung auf Desktop und Smartphone.
Eine zunächst schwarze mobile Ansicht war clientseitig zwischengespeichert und
nach dem Löschen der Websitedaten behoben. Ein versuchsweise auf „alle Bilder“
gestelltes Fotowidget erzeugte erwartbar viele Dateizugriffe und
Protokollmeldungen; das Widget wurde wieder entfernt. Es wurden keine
Nextcloud-Core- oder IntraVox-Appdateien verändert.

## Betriebsprüfungen

Für den laufenden Betrieb gelten weiterhin:

1. Gruppen und Rollen bei Onboarding und Offboarding konsistent halten,
2. keine öffentlichen IntraVox-Freigaben ohne Einzelprüfung,
3. vertrauliche Vorstands-, Personal-, Finanz- und Mitgliederdaten nicht auf
   allgemein sichtbaren Seiten ablegen,
4. neue externe Feed-, Video- oder Skriptquellen vor Freigabe prüfen,
5. App-Kompatibilität und Changelog vor IntraVox-Updates prüfen,
6. Darstellung auf Desktop und Smartphone nach größeren Änderungen testen,
7. den IntraVox-Team-Folder, App-Konfiguration und Datenbank gemeinsam sichern,
8. die Wiederherstellung einer Testseite im regulären Restore-Test
   nachvollziehen,
9. Cron, Client Push, Volltextsuche, Memories, Office und bestehende
   Nextcloud-Funktionen auf Auffälligkeiten beobachten.

## Betrieb und Backup

IntraVox-Inhalte liegen innerhalb der bestehenden Nextcloud-Datenhaltung. Das
reguläre Backup erfasst damit Team-Folder-Dateien, App-Konfiguration und
PostgreSQL-Daten gemeinsam. Vor App-Updates werden dennoch App-Version,
Kompatibilität, Changelog und mögliche Inhaltsmigrationen geprüft.

Direkte Änderungen unter `custom_apps/intravox` sind nicht zulässig. Gestaltung
und Konfiguration erfolgen ausschließlich über unterstützte App-, Theme- und
Nextcloud-Schnittstellen.

## Rückbau

Ein Rückbau beginnt mit dem Deaktivieren der App. Inhaltsordner, Gruppen und
Datenbankeinträge werden dabei nicht vorschnell gelöscht. Erst nach Export,
Backup und erfolgreicher Prüfung der weiter benötigten Dateien werden
automatisch angelegte Strukturen einzeln bewertet.

```bash
cd /opt/zircula/git/infrastructure/docker/nextcloud

docker compose exec -T --user www-data nextcloud \
  php occ app:disable intravox
```

Eine Deinstallation oder das Löschen des IntraVox-Team-Folders ist kein
Diagnoseschritt und benötigt ein eigenes bestätigtes Rückbauverfahren.
