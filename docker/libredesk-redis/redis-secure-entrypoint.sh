#!/bin/sh

set -eu

password="$(cat /run/secrets/libredesk_redis_password)"

case "$password" in
  ''|*[!0-9a-fA-F]*)
    echo >&2 "LIBREDESK_REDIS_PASSWORD must be a non-empty hexadecimal value."
    exit 1
    ;;
esac

umask 077
printf '%s\n' \
  'appendonly yes' \
  'appendfsync everysec' \
  "requirepass ${password}" > /tmp/redis.conf
unset password

exec redis-server /tmp/redis.conf
