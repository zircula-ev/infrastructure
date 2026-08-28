#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

if [[ ! -f .env ]]; then
  echo >&2 "FEHLER: docker/werkblatt/.env fehlt."
  exit 1
fi

if [[ "$(stat -c '%a' .env)" != "600" ]]; then
  echo >&2 "FEHLER: docker/werkblatt/.env benötigt Modus 600."
  exit 1
fi

required_secrets=(
  django_secret_key
  postgres_password
  oidc_client_secret
  pretix_api_token
  webdav_password
)

for name in "${required_secrets[@]}"; do
  path="secrets/${name}"
  if [[ ! -s "${path}" ]]; then
    echo >&2 "FEHLER: ${path} fehlt oder ist leer."
    exit 1
  fi
  if [[ "$(stat -c '%a' "${path}")" != "600" ]]; then
    echo >&2 "FEHLER: ${path} benötigt Modus 600."
    exit 1
  fi
done

set -a
source .env
set +a

required_configuration=(
  DJANGO_ALLOWED_HOSTS
  DJANGO_CSRF_TRUSTED_ORIGINS
  WERKBLATT_PUBLIC_BASE_URL
  WERKBLATT_DEFAULT_ORGANIZATION
  OIDC_DISCOVERY_URL
  OIDC_ISSUER
  OIDC_CLIENT_ID
  OIDC_ALLOWED_GROUPS
  PRETIX_ORGANIZER
  WEBDAV_BASE_URL
  WEBDAV_USERNAME
)

for name in "${required_configuration[@]}"; do
  value="${!name:-}"
  if [[ -z "${value}" || "${value}" == *CHANGE_ME* ]]; then
    echo >&2 "FEHLER: ${name} fehlt oder enthält noch einen Platzhalter."
    exit 1
  fi
done

for path in /srv/zircula/werkblatt/media /srv/zircula/werkblatt/postgres; do
  if [[ ! -d "${path}" ]]; then
    echo >&2 "FEHLER: Persistenzpfad fehlt: ${path}"
    exit 1
  fi
done

docker network inspect zircula_frontend >/dev/null
docker compose config --quiet

echo "Werkblatt-Preflight erfolgreich"
