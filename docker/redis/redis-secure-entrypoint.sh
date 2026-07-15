#!/bin/sh

set -eu

password="$(cat /run/secrets/redis_password)"

case "$password" in
  ''|*[!0-9a-f]*)
    echo >&2 "REDIS_PASSWORD must be a non-empty hexadecimal value."
    exit 1
    ;;
esac

umask 077
printf 'appendonly yes\nrequirepass %s\n' "$password" > /tmp/redis.conf
unset password

exec redis-server /tmp/redis.conf

