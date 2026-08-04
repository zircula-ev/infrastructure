# Dashboards lesen

## Einstieg

1. Grafana über die zentrale Anmeldung öffnen.
2. Das bereitgestellte Übersichts-Dashboard auswählen.
3. Oben rechts einen sinnvollen Zeitraum einstellen.
4. Bei einer Auffälligkeit den Zeitraum vergrößern und benachbarte Kacheln
   vergleichen.

## Wichtige Werte

- CPU-Auslastung und Systemlast
- Arbeitsspeicher und freier Speicherplatz
- Erreichbarkeit über Blackbox-Prüfungen
- verfügbare System- und Sicherheitsupdates
- erforderlicher Neustart
- Erfolg, Zeitpunkt und Dauer des letzten Backups
- Ablaufzeit von TLS-Zertifikaten

Ein einzelner kurzer Ausschlag ist nicht automatisch ein Vorfall. Entscheidend
sind Dauer, Wiederholung und Auswirkungen auf die Dienste.

## Gute Dokumentation im Ticket

- betroffener Dienst
- Beginn und Ende der Auffälligkeit
- ausgewählter Zeitraum
- beobachtete Werte
- gleichzeitig aktive Alarme
- bereits durchgeführte, nicht verändernde Prüfungen

Keine Screenshots veröffentlichen, wenn darauf interne Adressen, Kontaktdaten
oder andere sensible Informationen zu sehen sind.
