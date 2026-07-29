# 05 – Security Hardening

Dieses Dokument beschreibt ein verhältnismäßiges Sicherheitsniveau für den
Zircula-VPS. Änderungen werden einzeln durchgeführt und nach jeder Stufe getestet.
Ein vollständiges CIS-Profil wird nicht blind angewendet, da es Docker,
Dateiberechtigungen oder Wiederherstellungszugänge beeinträchtigen kann.

## 1. Exponierte Dienste

Von außen erforderlich sind nur:

| Port | Protokoll | Zweck |
|---|---|---|
| 22 | TCP | SSH; nach Möglichkeit auf VPN oder feste Admin-IP beschränken |
| 80 | TCP | ACME und HTTPS-Weiterleitung durch Caddy |
| 443 | TCP/UDP | HTTPS und HTTP/3 durch Caddy |
| 3478 | TCP/UDP | Nextcloud Talk TURN/STUN |

PostgreSQL 5432, Redis 6379, Nextcloud 80, Collabora 9980 und Talk Signaling 8081
dürfen nicht öffentlich veröffentlicht werden.

Docker-Portfreigaben werden vor UFW verarbeitet. Deshalb werden sowohl IPv4 als
auch IPv6 mit `ss`, Docker-Portlisten und einem externen Portscan geprüft. Docker-
Firewallregeln werden nicht pauschal deaktiviert.

## 2. SSH

Umgesetzter Stand vom 15.07.2026:

- ausschließlich Public-Key-Authentifizierung
- `PasswordAuthentication no`
- `KbdInteractiveAuthentication no`
- `PermitRootLogin no`
- `PubkeyAuthentication yes`
- `MaxAuthTries 3`
- persönliche Konten; keine gemeinsam genutzten Administratorzugänge
- `AllowUsers` nur, wenn die Liste organisatorisch gepflegt wird
- wenige Mitglieder in `sudo` und `docker`

Die Einstellungen liegen in
`/etc/ssh/sshd_config.d/00-zircula-hardening.conf`. OpenSSH verwendet für viele
Direktiven den zuerst gelesenen Wert, deshalb wird die Datei bewusst früh geladen.
Syntax und effektive Konfiguration werden vor jedem Reload geprüft:

```bash
sudo sshd -t
sudo sshd -T | \
  grep -E '^(permitrootlogin|passwordauthentication|kbdinteractiveauthentication|pubkeyauthentication|maxauthtries) '
```

Der Reload erfolgt nur bei erfolgreicher Prüfung und mit mindestens einer offenen
Rückfallsitzung. Anschließend wird eine vollständig neue Public-Key-Sitzung als
persönlicher Administrator einschließlich `sudo` getestet.

## 3. Docker-Administration

Die Gruppe `docker` besitzt praktisch Root-Rechte. Nur Administratoren, die den
gesamten Host verwalten dürfen, werden Mitglied. Der Docker-Daemon wird nicht über
einen ungeschützten TCP-Port veröffentlicht.

Container erhalten weder `privileged: true` noch Host-PID/Host-Netzwerk, sofern
dies nicht zwingend dokumentiert ist. Zusätzliche Capabilities, Socket-Mounts,
schreibbare Hostpfade und root-Betrieb werden für jeden Stack begründet.

Besondere Ausnahmen:

- Collabora benötigt derzeit `MKNOD`; diese Ausnahme bleibt dienstbezogen.
- Der Authentik-Worker läuft ohne Root-Rechte und Docker-Socket. Der derzeit
  verwendete Embedded Outpost benötigt keinen Socket. Falls später verwaltete
  Docker-Outposts eingeführt werden, wird dafür eine getrennte, erneut geprüfte
  Integration benötigt.

## 4. Anwendungsschutz

- gruppenbasierte MFA über Authentik für Administratoren, Vorstände,
  `Objekt 218 GmbH` und `Vaultwarden Users`
- getrennte persönliche Administratorkonten und dokumentierte Break-Glass-Konten
- Break-Glass-Zugangsdaten offline und verschlüsselt verwahren
- Authentik- und Nextcloud-Adminaktionen nach Einführung eines stabilen VPNs auf
  Admin-Netze beschränken
- regelmäßig Freigaben, App-Berechtigungen, Gruppenadministratoren und inaktive
  Konten kontrollieren
- Debug-/Trace-Logging nur kurzzeitig aktivieren; Logs können sensible Daten
  enthalten

## 5. Daten und Secrets

