#!/usr/bin/env bash

set -Eeuo pipefail

network='zircula_search'
endpoint='http://elasticsearch:9200'
template='nextcloud-single-node'
index='nextcloud'

test -r index-template.json || {
  echo 'FEHLER: index-template.json ist nicht lesbar'
  exit 1
}

docker network inspect "$network" >/dev/null

docker run --rm   --network "$network"   --volume "$PWD/index-template.json:/config/index-template.json:ro"   curlimages/curl:8.16.0   --fail   --silent   --show-error   --request PUT   --header 'Content-Type: application/json'   --data-binary @/config/index-template.json   "$endpoint/_index_template/$template"   >/dev/null

if docker run --rm   --network "$network"   curlimages/curl:8.16.0   --fail   --silent   --head   "$endpoint/$index"   >/dev/null 2>&1
then
  docker run --rm     --network "$network"     curlimages/curl:8.16.0     --fail     --silent     --show-error     --request PUT     --header 'Content-Type: application/json'     --data-binary '{"index":{"number_of_replicas":0}}'     "$endpoint/$index/_settings"     >/dev/null
fi

echo 'Nextcloud-Indexvorlage und vorhandener Index sind für einen Einzelknoten konfiguriert'
