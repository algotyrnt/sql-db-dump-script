# MySQL Remote Dump Script
This script allows to securely dump a remote MySQL database using Docker.

## What It Does
- Connects to a remote MySQL database.
- Creates a local `.sql` dump.
- Shows a progress bar while dumping.
- Automatically creates and removes a temporary credentials file.
- Skips tablespace info to avoid `PROCESS` privilege errors.

## Requirements
- `docker` installed and running.
- `pv` installed for progress bar:
  - macOS: `brew install pv`
  - Ubuntu: `sudo apt install pv`
- Remote MySQL credentials with read access.

## Configuration
Edit the script and update the configuration section:
```
REMOTE_HOST="your_db_host"        # Remote MySQL host
REMOTE_PORT="3306"                # Remote MySQL port
REMOTE_USER="your_user"           # MySQL username
REMOTE_PASSWORD="your_password"   # MySQL password
REMOTE_DB="your_database"         # Database to dump
DUMP_FILE="dump.sql"              # Output SQL dump file
CRED_FILE="my.cnf"                # Temporary credentials file
```

## Usage
- Make the script executable: `chmod +x dump.sh`
- Run the script: `./dump.sh`
- Dump is saved to `dump.sql` file.

## Notes
- `--no-tablespaces` avoids errors related to tablespaces (PROCESS privilege required).
- Ensure the output directory has write permission.
- The script uses Docker, so no local MySQL client installation is required.

## Troubleshooting
- Docker not found: Install and start Docker.
- Progress bar missing: Install pv.
- Permission errors: Check script permissions (chmod +x dump.sh) and folder write permissions.
- Dump errors: Verify remote credentials and database access.
