# Zugang und Adressen

Nicht alle Werkzeuge sind öffentlich erreichbar. Für die tägliche
IT-Administration gibt es zwei Zugangsarten:

- Authentik-SSO für Authentik, Grafana und LibreDesk
- Tailscale plus eine eigene Anmeldung für Uptime Kuma auf nctest

## Wer braucht Tailscale?

Tailscale-Zugang ist nur erforderlich, wenn eine Person Uptime Kuma bedienen
oder einen anderen ausdrücklich freigegebenen internen nctest-Dienst erreichen
soll. Wer ausschließlich Benutzer:innen in Authentik verwaltet oder Tickets in
LibreDesk bearbeitet, benötigt ihn nicht automatisch.

Die Aufnahme in eine Authentik-Gruppe lädt niemanden in das Tailnet ein.
Ein:e berechtigte:r Tailnet-Administrator:in muss die Person separat einladen
und gegebenenfalls freigeben.

## Sicherheitsgrundsatz

Der Tailnet-Zugang wird nur auf persönlich verwalteten, ausreichend geschützten
Geräten eingerichtet. Einladungslinks, Zugangsdaten und MFA-Codes werden nicht
in LibreDesk, Collectives oder Chat-Nachrichten abgelegt.
