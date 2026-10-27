#!/usr/bin/env bash
# Generates .env with a random secret (once) and starts SearXNG.
set -euo pipefail
cd "$(dirname "$0")"
[ -f .env ] || echo "SEARXNG_SECRET=$(openssl rand -hex 32)" > .env
docker compose up -d
echo "SearXNG running at http://localhost:8888"
