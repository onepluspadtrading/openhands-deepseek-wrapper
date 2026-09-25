# OpenHands Wrapper with proper permission handling for Railway
FROM ghcr.io/openhands/agent-canvas:latest

USER root

# Create the persistence directory and ensure proper ownership
RUN mkdir -p /home/openhands/.openhands && \
    chown -R openhands:openhands /home/openhands/.openhands && \
    chmod -R 755 /home/openhands/.openhands && \
    chown -R openhands:openhands /home/openhands

# Create an entrypoint wrapper that handles permissions and drops privileges
RUN cat > /entrypoint-wrapper.sh << 'EOFSCRIPT'
#!/bin/bash
set -e

# Fix permissions on the mounted volume (run as root)
if [ -d /home/openhands/.openhands ]; then
    chown -R openhands:openhands /home/openhands/.openhands
    chmod -R 755 /home/openhands/.openhands
fi

# Ensure the directory exists
mkdir -p /home/openhands/.openhands

# Drop to openhands user and run the original entrypoint
exec gosu openhands "$@"
EOFSCRIPT

chmod +x /entrypoint-wrapper.sh

# Install gosu for proper privilege dropping
RUN apt-get update && \
    apt-get install -y --no-install-recommends gosu && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set the wrapper as the entrypoint
ENTRYPOINT ["/entrypoint-wrapper.sh"]

# The CMD from the base image will be passed as arguments to our wrapper
CMD ["python", "-m", "openhands.automation.app"]
