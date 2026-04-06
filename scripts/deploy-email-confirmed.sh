#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
PROJECT_REF="elpxxgkgjyufuidnnevk"

if [[ -z "${SUPABASE_ACCESS_TOKEN:-}" ]]; then
  echo "No SUPABASE_ACCESS_TOKEN set."
  echo "Option A: npx supabase login"
  echo "Option B: create a token at https://supabase.com/dashboard/account/tokens then run:"
  echo "  export SUPABASE_ACCESS_TOKEN='your-token'"
  echo "  $0"
  exit 1
fi

exec npx --yes supabase functions deploy email-confirmed --project-ref "$PROJECT_REF" --no-verify-jwt
