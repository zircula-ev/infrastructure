# Alarme einordnen

## Zustände

- **Pending:** Bedingung ist erfüllt, aber die vorgesehene Wartezeit läuft noch.
- **Firing:** Der Alarm ist aktiv und wurde gegebenenfalls weitergeleitet.
- **Resolved:** Die Bedingung besteht nicht mehr.

## Vorgehen bei einem Alarm

1. Alarmname, betroffenen Dienst und Zeitpunkt lesen.
2. Öffentlichen Dienst selbst prüfen.
3. Grafana-Dashboard und Uptime Kuma vergleichen.
4. Prüfen, ob ein bekanntes Wartungsfenster aktiv ist.
5. Bei tatsächlicher Störung ein LibreDesk-Ticket anlegen oder ergänzen.
6. Bei kritischem oder längerem Ausfall die technische Verantwortung
   eskalieren.
7. Entwarnung abwarten und Abschluss dokumentieren.

Ein Alert kann während eines Neustarts oder einer Wartung korrekt auslösen. Das
ist kein Fehlalarm, sondern eine erwartete Messung mit bekanntem Grund.

## Was nicht über die Oberfläche geändert wird

- provisionierte Alarmregeln
- Dashboards aus Git
- Datenquellen
- Contact Points und Notification Policies
- Schwellwerte zur schnellen Unterdrückung eines störenden Alarms

Geplante Unterdrückungen erfolgen über das abgestimmte Wartungsverfahren.
