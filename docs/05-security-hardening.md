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

Portainer 9000, PostgreSQL 5432, Redis 6379, Nextcloud 80, Collabora 9980 und Talk
Signaling 8081 dürfen nicht öffentlich veröffentlicht werden.

Docker-Portfreigaben werden vor UFW verarbeitet. Deshalb werden sowohl IPv4 als
auch IPv6 mit `ss`, Docker-Portlisten und einem externen Portscan geprüft. Docker-
Firewallregeln werden nicht pauschal deaktiviert.

## 2. SSH

Sollzustand nach erfolgreichem Test in einer zweiten offenen SSH-Sitzung und nach
Prüfung der Manitu-Konsole:

- ausschließlich Public-Key-Authentifizierung
- `PasswordAuthentication no`
- `KbdInteractiveAuthentication no`
- `PermitRootLogin no`
- persönliche Konten; keine gemeinsam genutzten Administratorzugänge
- `AllowUsers` nur, wenn die Liste organisatorisch gepflegt wird
- wenige Mitglieder in `sudo` und `docker`

Die effektive Konfiguration wird mit `sshd -T` geprüft. Dateien unter
`sshd_config.d` können frühere Einstellungen überschreiben.

## 3. Docker-Administration

Die Gruppe `docker` besitzt praktisch Root-Rechte. Nur Administratoren, die den
gesamten Host verwalten dürfen, werden Mitglied. Der Docker-Daemon wird nicht über
einen ungeschützten TCP-Port veröffentlicht.

Container erhalten weder `privileged: true` noch Host-PID/Host-Netzwerk, sofern
dies nicht zwingend dokumentiert ist. Zusätzliche Capabilities, Socket-Mounts,
schreibbare Hostpfade und root-Betrieb werden für jeden Stack begründet.

Besondere Ausnahmen:

- Collabora benötigt derzeit `MKNOD`; diese Ausnahme bleibt dienstbezogen.
- Authentik benötigt den Docker-Socket nur für automatisch verwaltete Outposts.
- Portainer benötigt den Docker-Socket für seine Kernfunktion und wird deshalb
  nur administrativ erreichbar gemacht oder entfernt.

## 4. Anwendungsschutz

- MFA für Nextcloud- und Authentik-Administratoren
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
- Backupalter und letzter erfolgreicher Restore-Test

