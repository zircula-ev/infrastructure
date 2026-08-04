# Uptime-Kuma-Alarm behandeln

## Kurzablauf

1. Nicht nur auf die Nachricht reagieren, sondern den Monitor öffnen.
2. Dienst von einem unabhängigen Gerät oder Netz prüfen, wenn möglich.
3. Grafana auf gemeinsame Auffälligkeiten kontrollieren.
4. Laufende Wartung oder angekündigten Neustart prüfen.
5. Bei bestätigtem Ausfall LibreDesk-Ticket eröffnen oder aktualisieren.
6. Bei mehreren oder kritischen Diensten sofort eskalieren.
7. Nach der Entwarnung Ursache, Dauer und Ergebnis festhalten.

## Priorität

Hohe Priorität haben insbesondere gleichzeitig ausfallende zentrale Dienste,
die Cloud-Anmeldung, Nextcloud sowie Ausfälle, die nach einem Wartungsfenster
bestehen bleiben.

Ein einzelner vorübergehender Monitorfehler kann beobachtet werden. Wiederholte
Fehler werden auch dann untersucht, wenn Nutzer:innen den Dienst zwischendurch
erreichen können.

Testmonitore werden nach abgeschlossenem Test wieder entfernt oder eindeutig als
Test gekennzeichnet.
