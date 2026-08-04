# Monitore prüfen

## Bei einer Meldung

1. Uptime Kuma öffnen.
2. Den betroffenen Monitor auswählen.
3. Status, Zeitpunkt, Fehlermeldung und Heartbeat-Verlauf ansehen.
4. Dienst zusätzlich im Browser öffnen.
5. Mit Grafana und bekannten Wartungen vergleichen.

## Einordnung

- **Down und Dienst nicht erreichbar:** wahrscheinliche echte Störung
- **Down, Dienst im Browser erreichbar:** DNS, Zertifikat, erwarteter
  Statuscode, Suchbegriff oder kurzer Übergang können die Ursache sein
- **Mehrere Dienste gleichzeitig Down:** VPS, Netzwerk, Reverse Proxy oder
  Wartung als gemeinsame Ursache prüfen
- **Kurzer Ausfall mit schneller Entwarnung:** Zeitpunkt und möglichen
  Neustart/Wartung abgleichen

Ein Monitor wird nicht einfach pausiert, um Benachrichtigungen zu stoppen.
Fehlkonfigurationen werden nachvollziehbar korrigiert; echte Wartung erhält ein
Wartungsfenster.
