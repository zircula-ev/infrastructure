# 09 – Container- und Privilegien-Review

Stand: 23.07.2026

## Ziel und Abgrenzung

Dieses Review bewertet Hostport-Freigaben, Containerprivilegien, Socket-Mounts,
Capabilities und Docker-Netzreichweite. Backupstrategie und MFA-Governance sind
bewusst nicht Bestandteil dieses Dokuments.

Das Review ist keine Zertifizierung des laufenden VPS. Die Repository-Konfiguration
wird zusätzlich durch Laufzeitprüfungen mit `docker inspect`, `ss`, UFW und
einem externen IPv4-/IPv6-Portscan bestätigt.

## Ergebnis

Die grundlegende Architektur ist angemessen:

- Nur Caddy veröffentlicht 80/TCP und 443/TCP.
- Talk HPB veröffentlicht den erforderlichen TURN-Port über TCP und UDP.
- Nextcloud, Authentik, Collabora, PostgreSQL und Redis besitzen keine Hostports.
- PostgreSQL und Redis liegen ausschließlich im Backend-Netz.
- Talk HPB verwendet ein schreibgeschütztes Root-Dateisystem und reduziert
  Capabilities.
- Redis läuft ausdrücklich als unprivilegierter Benutzer.

Ein kritischer, vermeidbarer Privilegienpfad wurde behoben: Der Authentik-Worker
lief zuvor als Root und hatte den Docker-Socket eingebunden. Damit hätte eine
Kompromittierung des Workers faktisch zu Root-Rechten auf dem Host führen können.

## Umgesetzte und validierte Änderung

Für den aktuellen Funktionsumfang werden keine automatisch bereitgestellten
Docker-Outposts benötigt. Nextcloud verwendet OIDC und der vorhandene
`authentik Embedded Outpost` läuft im Authentik-Server selbst.

Daher wird:

1. der Docker-Socket aus dem Worker entfernt,
2. `user: root` aus dem Worker entfernt,
3. automatische Outpost-Integrationssuche deaktiviert,
4. der Worker aus dem gemeinsamen Frontend-Netz entfernt.

Der Worker behält:

- Zugriff auf seine Authentik-Verzeichnisse,
- Zugriff auf PostgreSQL über das Backend-Netz,
- normalen ausgehenden Netzwerkzugriff für SMTP und benötigte externe Anfragen.

Deployment, Eigentümerprüfung, Funktionstest und Rollback stehen in
`docker/authentik/README.md`.

Die Änderung wurde am 23.07.2026 ausgerollt. Geprüft wurden UID/GID 1000,
fehlender Docker-Socket, ausschließlich das Backend-Netz, der Worker-Healthcheck,
die öffentlichen Live- und Ready-Endpunkte sowie ein erfolgreicher
Authentik-Login.

## Bewertung der übrigen Stacks

### Caddy

Caddy veröffentlicht ausschließlich die beabsichtigten Webports und ist nur mit
dem Frontend-Netz verbunden. Der einfache Reverse-Proxy-Aufbau ist kein
Sicherheitsmangel; TLS und Zertifikatsverwaltung werden von Caddy implementiert.

Die Dokumentation nennt 443/UDP für HTTP/3, während Compose derzeit nur 443/TCP
veröffentlicht. Das ist keine Sicherheitslücke. Entweder bleibt HTTP/3 bewusst
deaktiviert oder Dokumentation und Portfreigabe werden später gemeinsam angepasst.

### Nextcloud

Nextcloud veröffentlicht keinen Hostport. Das offizielle Apache-Image benötigt
Schreibzugriff auf Installation, Apps, Konfiguration und Nutzdaten. Ein pauschales
`read_only: true` oder ungetestetes Entfernen aller Capabilities würde Updates,
App-Verwaltung und Laufzeitfunktionen gefährden und wird deshalb nicht in diese
Änderung aufgenommen.

Die beiden Netze sind funktional erforderlich: Frontend für Caddy und verbundene
Anwendungen, Backend für PostgreSQL und Redis.

### PostgreSQL

PostgreSQL veröffentlicht keinen Hostport und liegt nur im Backend. Das offizielle
Image startet seinen Entrypoint mit den für Initialisierung und Eigentümerprüfung
erforderlichen Rechten und wechselt anschließend zum Datenbankbenutzer. Ein
Compose-`user` wird nicht ohne isolierten Restore- und Initialisierungstest
erzwungen.

### Redis

Redis läuft ausdrücklich als Benutzer `redis`, besitzt keinen Hostport,
verwendet Passwortauthentifizierung und nutzt ein temporäres `/tmp`. Hier wurde
kein zusätzlicher hochpriorisierter Privilegienpfad gefunden.

### Collabora

Collabora veröffentlicht keinen Hostport. Die zusätzliche Capability `MKNOD`
ist als dienstbezogene Ausnahme dokumentiert. Sie wird nur nach einem
Collabora-spezifischen Test entfernt; ein pauschales Entfernen könnte die
Sandboxing-Funktion des Images beeinträchtigen.

### LibreDesk und LibreDesk Redis

