#!/bin/bash

# ============================================================== CONFIGURATION ==============================================================
REMOTE_HOST="remote_host"
REMOTE_PORT="remote_port"
REMOTE_USER="remote_user"
REMOTE_PASSWORD="remote_password"
REMOTE_DB="remote_db_name"
DUMP_FILE="dump.sql"

# ==================================================== Create temporary credentials file =====================================================
cat > $CRED_FILE <<EOL
[client]
user=$REMOTE_USER
password=$REMOTE_PASSWORD
host=$REMOTE_HOST
port=$REMOTE_PORT
EOL

chmod 600 $CRED_FILE

# ========================================================== Dump DB with progress ============================================================
echo "Dumping database..."
docker run --rm \
  -v "$PWD:/dump" \
  -v "$PWD/$CRED_FILE:/root/.my.cnf:ro" \
  --entrypoint sh \
  mysql:8.0 \
  -c "exec mysqldump --defaults-file=/root/.my.cnf $REMOTE_DB" | pv > "$DUMP_FILE"

if [ $? -ne 0 ]; then
  echo "Error dumping remote database"
  rm -f $CRED_FILE
  exit 1
fi

echo "Dump completed: $DUMP_FILE"

# Add --no-tablespaces to mysqldump so it skips tablespace info (avoids PROCESS privilege error).
