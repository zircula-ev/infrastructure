#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

readonly werkblatt_image="werkblatt:b0618d34ac97f2384bac59ef632cbaa4e7746429"
readonly expected_image_id="sha256:a01cd9ddc1f72b7bc4347047005a1c597b4af609e745cb6a039a6fee94bf0012"

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
  postgres_password_web
  postgres_password_db
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
  expected_uid=10001
  if [[ "${name}" == postgres_password_db ]]; then
    expected_uid=999
  fi
  if [[ "$(stat -c '%u' "${path}")" != "${expected_uid}" ]]; then
    echo >&2 "FEHLER: ${path} benötigt Eigentümer-UID ${expected_uid}."
    exit 1
  fi
done

env_value() {
  local name="$1" line value="" first last
  local matches=0

  while IFS= read -r line || [[ -n "${line}" ]]; do
    line="${line%$'\r'}"
    if [[ "${line}" == "${name}="* ]]; then
      matches="$((matches + 1))"
      value="${line#*=}"
    fi
  done <.env

  if [[ "${matches}" -ne 1 ]]; then
    return 1
  fi

  if [[ -n "${value}" ]]; then
    first="${value:0:1}"
    last="${value: -1}"
    if [[ "${#value}" -ge 2 && "${first}" == "${last}" && ( "${first}" == '"' || "${first}" == "'" ) ]]; then
      value="${value:1:${#value}-2}"
    fi
  fi

  printf '%s' "${value}"
}

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
  if ! value="$(env_value "${name}")"; then
    echo >&2 "FEHLER: ${name} fehlt oder ist mehrfach gesetzt."
    exit 1
  fi
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

actual_image_id="$(docker image inspect "${werkblatt_image}" --format '{{.Id}}')"
if [[ "${actual_image_id}" != "${expected_image_id}" ]]; then
  echo >&2 "FEHLER: Werkblatt-Image entspricht nicht dem validierten Phase-4a-Build."
  exit 1
fi

echo "Werkblatt-Preflight erfolgreich"
