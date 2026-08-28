"""
Talk to Roblox Studio's MCP server over stdio, without an MCP client.

Studio ships an MCP proxy (StudioMCP.exe). Normally an agent reaches it by
registering the server and letting the harness manage the connection. This does
the same thing by hand -- spawn the proxy, do the JSON-RPC handshake, call a
tool -- which is useful when you need Studio access from a plain script, from CI,
or from a session where the MCP server was not registered at startup.

Requires Roblox Studio to be RUNNING with:
    Assistant Settings -> MCP Servers -> Enable Studio as MCP server

Usage:
    python tools/studio_mcp.py list
    python tools/studio_mcp.py call get_studio_state
    python tools/studio_mcp.py call search_game_tree '{"query": "Lobby"}'
    python tools/studio_mcp.py call execute_luau '{"code": "return #workspace:GetChildren()"}'

Tools do not appear immediately -- the proxy reports capabilities first and
registers Studio's tools once Studio attaches, so there is a deliberate wait
before the first tools/list.
"""

import json
import subprocess
import sys
import threading
import time
from pathlib import Path

VERSIONS = Path.home() / "AppData" / "Local" / "Roblox" / "Versions"
HANDSHAKE_WAIT = 2.0
TOOLS_WAIT = 5.0
CALL_TIMEOUT = 120.0


def find_proxy() -> Path:
    """Newest StudioMCP.exe. Studio updates land in a new version-* folder."""
    found = sorted(
        VERSIONS.glob("version-*/StudioMCP.exe"),
        key=lambda p: p.stat().st_mtime,
        reverse=True,
    )
    if not found:
        sys.exit(
            "StudioMCP.exe not found. Is Roblox Studio installed?\n"
            f"Looked under: {VERSIONS}"
        )
    return found[0]


class Studio:
    def __init__(self) -> None:
        self.proc = subprocess.Popen(
            [str(find_proxy())],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1,
        )
        self.lines: list[str] = []
        threading.Thread(target=self._read, daemon=True).start()
        self._handshake()

    def _read(self) -> None:
        for line in self.proc.stdout:  # type: ignore[union-attr]
            self.lines.append(line.rstrip())

    def _send(self, msg: dict) -> None:
        self.proc.stdin.write(json.dumps(msg) + "\n")  # type: ignore[union-attr]
        self.proc.stdin.flush()  # type: ignore[union-attr]

    def _await(self, msg_id: int, timeout: float) -> dict:
        deadline = time.time() + timeout
        needle = f'"id":{msg_id}'
        while time.time() < deadline:
            for line in self.lines:
                if needle in line:
                    try:
                        parsed = json.loads(line)
                    except json.JSONDecodeError:
                        continue
                    if parsed.get("id") == msg_id:
                        return parsed
            time.sleep(0.25)
        return {"error": {"message": f"timed out after {timeout}s waiting for id {msg_id}"}}

    def _handshake(self) -> None:
        self._send(
            {
                "jsonrpc": "2.0",
                "id": 1,
                "method": "initialize",
                "params": {
                    "protocolVersion": "2024-11-05",
                    "capabilities": {"tools": {}},
                    "clientInfo": {"name": "nightdesk-bridge", "version": "1"},
                },
            }
        )
        time.sleep(HANDSHAKE_WAIT)
        self._send({"jsonrpc": "2.0", "method": "notifications/initialized"})
        # Studio's tools register only after Studio attaches to this proxy.
        time.sleep(TOOLS_WAIT)

    def list_tools(self) -> list[dict]:
        self._send({"jsonrpc": "2.0", "id": 2, "method": "tools/list", "params": {}})
        return self._await(2, 20).get("result", {}).get("tools", [])

    def call(self, name: str, args: dict | None = None) -> dict:
        self._send(
            {
                "jsonrpc": "2.0",
                "id": 3,
                "method": "tools/call",
                "params": {"name": name, "arguments": args or {}},
            }
        )
        return self._await(3, CALL_TIMEOUT)

    def close(self) -> None:
        self.proc.terminate()


def main() -> None:
    if len(sys.argv) < 2:
        sys.exit(__doc__)

    studio = Studio()
    try:
        if sys.argv[1] == "list":
            tools = studio.list_tools()
            print(f"{len(tools)} tools")
            for tool in tools:
                desc = (tool.get("description") or "").split("\n")[0][:70]
                print(f"  {tool['name']:<28} {desc}")

        elif sys.argv[1] == "call":
            if len(sys.argv) < 3:
                sys.exit("usage: studio_mcp.py call <tool_name> [json_args]")
            args = json.loads(sys.argv[3]) if len(sys.argv) > 3 else {}
            result = studio.call(sys.argv[2], args)
            print(json.dumps(result, indent=2)[:6000])

        else:
            sys.exit(__doc__)
    finally:
        studio.close()


if __name__ == "__main__":
    main()
