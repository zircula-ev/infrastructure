# Einladung und erster Zugriff

## Für die einladende Administration

1. Prüfen, ob die Person Uptime Kuma tatsächlich bedienen soll.
2. In der Tailscale-Administrationsoberfläche die Person mit ihrer vorgesehenen
   Identität einladen.
3. Nur die notwendige Rolle und den vorgesehenen Zugriff vergeben.
4. Falls **Needs approval** angezeigt wird, die Person nach Identitätsprüfung
   freigeben.
5. Abschluss und Umfang im zugehörigen LibreDesk-Ticket dokumentieren.

## Für die eingeladene Person

1. Einladung aus der offiziellen Tailscale-Mail öffnen.
2. Tailscale von der offiziellen Downloadseite installieren.
3. Mit genau dem Konto anmelden, an das die Einladung gesendet wurde.
4. Prüfen, dass Tailscale **Connected** anzeigt.
5. Die interne Uptime-Kuma-Adresse im Browser öffnen.
6. Mit dem separat übergebenen persönlichen oder vorgesehenen
   Uptime-Kuma-Konto anmelden.
7. TOTP-Abfrage testen.

## Wenn keine Verbindung möglich ist

- Prüfen, ob das richtige Tailnet aktiv ist.
- Status des Tailscale-Clients kontrollieren.
- Auf ausstehende Benutzer- oder Gerätefreigabe prüfen.
- Adresse einschließlich `:8443` vollständig eingeben.
- Nicht versuchen, Uptime Kuma über eine öffentliche oder lokale Ersatzadresse
  freizugeben.
