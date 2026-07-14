# Collabora Online

## Purpose

This stack provides the **Collabora Online Development Edition (CODE)** used by Nextcloud Office.

The service is intentionally separated from the Nextcloud container and exposed exclusively through the central Caddy reverse proxy.

---

## Architecture

```text
Browser
    │
    ▼
office.zircula.org
    │
    ▼
Caddy
    │
    ▼
Collabora (Port 9980)
```

When a user opens an Office document in Nextcloud, the communication flow is:

```text
Browser
    │
    ▼
Nextcloud (vps.zircula.org / cloud.zircula.org)
    │
    │ WOPI
    ▼
office.zircula.org
    │
    ▼
Collabora
```

Collabora is **not accessed directly by users**. The browser loads the Office editor through the `office.zircula.org` endpoint while all document access is controlled through Nextcloud using the WOPI protocol.

---

## Public URL

```
https://office.zircula.org
```

---

## Docker Network

This service is connected only to:

```
zircula_frontend
```

No backend network is required.

Communication between Nextcloud and Collabora always happens via HTTPS through Caddy.

---

## Reverse Proxy

TLS termination is handled by Caddy.

Collabora itself runs without TLS.

Environment:

```text
extra_params=--o:ssl.enable=false --o:ssl.termination=true
```

---

## Persistent Data

Collabora is largely stateless.

No user documents are stored inside the container.

All documents remain inside Nextcloud.

---

## Environment Variables

Example:

```env
TZ=Europe/Berlin

COLLABORA_VERSION=26.04.2.1.1

COLLABORA_DOMAIN=office.zircula.org

COLLABORA_ALIASGROUP1=https://(nextcloud|vps)\.zircula\.org
```

---

## Nextcloud Configuration

Within the Nextcloud Office app:

**Collabora URL**

```
https://office.zircula.org
```

---

## Important: WOPI Allowlist

After configuring Nextcloud Office, documents may fail to open with:

```
Unauthorized WOPI host
```

or

```
WOPI::CheckFileInfo returned 403 (Forbidden)
```

### Cause

The Nextcloud setting

```
richdocuments.wopi_allowlist
```

does **not** expect the public Collabora hostname.

Instead it must contain the **Docker network** from which WOPI requests originate.

For this infrastructure:

```
172.18.0.0/16
```

Configure using:

```bash
docker exec nextcloud php occ config:app:set richdocuments wopi_allowlist --value="172.18.0.0/16"
```

Verify:

```bash
docker exec nextcloud php occ config:app:get richdocuments wopi_allowlist
```

Expected output:

```
172.18.0.0/16
```

Without this setting Nextcloud responds with HTTP 403 and documents cannot be opened.

---

## Testing

Verify the service:

```
https://office.zircula.org
```

A successful installation returns a minimal page containing:

```
OK
```

This is expected.

It does **not** provide a user interface.

---

## Updating

Pull the configured image version:

```bash
docker compose pull
docker compose up -d
```

Verify container health:

```bash
docker logs collabora
```

---

## Security Notes

- No published Docker ports.
- Accessible only through Caddy.
- HTTPS handled exclusively by Caddy.
- WOPI restricted through Nextcloud allowlist.
- Nextcloud controls authentication and document permissions.

---

## Related Services

- Caddy
- Nextcloud
- Redis
- PostgreSQL
