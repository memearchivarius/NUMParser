#!/usr/bin/env bash
set -euo pipefail

# Defaults
: "${PORT:=38888}"
: "${USE_PROXY:=false}"
: "${PROXY:=}"

APP_DIR="/app"
BIN="$APP_DIR/numparser"

cd "$APP_DIR"

# Prepare runtime tree in /app (binary resolves paths relative to its own dir)
mkdir -p "$APP_DIR/db" "$APP_DIR/public/releases"

# TMDB key file
if [ -n "${TMDB_KEY:-}" ]; then
  echo "$TMDB_KEY" > "$APP_DIR/tmdb.key"
elif [ ! -f "$APP_DIR/tmdb.key" ]; then
  echo "TMDB key is required. Provide TMDB_KEY env or mount $APP_DIR/tmdb.key" >&2
  exit 1
fi

# Ensure helper scripts are executable
chmod +x "$APP_DIR/copy.sh" "$APP_DIR/proxy.sh" || true

# Proxy mode
ARGS=("-p" "$PORT")
if [ -n "$PROXY" ]; then
  ARGS+=("--proxy" "$PROXY")
fi
if [ "${USE_PROXY,,}" = "true" ]; then
  ARGS+=("--useproxy")
fi

exec "$BIN" "${ARGS[@]}"


