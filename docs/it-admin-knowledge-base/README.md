# IT-Admin Knowledge Base

Stand: 04.08.2026

Diese Dokumentation ist für den Import in ein zugriffsbeschränktes Nextcloud
Collective vorgesehen. Sie beschreibt die tägliche Nutzung der
Administrationsoberflächen, nicht den technischen Serverbetrieb.

## Umfang

- Authentik: normale Benutzer:innen anlegen, aktivieren, Gruppen zuweisen und
  bei Anmeldung sowie MFA unterstützen
- Grafana: Dashboards und Alarme lesen und einordnen
- Uptime Kuma: Monitore prüfen, Wartungsfenster nutzen und Ausfälle bewerten
- LibreDesk: Supportfälle als Agent:in bearbeiten

Technische Konfiguration, Deployment, Recovery und Änderungen an der
Infrastruktur bleiben in den übrigen Git-Dokumenten.

## Import

Das Verzeichnis `collective` wird als Wurzel in ein nur für die zuständige
IT-Gruppe freigegebenes Collective importiert. Die konkreten IDs werden vor dem
Import aus der Nextcloud-Oberfläche ermittelt.

```bash
docker compose exec -T --user www-data nextcloud \
  php -d memory_limit=1G occ collectives:import:markdown \
  --collective-id=<COLLECTIVE_ID> \
  --user-id=<IMPORT_USER_ID> \
  --parent-id=0 \
  --no-interaction \
  /tmp/zircula-it-admin-knowledge-base
```

Nach dem Import werden Seitenbaum, Links, Bearbeitungsrechte und Sichtbarkeit
mit einem normalen IT-Admin-Konto geprüft.
