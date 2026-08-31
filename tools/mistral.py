"""
Call Mistral from the command line, and prove its tool-calling actually works.

Why this exists rather than "run Claude Code on Mistral": Claude Code speaks the
Anthropic Messages API and there is no supported way to swap the driving model.
Pointing ANTHROPIC_BASE_URL at a translating proxy is possible, and the long
agentic tool loop is exactly where it falls over. So Claude stays the driver and
Mistral is a tool it calls. That split is reliable, and it is what this is for.

Standard library only, on purpose. Nothing to install before a teammate runs it.

    python tools/mistral.py selftest
    python tools/mistral.py generate "twelve surnames for a 1980s motel ledger"
    python tools/mistral.py generate --json "six guest records: name, city, room"

The key is read from MISTRAL_API_KEY, or from a .env file at the repo root.
.env is gitignored. Never paste a key into a chat or a commit.
"""

import argparse
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

API_URL = "https://api.mistral.ai/v1/chat/completions"
DEFAULT_MODEL = "mistral-large-latest"
REPO_ROOT = Path(__file__).resolve().parent.parent
KEY_NAME = "MISTRAL_API_KEY"


def load_key() -> str:
    key = os.environ.get(KEY_NAME, "").strip()
    if key:
        return key

    env = REPO_ROOT / ".env"
    if env.is_file():
        for line in env.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line.startswith(KEY_NAME + "="):
                value = line.split("=", 1)[1].strip()
                return value.strip("'").strip('"')

    sys.exit(
        "No " + KEY_NAME + ".\n"
        "  Set the environment variable, or write it into .env at the repo root:\n"
        "      " + KEY_NAME + "=your-key-here\n"
        "  .env is gitignored. See .env.example."
    )


def call(messages: list, model: str, tools: list | None = None, temperature: float = 0.7) -> dict:
    body = {"model": model, "messages": messages, "temperature": temperature}
    if tools:
        body["tools"] = tools
        body["tool_choice"] = "auto"

    req = urllib.request.Request(
        API_URL,
        data=json.dumps(body).encode("utf-8"),
        headers={
            "Authorization": "Bearer " + load_key(),
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            return json.loads(r.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        detail = e.read().decode("utf-8", "replace")[:600]
        sys.exit(f"Mistral returned HTTP {e.code}\n{detail}")
    except urllib.error.URLError as e:
        sys.exit(f"Could not reach Mistral: {e.reason}")


# --------------------------------------------------------------------------- #
# generate
# --------------------------------------------------------------------------- #


def cmd_generate(args: argparse.Namespace) -> int:
    system = "You are a concise generator. Output only what was asked for, no preamble."
    if args.json:
        system += " Respond with valid JSON and nothing else."

    out = call(
        [
            {"role": "system", "content": system},
            {"role": "user", "content": args.prompt},
        ],
        model=args.model,
        temperature=args.temperature,
    )
    text = out["choices"][0]["message"]["content"]

    if args.json:
        # Fail loudly rather than handing malformed JSON to a caller.
        try:
            print(json.dumps(json.loads(text), indent=2))
        except json.JSONDecodeError:
            print(text, file=sys.stderr)
            print("\nModel did not return valid JSON.", file=sys.stderr)
            return 1
    else:
        print(text)
    return 0


# --------------------------------------------------------------------------- #
# selftest -- a real two-turn tool loop, not a claim that one would work
# --------------------------------------------------------------------------- #

SELFTEST_TOOL = {
    "type": "function",
    "function": {
        "name": "lookup_room_status",
        "description": "Look up whether a motel room is currently occupied.",
        "parameters": {
            "type": "object",
            "properties": {
                "room_number": {
                    "type": "integer",
                    "description": "Room number, 101 to 108.",
                }
            },
            "required": ["room_number"],
        },
    },
}


def cmd_selftest(args: argparse.Namespace) -> int:
    expected = SELFTEST_TOOL["function"]["name"]
    print("model: " + args.model)
    messages = [
        {
            "role": "user",
            "content": "Is room 104 occupied? Use the tool, then answer in one short sentence.",
        }
    ]

    print("\n[1/3] asking for a tool call ...")
    first = call(messages, model=args.model, tools=[SELFTEST_TOOL], temperature=0)
    msg = first["choices"][0]["message"]
    calls = msg.get("tool_calls") or []

    if not calls:
        print("  FAIL  model returned no tool_calls")
        print("  content: " + repr(msg.get("content")))
        return 1

    tc = calls[0]
    name = tc["function"]["name"]
    raw_args = tc["function"]["arguments"]
    print("  OK    tool_call: " + name + "(" + str(raw_args) + ")")

    if name != expected:
        print("  FAIL  wrong tool name, expected " + expected)
        return 1

    print("\n[2/3] checking the arguments parse and are correct ...")
    try:
        parsed = raw_args if isinstance(raw_args, dict) else json.loads(raw_args)
    except json.JSONDecodeError as e:
        print("  FAIL  arguments are not valid JSON: " + str(e))
        return 1
    if parsed.get("room_number") != 104:
        print("  FAIL  expected room_number 104, got " + repr(parsed.get("room_number")))
        return 1
    print("  OK    parsed " + str(parsed))

    print("\n[3/3] feeding the result back for a final answer ...")
    messages.append(msg)
    messages.append(
        {
            "role": "tool",
            "name": name,
            "tool_call_id": tc["id"],
            "content": json.dumps({"room_number": 104, "occupied": True, "guest": "Vance, H."}),
        }
    )
    second = call(messages, model=args.model, tools=[SELFTEST_TOOL], temperature=0)
    final = (second["choices"][0]["message"].get("content") or "").strip()
    if not final:
        print("  FAIL  no final content after the tool result")
        return 1
    print("  OK    " + final)

    print("\nPASS - Mistral does tool calling: it requested the tool, sent well-formed")
    print("       arguments, and used the result. Safe to call from Claude Code as a")
    print("       tool. Still not a substitute for Claude as the driving model.")
    return 0


def main() -> int:
    p = argparse.ArgumentParser(prog="mistral", description="Call Mistral, and test its tool calling.")
    p.add_argument("--model", default=DEFAULT_MODEL, help="default " + DEFAULT_MODEL)
    sub = p.add_subparsers(dest="cmd", required=True)

    g = sub.add_parser("generate", help="generate text")
    g.add_argument("prompt")
    g.add_argument("--json", action="store_true", help="demand valid JSON back")
    g.add_argument("--temperature", type=float, default=0.7)
    g.set_defaults(func=cmd_generate)

    s = sub.add_parser("selftest", help="prove tool calling works end to end")
    s.set_defaults(func=cmd_selftest)

    args = p.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
