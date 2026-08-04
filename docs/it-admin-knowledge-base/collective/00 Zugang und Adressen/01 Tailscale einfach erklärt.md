# Tailscale einfach erklärt

Tailscale verbindet freigegebene Geräte über ein privates Netzwerk, das
**Tailnet**. Dadurch kann Uptime Kuma intern erreichbar sein, ohne seine
Administrationsoberfläche öffentlich ins Internet zu stellen.

Die Uptime-Kuma-Weboberfläche liegt technisch nur lokal auf nctest. Tailscale
Serve stellt sie verschlüsselt innerhalb des Tailnets bereit. Normale
Internetnutzer:innen können die Adresse nicht erreichen.

## Das bedeutet praktisch

- Tailscale muss auf dem verwendeten Endgerät installiert und verbunden sein.
- Das angemeldete Tailscale-Konto muss zum richtigen Tailnet gehören.
- Zugriffsregeln des Tailnets gelten zusätzlich zur Anmeldung in Uptime Kuma.
- Tailscale ersetzt nicht das eigene Uptime-Kuma-Passwort und dessen TOTP.
- Authentik und Tailscale sind zwei getrennte Zugangssysteme.

Die direkte lokale Adresse und Port 3001 sind absichtlich nicht aus dem
Hausnetz freigegeben. Auch im Büro wird deshalb die Tailnet-Adresse verwendet.
