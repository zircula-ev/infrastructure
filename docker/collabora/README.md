# Collabora Online

Dieser Stack stellt Collabora Online Development Edition für Nextcloud Office
unter `https://office.zircula.org` bereit.

## Architektur

```text
Browser ──HTTPS──► Caddy ──HTTP/Docker──► Collabora
    │                                      │
    └──────── Dokumentzugriff über Nextcloud/WOPI ────────┘
```

Collabora ist ausschließlich mit `zircula_frontend` verbunden. Es veröffentlicht
keinen Hostport; Caddy erreicht den Dienst intern auf Port 9980. TLS endet bei
Caddy, Collabora läuft intern ohne TLS.

## Dateien

- `compose.yaml` – Container, Capability und Netzwerk
- `.env.example` – Domain und erlaubter WOPI-Host; die Image-Version steht direkt
  in `compose.yaml`
- `.env` – produktive lokale Konfiguration; nicht versioniert, Modus 600

Collabora ist weitgehend zustandslos. Benutzerdokumente verbleiben in Nextcloud.

## Erlaubter Nextcloud-Host

`COLLABORA_ALIASGROUP1` wird auf die produktive Nextcloud
`https://cloud.zircula.org` begrenzt. Alte Test- oder VPS-Domains werden nicht
dauerhaft in der Allowlist behalten.

## Start

```bash
cp .env.example .env
chmod 600 .env
docker compose config --quiet
docker compose up -d
docker compose ps
docker compose logs --tail=100 collabora
```

## Nextcloud-Konfiguration

In Nextcloud Office:

```text
https://office.zircula.org
```

Die Nextcloud-WOPI-Allowlist muss den Netzwerkpfad zulassen, über den Collabora
Nextcloud erreicht. Eine feste CIDR wie `172.18.0.0/16` darf nicht ungeprüft aus
der Dokumentation übernommen werden. Aktuelles Frontend-Netz ermitteln:

```bash
docker network inspect zircula_frontend --format '{{json .IPAM.Config}}'
```

Danach den tatsächlich benötigten Bereich so eng wie mit der bestehenden
Netzwerkarchitektur möglich setzen und dokumentieren:

```bash
docker exec nextcloud php occ config:app:set richdocuments wopi_allowlist --value="<GEPRUEFTE_CIDR>"
docker exec nextcloud php occ config:app:get richdocuments wopi_allowlist
```

## Prüfung

`https://office.zircula.org` liefert bei betriebsbereitem Dienst eine kurze
OK-Antwort. Der maßgebliche Funktionstest ist das Öffnen, Bearbeiten und Speichern
eines Dokuments in Nextcloud.

## Sicherheit

- kein veröffentlichter Docker-Port
- Zugriff ausschließlich über Caddy
- WOPI auf die produktive Nextcloud begrenzen
- `MKNOD` ist die dokumentierte dienstspezifische Capability
- keine Dokumente dauerhaft im Container

## Updates

```bash
docker compose pull
docker compose up -d
docker compose logs --tail=100 collabora
```

Vor dem Update Release Notes und Nextcloud-Office-Kompatibilität prüfen. Danach
ein Dokument öffnen, bearbeiten und speichern.

