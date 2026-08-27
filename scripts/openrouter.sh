#!/usr/bin/env bash
# Launch Claude Code against a free OpenRouter model.
#
#     ./scripts/openrouter.sh              # MiniMax M3 (default, works today)
#     ./scripts/openrouter.sh --glm        # GLM 5.2 (see the warning below)
#
# Reads OPENROUTER_API_KEY from .env. Affects this shell only.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

model="minimax"
if [ "${1:-}" = "--glm" ]; then
  model="glm"
  shift
elif [ "${1:-}" = "--minimax" ]; then
  shift
fi

if [ ! -f "$root/.env" ]; then
  echo "No .env found. Run:  cp .env.example .env   then put your key in it." >&2
  exit 1
fi

# shellcheck disable=SC1091
set -a; . "$root/.env"; set +a

if [ -z "${OPENROUTER_API_KEY:-}" ] || [ "$OPENROUTER_API_KEY" = "sk-or-v1-replace-me" ]; then
  echo "OPENROUTER_API_KEY is missing or still the placeholder in .env" >&2
  exit 1
fi

# The base URL is the API ROOT, not the messages endpoint. Claude Code appends
# /v1/messages itself. Setting this to .../api/v1 produces /api/v1/v1/messages
# and a 404 -- the single most common way this setup fails.
export ANTHROPIC_BASE_URL="https://openrouter.ai/api"
export ANTHROPIC_AUTH_TOKEN="$OPENROUTER_API_KEY"

# Must be blank, or Claude Code falls back to Anthropic auth and ignores the gateway.
export ANTHROPIC_API_KEY=""

if [ "$model" = "glm" ]; then
  # GLM is served at 256K on OpenRouter despite the 1M claim on its model page.
  id="z-ai/glm-5.2:free"
  export CLAUDE_CODE_MAX_CONTEXT_TOKENS="256000"
  echo "GLM 5.2 (free) -- single provider, heavily rate-limited. Expect 429s." >&2
else
  id="minimax/minimax-m3:free[1m]"
  unset CLAUDE_CODE_MAX_CONTEXT_TOKENS || true
  echo "MiniMax M3 (free) -- 1M context." >&2
fi

# Claude Code hardcodes the names opus/sonnet/haiku. Remap all of them onto one
# model so /model never lands on something OpenRouter cannot route.
export ANTHROPIC_MODEL="$id"
export ANTHROPIC_SMALL_FAST_MODEL="$id"
export ANTHROPIC_DEFAULT_OPUS_MODEL="$id"
export ANTHROPIC_DEFAULT_SONNET_MODEL="$id"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="$id"

echo "50 requests/day on a \$0 balance; 1000/day after a one-time \$10 top-up." >&2
exec claude "$@"
