# MySQL Remote Dump Script

This script securely dumps a remote MySQL database using Docker, with a progress bar and automatic handling of credentials.

## Features

- Connects to a remote MySQL database.
- Creates a local `.sql` dump file.
- Supports dumping **specific tables** or the **full database**.
- Shows a progress bar while dumping.
- Automatically creates and removes a temporary credentials file.
- Skips tablespace info to avoid `PROCESS` privilege errors.

## Requirements

- [Docker](https://www.docker.com/get-started) installed and running.
- `pv` installed for progress bar:
  - macOS: `brew install pv`
  - Ubuntu/Debian: `sudo apt install pv`
- Remote MySQL credentials with read access.

## Configuration

Edit the script and update the configuration section:

\`\`\`bash
REMOTE_HOST="your_db_host" # Remote MySQL host
REMOTE_PORT="3306" # Remote MySQL port
REMOTE_USER="your_user" # MySQL username
REMOTE_PASSWORD="your_password" # MySQL password
REMOTE_DB="your_database" # Database to dump
TABLES_TO_DUMP="table1 table2" # Tables to dump (leave empty to dump full database)
DUMP_FILE="dump.sql" # Output SQL dump file
CRED_FILE="my.cnf" # Temporary credentials file
\`\`\`

## Usage

1. Make the script executable:
   \`\`\`bash
   chmod +x dump.sh
   \`\`\`
2. Run the script:
   \`\`\`bash
   ./dump.sh
   \`\`\`
3. The dump will be saved to `dump.sql`.
4. The script prints whether it is dumping the full database or specific tables.

## Notes

- `--no-tablespaces` avoids errors related to tablespaces (requires PROCESS privilege otherwise).
- Ensure the output directory is writable.
- Using Docker means you don’t need a local MySQL client installed.
- Temporary credentials file (`my.cnf`) is automatically deleted after the dump.

## Troubleshooting

- **Docker not found:** Install Docker and ensure the service is running.
- **Progress bar missing:** Install `pv`.
- **Permission errors:** Check script permissions (`chmod +x dump.sh`) and folder write permissions.
- **Dump errors:** Verify remote credentials, host, port, and database access.
