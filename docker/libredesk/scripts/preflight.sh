#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

if [[ ! -f .env ]]; then
  echo >&2 "FEHLER: docker/libredesk/.env fehlt."
  exit 1
fi

if [[ ! -r config.toml ]]; then
  echo >&2 "FEHLER: docker/libredesk/config.toml fehlt oder ist nicht lesbar."
  exit 1
fi

config_mode="$(stat -c '%a' config.toml)"
if [[ "$config_mode" != "644" ]]; then
  echo >&2 "FEHLER: docker/libredesk/config.toml benötigt Modus 644 (aktuell: ${config_mode})."
  exit 1
fi

set -a
source .env
set +a

required=(
  LIBREDESK_DOMAIN
  LIBREDESK_APP_ENCRYPTION_KEY
  LIBREDESK_DB_NAME
  LIBREDESK_DB_USER
  LIBREDESK_DB_PASSWORD
  LIBREDESK_REDIS_PASSWORD
)

for name in "${required[@]}"; do
  value="${!name:-}"
  if [[ -z "$value" || "$value" == *CHANGE_ME* ]]; then
    echo >&2 "FEHLER: ${name} fehlt oder enthält noch einen Platzhalter."
    exit 1
  fi
done

if [[ ! "$LIBREDESK_APP_ENCRYPTION_KEY" =~ ^[0-9a-fA-F]{32}$ ]]; then
  echo >&2 "FEHLER: LIBREDESK_APP_ENCRYPTION_KEY muss genau 32 Hex-Zeichen enthalten."
  exit 1
fi

for name in LIBREDESK_DB_PASSWORD LIBREDESK_REDIS_PASSWORD; do
  value="${!name}"
  if [[ ! "$value" =~ ^[0-9a-fA-F]{32,}$ ]]; then
    echo >&2 "FEHLER: ${name} muss ein Hex-Secret mit mindestens 32 Zeichen sein."
    exit 1
  fi
done

for network in zircula_frontend zircula_backend; do
  docker network inspect "$network" >/dev/null
done

test -d /srv/zircula/libredesk/uploads
test -w /srv/zircula/libredesk/uploads
docker compose config --quiet

echo "LibreDesk-Preflight erfolgreich"
