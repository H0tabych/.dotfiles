#!/usr/bin/env python3
"""Генератор конфигов MCP для агентов из ai/mcp-servers.toml (AI-CTX-3).

Только стандартная библиотека. Результат (ai/generated/*) коммитится.

    python3 ai/gen/gen.py          # перегенерировать
    python3 ai/gen/gen.py --check  # проверить схему и актуальность файлов

Форматы: claude.mcp.json — для `claude --mcp-config`. Другие агенты: aider не
поддерживает MCP; формат DeepSeek Harness не проверен (ПРОВЕРИТЬ) — не генерируется.
"""
import json
import sys
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "mcp-servers.toml"
OUT = ROOT / "generated"


def load() -> dict:
    servers = tomllib.loads(SRC.read_text(encoding="utf-8")).get("server", {})
    if not servers:
        sys.exit("gen.py: в mcp-servers.toml нет [server.*]")
    for name, s in servers.items():
        cmd = s.get("command")
        if not isinstance(cmd, str) or not cmd or "/" in cmd:
            sys.exit(f"gen.py: {name}: command — имя из PATH, не путь")
        args = s.get("args", [])
        if not isinstance(args, list) or not all(isinstance(a, str) for a in args):
            sys.exit(f"gen.py: {name}: args — список строк")
        if set(s) - {"command", "args"}:
            sys.exit(f"gen.py: {name}: неизвестные ключи {sorted(set(s) - {'command', 'args'})}")
    return servers


def render(servers: dict) -> dict[str, str]:
    claude = {
        "mcpServers": {
            n: {"type": "stdio", "command": s["command"], "args": s.get("args", [])}
            for n, s in servers.items()
        }
    }
    return {"claude.mcp.json": json.dumps(claude, indent=2, ensure_ascii=False) + "\n"}


def main() -> None:
    files = render(load())
    if "--check" in sys.argv[1:]:
        bad = [n for n, t in files.items()
               if not (OUT / n).exists() or (OUT / n).read_text(encoding="utf-8") != t]
        if bad:
            sys.exit(f"gen.py: устарели {bad} — перегенерируйте и закоммитьте")
        print("gen.py: ok")
        return
    OUT.mkdir(exist_ok=True)
    for n, t in files.items():
        (OUT / n).write_text(t, encoding="utf-8")
        print(f"записан ai/generated/{n}")


if __name__ == "__main__":
    main()
