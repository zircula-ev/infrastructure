# Nextcloud Full Text Search

## Ziel

Die Volltextsuche soll den regulären, für die jeweilige Person zugänglichen
Dateibestand erfassen. Eine dauerhaft nur teilweise indexierte Suche wäre
missverständlich, weil ein fehlender Treffer als nicht vorhandenes Dokument
interpretiert werden könnte.

Der technische Pilot prüft deshalb zunächst Qualität, Ressourcen und
Berechtigungsfilter. Nach erfolgreicher Freigabe wird der vollständige
vorgesehene Bestand indexiert.

## Plattformentscheidung

Verwendet wird Elasticsearch 8 statt der SQL-Plattform.

Die SQL-Plattform 1.3.6 ist mit Nextcloud 34 und PostgreSQL 17 kompatibel,
bezeichnet sich aber weiterhin als Proof of Concept. Sie vergrößert die
produktive Nextcloud-Datenbank durch Klartext und Suchindex, unterstützt
Office-Inhalte noch nicht und verwendet für PostgreSQL derzeit eine fest
angenommene englische Textkonfiguration.

Elasticsearch benötigt einen zusätzlichen Dienst, trennt den regenerierbaren
Index aber von PostgreSQL und unterstützt über die Attachment-Verarbeitung
PDF- und Office-Inhalte. Für den gemeinsamen Vereinsbestand ist diese Trennung
betrieblicher und funktionaler geeigneter.

## Komponenten

- Full text search 34.0.1
- Full text search – Files 34.0.1
- Full text search – Elasticsearch Platform 34.0.1
- Elasticsearch 8.19.19
- internes Netz `zircula_search`
- Datenpfad `/srv/zircula/elasticsearch`

Die App-Versionen werden vor der produktiven Installation erneut mit dem
Nextcloud App Store abgeglichen.

## Datenschutz und Berechtigungen

Der Index enthält extrahierten Dokumenttext und ist daher genauso
schutzbedürftig wie die Originaldateien. Elasticsearch erhält weder eine
öffentliche Route noch einen Hostport. Nur Nextcloud und Elasticsearch werden
mit dem internen Suchnetz verbunden.

Die Freigabe setzt einen positiven und einen negativen Berechtigungstest voraus:

- berechtigte Person findet eindeutigen Inhalt,
- unberechtigte Person findet denselben Inhalt nicht,
- Gruppenentzug entfernt den Treffer,
- erneute Freigabe stellt ihn wieder her.

Der technische Index wird nicht für allgemeine Analyse, Profilbildung oder
eine von Nextcloud unabhängige Suche verwendet.

## Ressourcenmodell

Der gemeinsame VPS besitzt 8 CPU-Kerne und 15 GiB RAM. Elasticsearch erhält:

- 768 MiB festen JVM-Heap,
- 2 GiB hartes Containerlimit,
- maximal 4096 Prozesse beziehungsweise Threads,
- begrenzte Docker-Logdateien.

Machine Learning, Kibana, Watcher und GeoIP-Downloads bleiben deaktiviert. Die
erste Indexierung erfolgt außerhalb der Hauptnutzung unter Beobachtung. Bei
Speicherdruck, Swap, wiederholten Neustarts oder spürbaren Auswirkungen auf
Nextcloud wird sie gestoppt und die Dimensionierung neu bewertet.

## Suchumfang

Im Zielzustand eingeschlossen werden:

- persönliche Dateien,
- direkte Freigaben,
- Team Folders,
- Text- und Markdown-Dateien,
- textbasierte PDFs,
- unterstützte Office-Dateien.

Externe oder föderierte Speicher werden nur bewusst aktiviert. Papierkorb,
Versionen, technische Appdaten, Backups und der Elasticsearch-Index selbst
gehören nicht zum Suchumfang. OCR für reine Bildscans ist eine spätere,
gesondert zu bewertende Erweiterung.

## Phasen

### 1. Infrastruktur

- Datenpfad, Sysctl und internes Netz vorbereiten
- Compose validieren
- Elasticsearch isoliert starten
- Health, Ressourcenlimit, Persistenz und Netztrennung prüfen

### 2. Nextcloud-Integration

- Nextcloud mit dem Suchnetz verbinden
- drei kompatible Apps installieren
- Plattform und Dateiprovider konfigurieren
- OCC-Check und Plattformtest durchführen

### 3. Repräsentativer Pilot

- eindeutige Testbegriffe in mehreren Dateitypen indexieren
- persönliche Dateien, Freigaben und Team Folders prüfen
- mindestens zwei Konten für Berechtigungs- und Entzugstests verwenden
- Indexgröße, RAM, CPU, Dauer und Logs dokumentieren

### 4. Vollständige Indexierung

Nach erfüllten Gates wird der gesamte reguläre Bestand indexiert. Der Lauf
wird vom interaktiven SSH-Terminal entkoppelt, protokolliert und überwacht.
Nutzer:innen erhalten erst danach die Information, dass die Volltextsuche den
produktiven Bestand abdeckt.

### 5. Betriebsübergabe

- Suchfunktion in das Benutzer-Onboarding aufnehmen
- Grenzen wie fehlendes OCR transparent erklären
- Update-, Fehler- und Neuindexierungsverfahren dokumentieren
- Indexwachstum und Vollständigkeit regelmäßig prüfen

## Backup und Wiederherstellung

Elasticsearch ist keine Primärdatenquelle. Sein Datenpfad wird nicht in Restic
aufgenommen, weil der Index aus den gesicherten Nextcloud-Dateien und der
App-Konfiguration neu aufgebaut werden kann. Das reduziert Backupmenge und
verhindert, dass ein inkonsistenter Live-Index als Restore-Grundlage behandelt
wird.

Nach einem Restore werden zuerst Nextcloud, Datenbank, Dateien und
Berechtigungen geprüft. Anschließend wird Elasticsearch leer bereitgestellt und
der Index neu aufgebaut.

## Freigabekriterien

Produktiv freigegeben wird die Funktion erst, wenn:

- alle Plattformtests erfolgreich sind,
- PDF-, Office-, Text- und Markdown-Suche funktionieren,
- Team Folders enthalten sind,
- Berechtigungs- und Gruppenentzugstests bestanden sind,
- Ressourcen und Plattenwachstum vertretbar bleiben,
- Nextcloud, Office, Cron und Client Push unbeeinträchtigt sind,
- Rückbau und Neuaufbau nachvollziehbar dokumentiert sind.
