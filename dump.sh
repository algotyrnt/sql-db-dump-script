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
cat > "$CRED_FILE" <<EOL
[client]
user=$REMOTE_USER
password=$REMOTE_PASSWORD
host=$REMOTE_HOST
port=$REMOTE_PORT
EOL

chmod 600 "$CRED_FILE"

# ============================================= Resolve tables (exclude views) =========================================
if [ -z "$TABLES_ARG" ]; then
  echo "Resolving base tables (excluding views)..."
  TABLES_ARG=$(docker run --rm \
    -v "$PWD/$CRED_FILE:/root/.my.cnf:ro" \
    mysql:8.0 \
    sh -c "mysql --defaults-file=/root/.my.cnf -N -e \
      \"SELECT table_name FROM information_schema.tables \
        WHERE table_schema='$REMOTE_DB' AND table_type='BASE TABLE';\"" \
    | tr '\n' ' ')

  if [ -z "$TABLES_ARG" ]; then
    echo "Error: Could not resolve table list"
    rm -f "$CRED_FILE"
    exit 1
  fi

  echo "Tables to dump: $TABLES_ARG"
fi

# =============================================== Dump DB with progress ================================================
echo "Creating a dump for database: $REMOTE_DB"

if [ -n "$SCHEMA_FLAG" ]; then
  echo "Mode: Schema Only"
else
  echo "Mode: Full Dump"
fi

docker run --rm \
  -v "$PWD:/dump" \
  -v "$PWD/$CRED_FILE:/root/.my.cnf:ro" \
  mysql:8.0 \
  sh -c "exec mysqldump --defaults-file=/root/.my.cnf \
    --single-transaction \
    --skip-lock-tables \
    --skip-triggers \
    --no-tablespaces \
    $SCHEMA_FLAG \
    $REMOTE_DB $TABLES_ARG" | pv > "$DUMP_FILE"

MYSQLDUMP_EXIT=${PIPESTATUS[0]}
if [ "$MYSQLDUMP_EXIT" -ne 0 ]; then
  echo "Error: mysqldump failed"
  rm -f "$CRED_FILE"
  exit 1
fi

# ================================================= Dump views =========================================================
echo "Dumping views..."

VIEWS=$(docker run --rm \
  -v "$PWD/$CRED_FILE:/root/.my.cnf:ro" \
  mysql:8.0 \
  sh -c "mysql --defaults-file=/root/.my.cnf -N -e \
    \"SELECT table_name FROM information_schema.tables \
      WHERE table_schema='$REMOTE_DB' AND table_type='VIEW';\"")

if [ -n "$VIEWS" ]; then
  for VIEW in $VIEWS; do
    SQL=$(docker run --rm \
      -v "$PWD/$CRED_FILE:/root/.my.cnf:ro" \
      mysql:8.0 \
      sh -c "mysql --defaults-file=/root/.my.cnf -N -e \
        \"SELECT view_definition FROM information_schema.views \
          WHERE table_schema='$REMOTE_DB' AND table_name='$VIEW';\"")

    echo "CREATE OR REPLACE VIEW \`$VIEW\` AS $SQL;" >> "$DUMP_FILE"
  done
  echo "Views dumped: $(echo "$VIEWS" | tr '\n' ' ')"
else
  echo "No views found"
fi

# Clean up credentials file
rm -f "$CRED_FILE"

echo "Dump completed: $DUMP_FILE"
