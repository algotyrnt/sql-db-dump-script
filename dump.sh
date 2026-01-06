#!/bin/bash

# ================================================= CONFIGURATION ======================================================
REMOTE_HOST="remote_host"
REMOTE_PORT="remote_port"
REMOTE_USER="remote_user"
REMOTE_PASSWORD="remote_password"
REMOTE_DB="remote_db_name"
TABLES_TO_DUMP="table1 table2 table3"  # Leave empty to dump full DB
DUMP_FILE="dump.sql"
CRED_FILE="my.cnf"


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
echo "Dumping database..."

# Prepare tables argument
if [ -z "$TABLES_TO_DUMP" ]; then
    TABLES_ARG=""
    echo "Dumping full database: $REMOTE_DB"
else
    TABLES_ARG="$TABLES_TO_DUMP"
    echo "Dumping specific tables: $TABLES_TO_DUMP"
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
