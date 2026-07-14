# rclone

## Zweck

`rclone` ist Bestandteil der Infrastruktur und wird für folgende Aufgaben eingesetzt:

- Migration bestehender Nextcloud-Instanzen
- Backups der produktiven Nextcloud
- Wiederherstellung und Datenübertragungen bei Bedarf

Die eigentliche Konfiguration (`rclone.conf`) ist **nicht** Bestandteil des Git-Repositories und wird lokal auf dem Server gespeichert.

---

## Konfigurierte Remotes

| Remote | Zweck |
|--------|-------|
| `Werkhaus` | Alte WERK-Cloud (`cloud.werk-haus.org`) |
| `nextcloud.zircula` | Alte Zircula-Cloud |
| `cloud.zircula` | Produktive Nextcloud |

Weitere Remotes (z. B. Backup-Ziele) werden ergänzt, sobald sie eingerichtet sind.

---

## Test der Verbindung

```bash
rclone lsd Werkhaus:
rclone lsd nextcloud.zircula:
rclone lsd cloud.zircula:
```

---

## Hinweise

- Zugangsdaten werden ausschließlich in der lokalen `rclone.conf` gespeichert.
- Die Konfigurationsdatei wird **nicht** versioniert.
- Vor Änderungen an bestehenden Remotes sollte ein Backup der Konfiguration erstellt werden.
