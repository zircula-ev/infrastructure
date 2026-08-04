# Uptime Kuma

Uptime Kuma läuft unabhängig vom VPS auf nctest und prüft die öffentlich
erreichbaren Dienste. Es beantwortet vor allem: **Ist der Dienst von außen
erreichbar?**

Die Oberfläche eignet sich für:

- aktuellen Zustand eines Monitors
- Antwortzeit und Heartbeat-Verlauf
- Zeitpunkt eines Ausfalls und einer Entwarnung
- geplante Wartungsfenster
- Test der eingerichteten Benachrichtigungen

## Zugang

Die Oberfläche ist ausschließlich über Tailscale unter
`https://nctest.tailf7eaa5.ts.net:8443` erreichbar und verwendet zusätzlich
eine eigene Anmeldung mit TOTP. Einladung, Ersteinrichtung und Offboarding
stehen im Bereich **Zugang und Adressen**.

Neue oder geänderte Monitore werden nach dem Speichern immer kontrolliert
getestet.
