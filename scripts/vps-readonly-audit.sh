#!/usr/bin/env bash

set -u

section() {
  echo
  echo "## $1"
}

section "Betriebssystem"
uname -a
cat /etc/os-release

section "Ausstehende Pakete"
apt list --upgradable 2>/dev/null || true
test -e /var/run/reboot-required && cat /var/run/reboot-required || echo "Kein Neustartmarker vorhanden"

section "Automatische Updates"
systemctl is-enabled unattended-upgrades.service 2>/dev/null || true
systemctl status unattended-upgrades.service --no-pager -l 2>/dev/null || true
systemctl list-timers apt-daily.timer apt-daily-upgrade.timer --no-pager 2>/dev/null || true

section "Fehlgeschlagene Dienste"
systemctl --failed --no-pager || true

section "SSH Sollwerte"
sshd -T 2>/dev/null | grep -E '^(passwordauthentication|kbdinteractiveauthentication|permitrootlogin|pubkeyauthentication|maxauthtries|allowusers|allowgroups) ' || true

section "Privilegierte Gruppen"
getent group sudo || true
getent group docker || true

section "Lauschende Ports"
ss -lntup || true

section "UFW IPv4 und IPv6"
ufw status verbose 2>/dev/null || true

section "Docker Version und Sicherheitsoptionen"
docker version 2>/dev/null || true
docker info --format 'SecurityOptions={{json .SecurityOptions}} LoggingDriver={{.LoggingDriver}} CgroupDriver={{.CgroupDriver}} Rootless={{json .Rootless}}' 2>/dev/null || true

section "Container, Images und veröffentlichte Ports"
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null || true

section "Lokale Image-Digests"
docker image ls --digests 2>/dev/null || true

section "Umgebungsdatei-Rechte ohne Inhalte"
find /opt/zircula/git/infrastructure/docker -type f -name .env -exec stat -c '%a %U:%G %n' {} \; 2>/dev/null || true

section "AppArmor"
systemctl is-active apparmor 2>/dev/null || true
aa-status 2>/dev/null || true

section "Speicher"
df -hT
df -ih

echo
echo "Hinweis: Dieses Script liest keine .env-Inhalte und führt kein docker inspect aus."
echo "Die Ausgabe kann trotzdem Hostnamen, Benutzer und öffentliche IP-Adressen enthalten."
echo "Vor einer Weitergabe entsprechend prüfen und redigieren."