- alle produktiven `.env` mit Modus 600 und restriktivem Eigentümer
- `rclone.conf`, Datenbankdumps, private Schlüssel und Backups niemals committen
- Secret Scanning und Push Protection im GitHub-Repository aktivieren
- Repository inklusive Historie regelmäßig mit Gitleaks oder Trivy scannen
- Secrets nach vermutetem Leak rotieren; Löschen aus dem aktuellen Commit reicht
  nicht aus

## 6. Hostschutz

- tägliche Ubuntu-Sicherheitsupdates über `unattended-upgrades`
- Neustartbedarf überwachen und in einem angekündigten Wartungsfenster erledigen
- AppArmor aktiv lassen und Docker-Standardprofile nicht global abschalten
- unnötige Pakete und Dienste entfernen
- Zeitabgleich, ausreichend freier Speicher und persistente Logrotation überwachen
- für Redis dauerhaft `vm.overcommit_memory=1` über `/etc/sysctl.d/99-redis.conf`
  setzen und nach Host-Neustarts kontrollieren
- Fail2ban zunächst nur für SSH und später anhand realer Nextcloud-/Authentik-Logs
  gezielt ergänzen; keine ungeprüften Filterregeln übernehmen

## 7. Regelmäßige Kontrolle

Monatlich:

- externe Portprüfung für IPv4 und IPv6
- Mitglieder von `sudo` und `docker`
- fehlgeschlagene Dienste und Neustartbedarf
- Container-Image- und Repository-Scan auf hohe/kritische Befunde
- Nextcloud-Administrationswarnungen und Security Scan
- Authentik-Systemaufgaben und Warnungen
- Prometheus-Targets, aktive Alarme, TLS-Restlaufzeiten und Grafana-Zugänge
- Backupalter und letzter erfolgreicher Restore-Test

## Umsetzungsstand vom 29.07.2026

Abgeschlossen:

- alle produktiven `.env` auf Modus 600
- SSH-Hardening einschließlich neuem Public-Key-Login-Test
- Redis-Passwortauthentifizierung über Compose-Secret
- Redis- und Nextcloud-Funktionstest nach dem Rollout
- `vm.overcommit_memory=1` dauerhaft gesetzt
- Dependabot-Benachrichtigungen für alle im Repository geführten Compose-Stacks
- Authentik-Worker ohne Root-Rechte, Docker-Socket und Frontend-Netz
- interne Monitoringdienste ohne öffentliche Hostports
- Node Exporter mit ausschließlich lesenden Host-Mounts
- Alertmanager-Secret als lokale, schreibgeschützt eingebundene Datei
- Grafana nur über Caddy veröffentlicht, mit lokalem Break-Glass-Konto und
  Authentik-OIDC
- Uptime Kuma getrennt auf `nctest`, nur über Tailscale administrierbar
- Vaultwarden als UID/GID 1000 ohne Capabilities, Docker-Socket oder Host-Port
- Vaultwarden-OIDC, Master-Passwort, SMTP und öffentliche TLS-Route geprüft

Noch offen:

- externes verschlüsseltes Backup und dokumentierter Restore-Test
- regelmäßiges Image- und Secret-Scanning
- Docker-Logrotation verbindlich begrenzen
- Fail2ban anhand realer Logs gezielt bewerten


## Vaultwarden-Zielzustand

Der bereitgestellte, noch nicht organisatorisch freigegebene Vaultwarden-Stack
folgt zusätzlich diesen Regeln:

- Prozess als UID/GID 1000, ohne Capabilities, Docker-Socket oder Host-Port
- read-only Root-Dateisystem; ausschließlich `/data` und begrenztes `/tmp`
  schreibbar
- Selbstregistrierung im Normalbetrieb und serverweite Admin-Konsole deaktiviert
- OIDC nur mit PKCE und verifizierter E-Mail-Zuordnung
- kein externes Icon-Fetching und keine Bitwarden-Sends in der ersten Stufe
- kleinster möglicher Owner-Kreis und getrennte Organisations-Collections
- produktive Secrets erst nach verschlüsseltem externem Backup und Restore-Test
- MFA für alle Vaultwarden-Berechtigten als Produktionsfreigabe; ohne Smartphone
  werden WebAuthn-Hardware-Schlüssel vorgesehen

Root und Mitglieder der Docker-Gruppe bleiben in der Lage, lokale
Konfigurationen und den verschlüsselten Serverdatenbestand zu kopieren. Die
Ende-zu-Ende-Verschlüsselung ersetzt daher weder Host-Hardening noch
Zugriffsgovernance und Rotation bei Offboarding.
