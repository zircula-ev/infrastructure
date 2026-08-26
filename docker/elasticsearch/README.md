# Elasticsearch für Nextcloud Full Text Search

Dieser Stack stellt den regenerierbaren, produktiv freigegebenen Suchindex für
die Nextcloud-App **Full text search** bereit. Architektur, vollständige
Erstindexierung sowie Berechtigungs- und Ressourcentests sind in
`docs/19-nextcloud-fulltextsearch.md` dokumentiert.

## Architektur und Grenzen

- Elasticsearch 8.19.19 als einzelner, konkret gepinnter Knoten
- ausschließlich im internen Docker-Netz `zircula_search`
- kein Hostport, keine Caddy-Route und keine öffentliche Oberfläche
- das Suchnetz verbindet nur Nextcloud und Elasticsearch
- 768 MiB JVM-Heap, 3 GiB Containerlimit und maximal 4096 Prozesse beziehungsweise Threads
- persistenter, aber vollständig regenerierbarer Index unter
  `/srv/zircula/elasticsearch`
- kein Kibana, Machine Learning, Watcher oder GeoIP-Downloader
- keine Elasticsearch-Snapshots im regulären Restic-Backup

Die Nextcloud-Suche filtert Ergebnisse anhand der Nextcloud-Berechtigungen.
Der Elasticsearch-Endpunkt selbst kennt diese Benutzerberechtigungen jedoch
nicht. Deshalb darf er nicht im gemeinsamen Backend-Netz oder über einen
Hostport erreichbar sein. Die Sicherheitsfunktion von Elasticsearch bleibt
für diese isolierte Verbindung deaktiviert, weil die Nextcloud-App in jüngeren
Versionen Probleme mit Zugangsdaten hatte. Die Netzisolation ist daher ein
verbindliches Sicherheits-Gate und keine optionale Optimierung.

Der einzelne Knoten verbessert die Suchfunktion, ist aber kein
hochverfügbarer Suchcluster. Ein Ausfall beeinträchtigt die Volltextsuche,
nicht die Originaldateien. Der Index wird bei Bedarf neu aufgebaut.

## Host vorbereiten

Vor dem ersten Start:

```bash
sudo install -d -o 1000 -g root -m 770 \
  /srv/zircula/elasticsearch

printf 'vm.max_map_count=1048576\n' \
  | sudo tee /etc/sysctl.d/90-zircula-elasticsearch.conf

sudo sysctl --system

docker network create \
  --driver bridge \
  --internal \
  zircula_search

cd /opt/zircula/git/infrastructure/docker/elasticsearch

cp .env.example .env
chmod 600 .env

bash scripts/preflight.sh
```

Existierende Pfade, Netze und Sysctl-Einstellungen werden vor einer Änderung
zuerst geprüft. Ein bereits vorhandenes Netz wird nicht blind neu angelegt.

## Stack zunächst isoliert starten

```bash
docker compose pull
docker compose up -d

docker compose ps
docker compose logs --tail=100 elasticsearch

docker inspect --format \
  'status={{.State.Status}} health={{if .State.Health}}{{.State.Health.Status}}{{end}} restart_count={{.RestartCount}} ports={{json .NetworkSettings.Ports}} memory={{.HostConfig.Memory}}' \
  elasticsearch
```

Der Knoten muss `healthy` sein, darf keinen veröffentlichten Port besitzen
und muss ein Speicherlimit von 3221225472 Bytes zeigen. Anschließend wird die
versionierte Einzelknoten-Vorlage idempotent angewendet:

```bash
bash scripts/configure-nextcloud-index.sh
```

Sie setzt für vorhandene und künftig neu erzeugte `nextcloud*`-Indizes null
Replikate. Ohne diese Einstellung bleibt ein gesunder Einzelknoten wegen einer
nicht zuweisbaren Replik absichtlich gelb. Der Hostwert
`vm.max_map_count` muss mindestens 1048576 betragen.

Interner Test ausschließlich aus dem Suchnetz:

```bash
docker run --rm \
  --network zircula_search \
  curlimages/curl:8.16.0 \
  --fail --silent --show-error \
  http://elasticsearch:9200/_cluster/health?pretty
```

Ein Test aus `zircula_backend` muss fehlschlagen. Dieser Negativtest bestätigt
die Netztrennung.

