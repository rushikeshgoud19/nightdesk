#!/usr/bin/env bash
# Launch Claude Code against GLM 5.2 (free) via OpenRouter.
#
#     ./scripts/glm.sh
#
# Reads OPENROUTER_API_KEY from .env. Only affects this one shell session.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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

export ANTHROPIC_MODEL="z-ai/glm-5.2:free"
export ANTHROPIC_SMALL_FAST_MODEL="z-ai/glm-5.2:free"
export ANTHROPIC_DEFAULT_OPUS_MODEL="z-ai/glm-5.2:free"
export ANTHROPIC_DEFAULT_SONNET_MODEL="z-ai/glm-5.2:free"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="z-ai/glm-5.2:free"

# Must be blank, or Claude Code falls back to Anthropic auth and ignores the gateway.
export ANTHROPIC_API_KEY=""

echo "GLM 5.2 (free) via OpenRouter -- 50 requests/day on a \$0 balance."
exec claude "$@"