Der vorbereitete LibreDesk-PoC veröffentlicht keine Hostports. Die Anwendung
läuft als UID/GID 1000 mit read-only Root-Dateisystem, `cap_drop: ALL` und
`no-new-privileges`; ausschließlich der Uploadpfad und ein begrenztes `/tmp`
sind schreibbar. Der anwendungseigene Redis läuft getrennt als Image-Benutzer
`redis`, nur im Backend-Netz und mit eigener Passwortauthentifizierung. Auch er
besitzt ein read-only Root-Dateisystem, keine Capabilities und nur den AOF-Pfad
als persistente Schreibfläche.

Die tatsächlichen UID/GID-, Mount-, Capability-, Port- und Netzwerkwerte werden
vor einer Produktivfreigabe auf dem VPS mit `docker inspect` bestätigt. Der PoC
teilt weder das Nextcloud-Redis-Passwort noch dessen Datenbestand.

### Talk HPB

Talk HPB benötigt den direkten TURN-Port. Der Container verwendet bereits
`read_only: true`, definierte `tmpfs`-Pfade und entfernt `NET_RAW`. Diese
Konfiguration ist im Vergleich zu den übrigen Anwendungscontainern bereits
restriktiv.

## Gemeinsame Docker-Netze

Das gemeinsame Frontend ermöglicht einem kompromittierten Frontend-Container,
interne Ports anderer Frontend-Dienste zu erreichen. Das gemeinsame Backend
ermöglicht Nextcloud und Authentik, die Datenbankports im Backend zu erreichen;
getrennte Datenbankrollen und Redis-Authentifizierung begrenzen den Zugriff.

Eine spätere zweite Hardening-Stufe kann Caddy und jeden Upstream über getrennte
Edge-Netze verbinden. Datenbanknetze können ebenfalls pro Anwendung getrennt
werden. Diese Änderung betrifft mehrere Stacks und wird nicht mit dem
Authentik-Worker-Hardening vermischt.

## Weitere Empfehlungen

### Hohe Priorität

- Der Authentik-Worker ist gehärtet und geprüft. Bei jeder späteren
  Outpost-Änderung erneut bestätigen, dass kein Docker-Socket erforderlich ist.
- Bestätigen, dass kein Container den Docker-Socket mountet, sofern dies nicht
  ausdrücklich dokumentiert und separat abgesichert ist.
- Öffentliche Ports von einem externen IPv4- und IPv6-System prüfen.
- Mitglieder der Gruppen `docker` und `sudo` regelmäßig kontrollieren.

### Mittlere Priorität

- Caddy, PostgreSQL und Redis nach Tests auf konkrete Patch-Tags oder Digests
  festlegen; Major- oder Minor-Tags sind veränderlich.
- Docker-Logrotation verbindlich konfigurieren.
- Image- und Repository-Scanning mit Trivy beziehungsweise Gitleaks ergänzen.
- Gemeinsame Docker-Netze in einer separaten Änderung segmentieren.
- Laufzeitbenutzer, Capabilities und Mounts monatlich automatisiert inventarisieren.

### Nicht pauschal anwenden

Folgende Maßnahmen werden nicht blind auf alle Container übertragen:

- `read_only: true`
- `cap_drop: ALL`
- erzwungene numerische Benutzer
- `no-new-privileges`
- interne Docker-Netze ohne ausgehendes Routing

Diese Optionen sind grundsätzlich sinnvoll, können aber Initialisierung,
Updates, Sandboxing, SMTP und Hintergrundjobs brechen. Sie werden pro Image in
einer isolierten Testumgebung eingeführt und mit einem dienstspezifischen
Rollback versehen.

## Laufzeitprüfung

Die Prüfung umfasst alle produktiven Anwendungs- und Monitoringcontainer:

```bash
containers=(
  caddy nextcloud postgres redis collabora
  authentik-server authentik-worker talk-hpb
  node-exporter blackbox-exporter alertmanager prometheus grafana
  vaultwarden libredesk libredesk-redis
)

docker inspect --format \
  '{{.Name}} user={{.Config.User}} privileged={{.HostConfig.Privileged}} readonly={{.HostConfig.ReadonlyRootfs}} ports={{json .NetworkSettings.Ports}}' \
  "${containers[@]}"
docker inspect --format \
  '{{.Name}}{{range .Mounts}} {{.Source}}:{{.Destination}}:rw={{.RW}}{{end}}' \
  "${containers[@]}"
docker inspect --format \
  '{{.Name}}{{range $name, $_ := .NetworkSettings.Networks}} {{$name}}{{end}}' \
  "${containers[@]}"

sudo ss -lntup
sudo ufw status verbose
```

Dabei werden Benutzer, Read-only-Root-Dateisystem, Capabilities, Mounts, Netze
und Hostport-Freigaben mit den jeweiligen Stack-READMEs abgeglichen.

Erwartete öffentliche Ports:

- 22/TCP
- 80/TCP
- 443/TCP
- 3478/TCP
- 3478/UDP

Zusätzliche Listener werden einzeln einem dokumentierten Dienst zugeordnet oder
geschlossen. Wegen der Interaktion zwischen Docker und UFW ersetzt diese lokale
Prüfung keinen externen Portscan.
