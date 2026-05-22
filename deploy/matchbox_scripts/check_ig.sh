#!/usr/bin/env bash
# Check which Implementation Guides are loaded on the running matchbox server.

BASE="${MATCHBOX_URL:-http://localhost:8080}/matchboxv3/fhir"
FILTER="${1:-}"

if [[ -n "$FILTER" ]]; then
  curl -sS -X GET "$BASE/ImplementationGuide?_content=$FILTER" \
    -H 'accept: application/fhir+json' | python3 -m json.tool
else
  curl -sS -X GET "$BASE/ImplementationGuide" \
    -H 'accept: application/fhir+json' | python3 -m json.tool
fi