## Nextcloud anbinden

Erst nach erfolgreichem isoliertem Start wird `zircula_search` in
`docker/nextcloud/compose.yaml` ergänzt und ausschließlich der
Nextcloud-Container neu erstellt. Client Push benötigt dieses Netz nicht.

Danach werden in dieser Reihenfolge installiert:

- Full text search 34.0.1
- Full text search – Files 34.0.1
- Full text search – Elasticsearch Platform 34.0.1

Vor der Installation werden die tatsächlich angebotenen Versionen und die
Hilfen der OCC-Kommandos geprüft. Konfigurationswerte werden nicht geraten.

Für die Plattform gelten anschließend:

- Adresse: `http://elasticsearch:9200`
- Indexname: `nextcloud` in Kleinbuchstaben
- Analyzer/Tokenizer: zunächst `standard`
- lokale Dateien: aktiviert
- Team Folders: aktiviert
- PDF- und Office-Inhalt: aktiviert
- App-Schalter werden bei Version 34.0.1 als Ganzzahlen `0` und `1` übergeben;
  JSON-Booleanwerte lösen einen TypeError aus
- Inhaltsgrößenlimit zunächst 100 MiB; größere Dateien bleiben über Namen und
  Metadaten auffindbar, die Inhaltsauswertung wird gesondert bewertet
- externe und föderierte Speicher nur, wenn sie bewusst zum produktiven
  Suchumfang gehören

Der reguläre Zielzustand ist die Suche über alle zugänglichen
organisatorischen Dateibereiche. Ein Pilot beschränkt nur die erste technische
Indexierung und niemals dauerhaft den kommunizierten Suchumfang.

## Rollout-Gates

Vor einer vollständigen Indexierung müssen erfolgreich sein:

1. `fulltextsearch:check` und `fulltextsearch:test`
2. Suche nach eindeutigen Begriffen in TXT/Markdown, PDF, DOCX und ODT
3. Treffer aus Team Folders
4. Berechtigungs-Negativtest mit mindestens zwei Konten
5. kein Treffer nach Entzug einer Gruppe oder Freigabe
6. keine Erreichbarkeit von Port 9200 aus Frontend, Backend oder vom Hostnetz
7. stabiler Betrieb unter dem Speicherlimit
8. ausreichend freier Plattenplatz und dokumentiertes Indexwachstum
9. Nextcloud-Dateioperationen, Cron, Client Push und Office weiterhin fehlerfrei

Die erste vollständige Indexierung wird in einer robusten, vom SSH-Terminal
unabhängigen Sitzung gestartet. Währenddessen werden Container-RAM, Host-RAM,
Load, Plattenbelegung, Elasticsearch-Health und Nextcloud-Logs beobachtet.

## Betrieb

Regelmäßige Kontrollen:

```bash
docker compose ps
docker compose logs --since=24h elasticsearch

docker run --rm \
  --network zircula_search \
  curlimages/curl:8.16.0 \
  --fail --silent \
  'http://elasticsearch:9200/_cat/indices?v'
```

Nach Updates werden mindestens Cluster-Health, Nextcloud-Plattformtest,
Berechtigungsfilter, PDF-/Office-Suche und Indexfortschritt geprüft.

## Backup und Restore

Originaldateien, Nextcloud-Konfiguration und App-Konfiguration werden durch das
bestehende Verfahren gesichert. Der Elasticsearch-Datenpfad wird bewusst von
Restic ausgeschlossen:

```text
/srv/zircula/elasticsearch
```

Nach einem Verlust wird ein leerer kompatibler Elasticsearch-Knoten gestartet,
die Plattform geprüft und der Index aus Nextcloud neu aufgebaut. Ein alter
Index darf nicht als einzige Quelle für Dokumentinhalte behandelt werden.

## Rückbau

Ein kontrollierter Rückbau verändert keine Originaldateien:

1. laufende Indexierung kontrolliert stoppen,
2. Full-Text-Search-Apps deaktivieren,
3. Nextcloud aus `zircula_search` entfernen und neu erstellen,
4. Elasticsearch stoppen,
5. erst nach Prüfung Datenverzeichnis und internes Netz entfernen.

Das Löschen des Index oder Datenverzeichnisses erfolgt niemals als beiläufiger
Diagnoseschritt.
