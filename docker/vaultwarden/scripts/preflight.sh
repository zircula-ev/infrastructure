#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."

test -f .env || {
  printf '%s\n' 'FEHLER: .env fehlt; zuerst .env.example kopieren und ausfüllen.' >&2
  exit 1
}

if grep -Eq 'CHANGE_ME|HIER_' .env; then
  printf '%s\n' 'FEHLER: .env enthält noch Platzhalter.' >&2
  exit 1
fi

mode="$(stat -c '%a' .env)"
test "$mode" = "600" || {
  printf 'FEHLER: .env hat Modus %s statt 600.\n' "$mode" >&2
  exit 1
}

test -d /srv/zircula/vaultwarden/data || {
  printf '%s\n' 'FEHLER: /srv/zircula/vaultwarden/data fehlt.' >&2
  exit 1
}

owner="$(stat -c '%u:%g' /srv/zircula/vaultwarden/data)"
test "$owner" = "1000:1000" || {
  printf 'FEHLER: Datenverzeichnis gehört %s statt 1000:1000.\n' "$owner" >&2
  exit 1
}

docker compose config --quiet
printf '%s\n' 'Vaultwarden-Preflight erfolgreich'
