# Grafana

Grafana zeigt technische Messwerte und den zeitlichen Verlauf des VPS und seiner
Dienste. Es hilft bei der Frage: **Was passiert gerade und seit wann?**

Grafana ist nicht dasselbe wie Uptime Kuma:

- Grafana bewertet Metriken wie CPU, Speicher, Updates, Backups und Zertifikate.
- Uptime Kuma prüft von nctest aus, ob öffentliche Dienste erreichbar sind.

Die Dashboards und Alarmregeln werden überwiegend aus Git bereitgestellt.
Provisionierte Inhalte werden deshalb nicht spontan in der Oberfläche geändert.
