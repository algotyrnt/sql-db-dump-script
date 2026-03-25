#!/bin/bash

# ================================================= CONFIGURATION ======================================================
ENV_FILE=".env"
CRED_FILE="my.cnf"

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Configuration file '$ENV_FILE' not found!"
    echo "Please create a .env file with: REMOTE_HOST, REMOTE_PORT, REMOTE_USER, REMOTE_PASSWORD, REMOTE_DB, DUMP_FILE"
    exit 1
fi

# Load variables from .env
set -a
source "$ENV_FILE"
set +a

# Default fallback for tables (if empty, dump all)
TABLES_ARG="${TABLES_TO_DUMP:-}"

# Optional schema-only mode (no table data)
SCHEMA_ONLY_RAW="${DUMP_SCHEMA_ONLY:-false}"
SCHEMA_ONLY="$(echo "$SCHEMA_ONLY_RAW" | tr '[:upper:]' '[:lower:]')"

case "$SCHEMA_ONLY" in
  true|1|yes|y)
    SCHEMA_FLAG="--no-data"
    ;;
  false|0|no|n|"")
    SCHEMA_FLAG=""
    ;;
  *)
    echo "Error: Invalid DUMP_SCHEMA_ONLY value '$SCHEMA_ONLY_RAW'. Use true/false."
    exit 1
    ;;
esac

# ========================================= Create temporary credentials file ==========================================
cat > $CRED_FILE <<EOL
[client]
user=$REMOTE_USER
password=$REMOTE_PASSWORD
host=$REMOTE_HOST
port=$REMOTE_PORT
EOL

chmod 600 $CRED_FILE

# =============================================== Dump DB with progress ================================================
echo "Creating a dump for database: $REMOTE_DB"

if [ -z "$TABLES_ARG" ]; then
  if [ -n "$SCHEMA_FLAG" ]; then
    echo "Mode: Full Database Schema Only"
  else
    echo "Mode: Full Database Dump"
  fi
else
  if [ -n "$SCHEMA_FLAG" ]; then
    echo "Mode: Specific Tables Schema Only ($TABLES_ARG)"
  else
    echo "Mode: Specific Tables ($TABLES_ARG)"
  fi
fi

docker run --rm \
  -v "$PWD:/dump" \
  -v "$PWD/$CRED_FILE:/root/.my.cnf:ro" \
  mysql:8.0 \
  sh -c "exec mysqldump --defaults-file=/root/.my.cnf \
    --single-transaction \
    --skip-lock-tables \
    --no-tablespaces \
    $SCHEMA_FLAG \
    $REMOTE_DB $TABLES_ARG" | pv > "$DUMP_FILE"

if [ $? -ne 0 ]; then
  echo "Error dumping remote database"
  rm -f $CRED_FILE
  exit 1
fi

# Clean up credentials file
rm -f "$CRED_FILE"

echo "Dump completed: $DUMP_FILE"
