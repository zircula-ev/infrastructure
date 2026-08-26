#!/usr/bin/env bash

set -Eeuo pipefail

data_directory='/srv/zircula/elasticsearch'
network='zircula_search'
minimum_map_count=1048576
minimum_available_kib=4194304

test -f .env || {
  echo 'FEHLER: .env fehlt'
  exit 1
}

test -d "$data_directory" || {
  echo "FEHLER: Datenverzeichnis fehlt: $data_directory"
  exit 1
}

owner="$(
  stat -c '%u:%g' "$data_directory"
)"

test "$owner" = '1000:0' || {
  echo "FEHLER: Erwarteter Eigentümer 1000:0, ermittelt: $owner"
  exit 1
}

mode="$(
  stat -c '%a' "$data_directory"
)"

test "$mode" = '770' || {
  echo "FEHLER: Erwarteter Modus 770, ermittelt: $mode"
  exit 1
}

actual_map_count="$(
  sysctl -n vm.max_map_count
)"

test "$actual_map_count" -ge "$minimum_map_count" || {
  echo "FEHLER: vm.max_map_count ist zu klein: $actual_map_count"
  exit 1
}

docker network inspect "$network" >/dev/null 2>&1 || {
  echo "FEHLER: Docker-Netz fehlt: $network"
  exit 1
}

internal="$(
  docker network inspect     --format '{{.Internal}}'     "$network"
)"

test "$internal" = 'true' || {
  echo "FEHLER: $network ist nicht als internes Netz angelegt"
  exit 1
}

available_kib="$(
  awk '/^MemAvailable:/ {print $2}' /proc/meminfo
)"

test "$available_kib" -ge "$minimum_available_kib" || {
  echo "FEHLER: Weniger als 4 GiB Arbeitsspeicher verfügbar"
  exit 1
}

docker compose config --quiet

echo 'Elasticsearch-Preflight erfolgreich'
