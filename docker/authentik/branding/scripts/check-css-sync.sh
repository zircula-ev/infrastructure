#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
branding_dir=$(CDPATH= cd -- "$script_dir/.." && pwd)
source_css="$branding_dir/css/authentik-custom.css"
blueprint="$branding_dir/../blueprints/werk-zircula-brand.yaml"
extracted_css=$(mktemp)

trap 'rm -f "$extracted_css"' EXIT HUP INT TERM

awk '
  /^      branding_custom_css: \|$/ {
    capture = 1
    next
  }
  /^      attributes:$/ {
    capture = 0
  }
  capture {
    sub(/^        /, "")
    print
  }
' "$blueprint" > "$extracted_css"

diff -u "$source_css" "$extracted_css"
printf '%s\n' "Branding CSS and Blueprint are in sync"
