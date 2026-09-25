FROM ghcr.io/openhands/agent-canvas:latest

USER root

# Install gosu for privilege dropping
RUN apt-get update && \
    apt-get install -y --no-install-recommends gosu && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create entrypoint wrapper
RUN cat > /entrypoint-wrapper.sh << 'EOFSCRIPT'
#!/bin/bash
set -e

# Fix permissions on mounted volume (run as root before dropping privileges)
if [ -d /home/openhands/.openhands ]; then
    chown -R openhands:openhands /home/openhands/.openhands 2>/dev/null || true
    chmod -R 755 /home/openhands/.openhands 2>/dev/null || true
fi

mkdir -p /home/openhands/.openhands 2>/dev/null || true

# Drop privileges and run as openhands user
exec gosu openhands "$@"
EOFSCRIPT

chmod +x /entrypoint-wrapper.sh

ENTRYPOINT ["/entrypoint-wrapper.sh"]
CMD ["python", "-m", "openhands.automation.app"]
