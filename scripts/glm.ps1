# Launch Claude Code against GLM 5.2 (free) via OpenRouter.
#
#     .\scripts\glm.ps1
#
# Reads OPENROUTER_API_KEY from .env. Only affects this one shell session --
# your normal `claude` in any other terminal still uses your Anthropic account.

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $root ".env"

if (-not (Test-Path $envFile)) {
    Write-Host "No .env found. Run:  Copy-Item .env.example .env   then put your key in it." -ForegroundColor Yellow
    exit 1
}

$key = $null
foreach ($line in Get-Content $envFile) {
    if ($line -match '^\s*OPENROUTER_API_KEY\s*=\s*(.+)\s*$') {
        $key = $Matches[1].Trim().Trim('"').Trim("'")
    }
}

if (-not $key -or $key -eq "sk-or-v1-replace-me") {
    Write-Host "OPENROUTER_API_KEY is missing or still the placeholder in .env" -ForegroundColor Yellow
    exit 1
}

# The base URL is the API ROOT, not the messages endpoint. Claude Code appends
# /v1/messages itself. Setting this to .../api/v1 produces /api/v1/v1/messages
# and a 404 -- this is the single most common way this setup fails.
$env:ANTHROPIC_BASE_URL = "https://openrouter.ai/api"
$env:ANTHROPIC_AUTH_TOKEN = $key

# Claude Code hardcodes the names opus/sonnet/haiku. These remap all of them onto
# one model, so /model never lands on something OpenRouter cannot route.
$env:ANTHROPIC_MODEL = "z-ai/glm-5.2:free"
$env:ANTHROPIC_SMALL_FAST_MODEL = "z-ai/glm-5.2:free"
$env:ANTHROPIC_DEFAULT_OPUS_MODEL = "z-ai/glm-5.2:free"
$env:ANTHROPIC_DEFAULT_SONNET_MODEL = "z-ai/glm-5.2:free"
$env:ANTHROPIC_DEFAULT_HAIKU_MODEL = "z-ai/glm-5.2:free"

# Must be blank, or Claude Code falls back to Anthropic auth and ignores the gateway.
$env:ANTHROPIC_API_KEY = ""

Write-Host "GLM 5.2 (free) via OpenRouter -- 50 requests/day on a `$0 balance." -ForegroundColor DarkGray
claude @args
