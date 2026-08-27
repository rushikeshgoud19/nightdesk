# Launch Claude Code against a free OpenRouter model.
#
#     .\scripts\openrouter.ps1                  # MiniMax M3 (default, works today)
#     .\scripts\openrouter.ps1 -Model glm       # GLM 5.2 (see the warning below)
#
# Reads OPENROUTER_API_KEY from .env. Affects this shell only -- `claude` in any
# other terminal still uses your normal account.

param(
    [ValidateSet("minimax", "glm")]
    [string]$Model = "minimax",

    [Parameter(ValueFromRemainingArguments = $true)]
    $Rest
)

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
# and a 404 -- the single most common way this setup fails.
$env:ANTHROPIC_BASE_URL = "https://openrouter.ai/api"
$env:ANTHROPIC_AUTH_TOKEN = $key

# Must be blank, or Claude Code falls back to Anthropic auth and ignores the gateway.
$env:ANTHROPIC_API_KEY = ""

if ($Model -eq "glm") {
    # The [1m]-style suffix tells Claude Code the real context window. GLM is
    # served at 256K on OpenRouter despite the 1M claim on its model page, so
    # set the window explicitly instead.
    $id = "z-ai/glm-5.2:free"
    $env:CLAUDE_CODE_MAX_CONTEXT_TOKENS = "256000"
    Write-Host "GLM 5.2 (free) -- single provider, heavily rate-limited. Expect 429s." -ForegroundColor Yellow
}
else {
    $id = "minimax/minimax-m3:free[1m]"
    Remove-Item Env:\CLAUDE_CODE_MAX_CONTEXT_TOKENS -ErrorAction SilentlyContinue
    Write-Host "MiniMax M3 (free) -- 1M context." -ForegroundColor DarkGray
}

# Claude Code hardcodes the names opus/sonnet/haiku. Remap all of them onto one
# model so /model never lands on something OpenRouter cannot route.
$env:ANTHROPIC_MODEL = $id
$env:ANTHROPIC_SMALL_FAST_MODEL = $id
$env:ANTHROPIC_DEFAULT_OPUS_MODEL = $id
$env:ANTHROPIC_DEFAULT_SONNET_MODEL = $id
$env:ANTHROPIC_DEFAULT_HAIKU_MODEL = $id

Write-Host "50 requests/day on a `$0 balance; 1000/day after a one-time `$10 top-up." -ForegroundColor DarkGray
claude @Rest
