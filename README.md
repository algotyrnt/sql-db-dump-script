# Dockerized MySQL Dump Script

A Bash script to dump a remote MySQL database (or specific tables) using a Docker container. It facilitates secure dumping by loading credentials from an environment file and includes a real-time progress bar.

## Prerequisites

Ensure the following are installed on your host machine:

- [Docker](https://www.docker.com/) (Must be running)
- `pv` (Pipe Viewer) - Used for the progress bar.
  - **MacOS:** `brew install pv`
  - **Ubuntu/Debian:** `sudo apt install pv`
  - **CentOS/RHEL:** `sudo yum install pv`

## Setup

1.  **Clone this repository** (or download the script).

2.  **Create a `.env` file** in the same directory as the script. You can copy the template below:
    ```bash
    # .env
    REMOTE_HOST=your_db_host
    REMOTE_PORT=3306
    REMOTE_USER=your_db_user
    REMOTE_PASSWORD=your_db_password
    REMOTE_DB=your_database_name
    DUMP_FILE=dump.sql

    # Leave empty "" to dump the full DB, or add space-separated table names
    TABLES_TO_DUMP=""

    # true/false: when true, dump only schema (no table data)
    DUMP_SCHEMA_ONLY=false
    ```

## Usage

1.  **Make the script executable:**
    ```bash
    chmod +x dump.sh
    ```

2.  **Run the script:**
    ```bash
    bash dump.sh
    ```

**Note:** Always invoke with `bash dump.sh`, not `sh dump.sh`. The script uses Bash-specific features (`PIPESTATUS`, `[[ ]]`) that are not available in `sh`.

## Features

- **Secure Auth:** Loads credentials from `.env` and uses a temporary, restricted-permission configuration file to authenticate with MySQL (avoids CLI password warnings).
- **Dockerized:** Runs `mysqldump` (v8.0) via Docker. No local MySQL installation is required on the host machine.
- **Progress Bar:** Visual feedback via `pv` creates a progress bar for large database dumps.
- **Non-locking:** Uses `--single-transaction` and `--skip-lock-tables` to ensure the backup does not lock the database for other users.
- **Selective Dumping:** Option to dump specific tables or the entire database.
- **Schema-only Mode:** Set `DUMP_SCHEMA_ONLY=true` to export only table structure without data.
- **No Tablespaces:** Uses `--no-tablespaces` to avoid errors related to tablespace information (requires PROCESS privilege).
- **View Support:** Automatically detects and dumps views separately via `information_schema`, working around `SHOW VIEW` privilege restrictions.
- **Accurate Error Detection:** Captures `mysqldump`'s exit code correctly through the `pv` pipe, so dump failures are never silently ignored.

## Troubleshooting

- **"Error: Configuration file '.env' not found!"**: Ensure you have created the `.env` file in the same directory as the script.
- **Docker permission errors**: Ensure your user has permission to run Docker commands (e.g., `sudo usermod -aG docker $USER`).
- **Docker not found:** Install Docker and ensure the service is running.
- **Progress bar missing:** Install `pv`.
- **Permission errors:** Check script permissions (`chmod +x dump.sh`) and folder write permissions.
- **Dump errors:** Verify remote credentials, host, port, and database access.
- **`SHOW VIEW` denied:** The script handles this automatically by resolving views via `information_schema.views`. No `SHOW VIEW` privilege is required on the DB user.
- **`unknown condition` / `PIPESTATUS` errors:** You are running the script with `sh` instead of `bash`. Use `bash dump.sh`.
