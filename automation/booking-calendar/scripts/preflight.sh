#!/usr/bin/env bash
set -Eeuo pipefail

app_dir='/opt/zircula/git/Zircula-Automation'
venv_python='/opt/zircula/venvs/booking-calendar/bin/python'
environment_file='/etc/zircula-booking-importer/environment'

id zircula-booking-importer >/dev/null
test -d "$app_dir/.git"
test -r "$app_dir/booking_importer.py"
test -r "$app_dir/requirements.txt"
test -x "$venv_python"
test -r "$environment_file"

for variable_name in IMAP_SERVER IMAP_USER IMAP_PASSWORD MYTURN_SENDER_DOMAINS COMMONSBOOKING_SENDER_DOMAINS CALDAV_USERNAME CALDAV_APP_PASSWORD CALDAV_CALENDAR_URL
do
  grep -Eq "^$variable_name=.+" "$environment_file" || {
    echo "Fehlende oder leere Variable: $variable_name"
    exit 1
  }
done

PYTHONPYCACHEPREFIX=/tmp/zircula-booking-pycache "$venv_python" -m py_compile "$app_dir/booking_importer.py" "$app_dir/calendar_sync.py" "$app_dir/parser.py" "$app_dir/parser_lastenrad.py"
echo "Booking-Calendar-Preflight erfolgreich"
