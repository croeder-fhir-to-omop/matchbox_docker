#!/usr/bin/env bash
# Check the matchbox server health endpoint.

BASE="${MATCHBOX_URL:-http://localhost:8080}"
curl -sS "$BASE/matchboxv3/actuator/health" | python3 -m json.tool
