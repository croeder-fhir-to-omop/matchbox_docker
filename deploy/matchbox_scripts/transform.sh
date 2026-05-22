#!/usr/bin/env bash
# Run a StructureMap $transform against the matchbox server.
# Usage: ./transform.sh <payload.json>

BASE="${MATCHBOX_URL:-http://localhost:8080}/matchboxv3/fhir"
PAYLOAD="${1:?Usage: $0 <payload.json>}"

curl -sS -X POST "$BASE/StructureMap/\$transform" \
  -H 'Content-Type: application/fhir+json' \
  -d "@$PAYLOAD" | python3 -m json.tool
