#!/usr/bin/env bash
# Validate a FHIR resource against matchbox.
# Usage: ./validate.sh <resource.json> [profile-url]

BASE="${MATCHBOX_URL:-http://localhost:8080}/matchboxv3/fhir"
RESOURCE="${1:?Usage: $0 <resource.json> [profile-url]}"
PROFILE="${2:-}"

PROFILE_PARAM=""
if [[ -n "$PROFILE" ]]; then
  PROFILE_PARAM="?profile=$PROFILE"
fi

curl -sS -X POST "$BASE/\$validate$PROFILE_PARAM" \
  -H 'Content-Type: application/fhir+json' \
  -d "@$RESOURCE" | python3 -m json.tool
