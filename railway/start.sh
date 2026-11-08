#!/bin/sh
set -eu
cd /yolorouter
CFG=configs/config.yaml
PORT="${PORT:-8080}"

# First run: let upstream generate config.yaml (random provider_master_key) and
# the SQLite database without opening any port.
if [ ! -f "$CFG" ]; then
  echo "railway: first boot, generating $CFG"
  yolorouter db:status >/dev/null
fi

# Set server.port (first "port:" under "server:") and server.external_url.
set_server() { # $1 port  $2 external_url
  awk -v p="$1" -v u="$2" '
    /^server:/ {s=1; print; next}
    /^[^ ]/ {s=0}
    s && /^ +port:/ && !pd {sub(/port:.*/, "port: " p); pd=1}
    s && /^ +external_url:/ && u != "-" {sub(/external_url:.*/, "external_url: \"" u "\"")}
    {print}' "$CFG" > "$CFG.tmp" && cat "$CFG.tmp" > "$CFG" && rm -f "$CFG.tmp"
  chmod 600 "$CFG"
}

EXT="-"
[ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ] && EXT="https://${RAILWAY_PUBLIC_DOMAIN}"
[ -n "${YOLOROUTER_EXTERNAL_URL:-}" ] && EXT="$YOLOROUTER_EXTERNAL_URL"

# Pre-create the first admin on a bootstrap port Railway never routes to.
if [ -n "${YOLOROUTER_ADMIN_PASSWORD:-}" ] && [ ! -f data/.railway-admin-created ]; then
  BP="$YOLOROUTER_BOOTSTRAP_PORT"
  set_server "$BP" "$EXT"
  yolorouter serve &
  BPID=$!
  i=0
  until wget -qO- "http://127.0.0.1:$BP/healthz" >/dev/null 2>&1; do
    i=$((i+1)); [ $i -gt 120 ] && { echo "railway: bootstrap server did not start" >&2; kill $BPID; exit 1; }
    sleep 0.5
  done
  STATE=$(wget -qO- "http://127.0.0.1:$BP/api/admin/auth/state" || true)
  case "$STATE" in
    *'"initialized":false'*)
      BODY=$(printf '{"username":"%s","password":"%s"}' "$YOLOROUTER_ADMIN_USERNAME" "$YOLOROUTER_ADMIN_PASSWORD")
      if wget -qO- --header "Content-Type: application/json" --post-data "$BODY" "http://127.0.0.1:$BP/api/admin/auth/setup" >/dev/null; then
        echo "railway: created admin account '$YOLOROUTER_ADMIN_USERNAME' (password = YOLOROUTER_ADMIN_PASSWORD)"
        touch data/.railway-admin-created
      else
        echo "railway: admin setup failed (password needs 10-72 chars with letters and digits); the console will show the setup screen" >&2
      fi ;;
    *'"initialized":true'*) touch data/.railway-admin-created ;;
  esac
  kill $BPID 2>/dev/null || true
  wait $BPID 2>/dev/null || true
fi

set_server "$PORT" "$EXT"
exec yolorouter serve
