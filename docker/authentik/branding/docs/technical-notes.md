# Technische Hinweise

## Versionsgrenze

Die Infrastruktur pinnt Server und Worker auf Authentik `2026.5.4`.
`branding_custom_css` und `branding_default_flow_background` stehen seit
Authentik 2025.4 zur Verfügung.

Das CSS priorisiert Authentik-Variablen mit `--ak-*`, ergänzt weiterhin
verwendete PatternFly-Variablen mit `--pf-*` und vermeidet tiefe DOM-Selektoren.
Verbleibende PatternFly-Fallbacks und exportierte `::part(...)`-Selektoren
werden vor jedem Authentik-Update erneut geprüft.

## Blueprint

Geplanter Modellname:

```text
authentik_brands.brand
```

Geplante Identifikation:

```yaml
state: present
identifiers:
  domain: auth.zircula.org
```

Bei einem vorhandenen Objekt aktualisiert `state: present` ausschließlich die
in `attrs` genannten Felder. Trotzdem werden die aktuellen Brand-Werte vorab
exportiert. Das JSON-Feld `attributes` wird erst nach Sichtung und bewusster
Zusammenführung der vorhandenen Werte verwaltet.

Vorhandene Flow-Zuweisungen, Default-Status, Default Application, Zertifikate und
der bestehende Flow-Hintergrund werden nicht ohne separate Freigabe in `attrs`
aufgenommen.

File-basierte Blueprints werden vom Worker unter `/blueprints` erkannt und bei
Änderungen erneut angewendet. Das Entfernen einer Blueprint-Datei entfernt die
Blueprint-Instanz, stellt aber die von ihr veränderten Objekte nicht zurück.

## Dateien und Assets

Binäre Uploads werden nicht in den Blueprint eingebettet. Logo und Favicon
werden mit unveränderlichen Dateinamen gleichursprünglich über Caddy ausgeliefert.
Es wird weder ein zusätzlicher Webserver noch ein zusätzlicher öffentlicher Port
eingeführt.

## Primärquellen

- https://docs.goauthentik.io/brands
- https://docs.goauthentik.io/brands/custom-css/
- https://docs.goauthentik.io/customize/interfaces/user/
- https://docs.goauthentik.io/customize/interfaces/admin/
- https://docs.goauthentik.io/customize/blueprints
- https://docs.goauthentik.io/customize/blueprints/v1/structure/
- https://docs.goauthentik.io/customize/files/
