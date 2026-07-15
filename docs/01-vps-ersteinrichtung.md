# 01 – VPS-Ersteinrichtung

## Ziel

Der VPS wird als sicherer und nachvollziehbar administrierter Docker-Host für die
Zircula-Infrastruktur betrieben.

## Basis

- Ubuntu 26.04 LTS, x86_64
- 8 vCPU, 16 GB RAM, 480 GB SSD
- Hostname `vps.zircula.org`
- persönlicher Administrator `timo` mit `sudo`
- SSH-Zugang per Public Key
- automatische Sicherheitsupdates über `unattended-upgrades`
- UFW für IPv4 und IPv6
- AppArmor und Docker-Standard-Seccomp aktiv

## Verzeichnisstruktur

```text
/opt/zircula
├── backups
├── docker
├── docs
├── git
└── scripts

/srv/zircula
└── persistente Daten der Docker-Stacks
```

## Öffentlich benötigte Ports

| Port | Protokoll | Zweck |
|---|---|---|
| 22 | TCP | SSH |
| 80 | TCP | HTTP/ACME über Caddy |
| 443 | TCP | HTTPS über Caddy |
| 3478 | TCP/UDP | Nextcloud Talk TURN/STUN |

PostgreSQL, Redis, Nextcloud, Collabora, Authentik und Talk-Signaling
veröffentlichen keine weiteren Hostports.

Docker-Portfreigaben werden zusätzlich über `docker ps` und `ss -lntup` geprüft,
da veröffentlichte Docker-Ports UFW-Regeln umgehen können.

## Sicherheitskonzept

- jeder Administrator erhält einen eigenen Linux-Benutzer
- ausschließlich SSH-Schlüssel, keine Passwortanmeldung
- nur notwendige Mitglieder in `sudo` und `docker`
- produktive `.env` besitzen Modus 600
- Root-SSH wird deaktiviert, sobald der Zugang über `timo` und die Manitu-Konsole
  als Rückfallebene abschließend getestet sind
- Break-Glass-Zugänge werden offline und verschlüsselt dokumentiert

## Aktueller Prüfstand vom 15.07.2026

- `unattended-upgrades` aktiv
- keine fehlgeschlagenen systemd-Dienste
- AppArmor aktiv; `docker-default` im Enforce-Modus
- erwartete Ports 22, 80, 443 und 3478 auf IPv4 und IPv6
- `PasswordAuthentication no`
- noch offen: `PermitRootLogin yes` und `MaxAuthTries 6`
- noch offen: produktive `.env` von 664 auf 600 setzen

Die offenen Hostmaßnahmen werden nach einem kontrollierten Zugangstest umgesetzt.

