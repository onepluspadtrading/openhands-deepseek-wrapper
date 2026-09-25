FROM ghcr.io/openhands/agent-canvas:latest
USER root
RUN apt-get update && apt-get install -y --no-install-recommends gosu && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /entrypoint && cat > /entrypoint/wrapper.sh << 'EOFEND'
#!/bin/bash
set -e
if [ -d /home/openhands/.openhands ]; then
  chown -R openhands:openhands /home/openhands/.openhands 2>/dev/null || true
  chmod -R 755 /home/openhands/.openhands 2>/dev/null || true
fi
mkdir -p /home/openhands/.openhands 2>/dev/null || true
exec gosu openhands "$@"
EOFEND
chmod +x /entrypoint/wrapper.sh
ENTRYPOINT ["/entrypoint/wrapper.sh"]
CMD ["python", "-m", "openhands.automation.app"]

