# OpenHands DeepSeek Wrapper

Custom Dockerfile wrapper for the OpenHands agent-canvas image with proper persistent volume handling for Railway deployments.

## Problem Solved

The official OpenHands image attempts to write to `/home/openhands/.openhands` for SQLite persistence. On Railway, mounted volumes have restricted permissions that prevented the container from writing to this path, causing `sqlite3.OperationalError: unable to open database file`.

## Solution

This wrapper:
- Uses the official OpenHands image as a base
- Runs a permission-fixing entrypoint as root during container startup
- Ensures `/home/openhands/.openhands` is owned by the `openhands` user with writable permissions (755)
- Safely drops privileges back to the `openhands` user before running the app
- Enables persistent storage on Railway volumes without permission errors

## How It Works

1. **Build time:** Dockerfile sets up an entrypoint wrapper script and installs `gosu`
2. **Runtime:** When the container starts:
   - Entrypoint runs as root
   - Fixes ownership of `/home/openhands/.openhands` to `openhands:openhands`
   - Sets permissions to 755 (owner read/write/execute, group and other read/execute)
   - Creates the directory if needed
   - Uses `gosu` to drop to the `openhands` user
   - Launches the OpenHands application
3. **Result:** The app runs as a non-root user but can write to the mounted volume

## Deployment on Railway

1. Create an openhands-deepseek service pointing to this repository
2. Mount a persistent volume to `/home/openhands/.openhands`
3. Set environment variables as needed:
   - `BASIC_AUTH_USER`
   - `BASIC_AUTH_PASSWORD`
   - `RUNTIME` (e.g., `bash`, `python`)
   - `LLM_MODEL` (e.g., `deepseek-chat`)
   - `LLM_API_KEY`
   - `LLM_BASE_URL`
   - `GITHUB_TOKEN`
   - `OH_PERSISTENCE_DIR` (defaults to `/home/openhands/.openhands`)
   - `FILE_STORE_PATH` (defaults to `/home/openhands/.openhands`)
   - `WORKSPACE_BASE` (defaults to `/home/openhands/.openhands`)

## Security

- The app runs as a non-root user (`openhands`) after startup
- Only the permission-fixing entrypoint runs as root
- Uses `gosu` instead of `sudo` for privilege dropping (more secure)
- No modifications to the official OpenHands image behavior

## Technical Details

- **Base Image:** `ghcr.io/openhands/agent-canvas:latest`
- **User:** openhands (uid 1000)
- **Privilege Dropping:** gosu (clean fork/exec without shell overhead)
- **Volume Mount:** `/home/openhands/.openhands` (persistent SQLite storage)
