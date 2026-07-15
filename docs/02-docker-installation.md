# 02 – Docker-Installation

## Ziel

Installation und sicherer Betrieb der Container-Plattform auf dem VPS.

## Installierte Komponenten

- Docker Engine Community
- Docker CLI
- Docker Compose Plugin
- Docker Buildx
- containerd
- runc

Docker CE wurde aus dem offiziellen Docker-Repository installiert und mit einem
Testcontainer geprüft.

## Administration

Der Benutzer `timo` ist Mitglied der Gruppe `docker` und kann Docker ohne `sudo`
bedienen. Diese Gruppe verleiht praktisch Root-Rechte, da Mitglieder beliebige
Hostpfade mounten und privilegierte Container starten können.

Regeln:

- nur vollständige Hostadministratoren in der Gruppe `docker`
- Mitgliedschaft regelmäßig mit `getent group docker` prüfen
- Docker-Daemon nicht ungeschützt per TCP veröffentlichen
- Docker-Socket nur begründet in Container mounten
- produktive Verwaltung bevorzugt über versionierte Compose-Dateien

## Netzwerk und Firewall

Docker verwaltet eigene Firewall- und NAT-Regeln. Veröffentlichte Containerports
können vor UFW verarbeitet werden. Deshalb werden Portfreigaben nicht allein über
`ufw status`, sondern zusätzlich mit folgenden Befehlen kontrolliert:

```bash
ss -lntup
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}'
```

Docker-Firewallregeln werden nicht global deaktiviert, da dies Bridge-Netze und
Isolation beeinträchtigen kann.

## Sicherheitsprofile

Der Host verwendet:

- AppArmor mit `docker-default`
- Docker-Standard-Seccomp
- cgroup namespaces
- systemd als cgroup driver

Container erhalten keine zusätzlichen Capabilities oder Socket-Mounts, sofern
diese nicht im jeweiligen Stack dokumentiert sind.

## Updates

Ubuntu-Sicherheitsupdates laufen automatisiert. Docker-Engine, containerd und
normale Paketupdates werden regelmäßig geprüft und in einem Wartungsfenster
installiert. Container-Images werden getrennt nach `docs/06-update-strategy.md`
aktualisiert.

