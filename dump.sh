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
    echo "Mode: Full Database Dump"
else
    echo "Mode: Specific Tables ($TABLES_ARG)"
fi

docker run --rm \
  -v "$PWD:/dump" \
  -v "$PWD/$CRED_FILE:/root/.my.cnf:ro" \
  mysql:8.0 \
  sh -c "exec mysqldump --defaults-file=/root/.my.cnf \
    --single-transaction \
    --skip-lock-tables \
    --no-tablespaces \
    $REMOTE_DB $TABLES_ARG" | pv > "$DUMP_FILE"

if [ $? -ne 0 ]; then
  echo "Error dumping remote database"
  rm -f $CRED_FILE
  exit 1
fi

# Clean up credentials file
rm -f "$CRED_FILE"

echo "Dump completed: $DUMP_FILE"
