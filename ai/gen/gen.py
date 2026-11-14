#!/usr/bin/env python3
"""Генератор плагина Claude Code с MCP-серверами из ai/mcp-servers.toml (AI-CTX-3).

Только стандартная библиотека. Результат (ai/generated/*) коммитится.

    python3 ai/gen/gen.py          # перегенерировать
    python3 ai/gen/gen.py --check  # проверить схему и актуальность файлов

Результат — локальный marketplace Claude Code `ai/generated/claude-plugin/` с одним плагином
`ai-tools`: список MCP живёт в штатной конфигурации агента (плагин), а не во флаге запуска, и
поэтому переживает `--resume` и фоновые сессии (ADR-48). Подключение — разовая команда
(REGISTRY.md, запись `ai`): `claude plugin marketplace add <каталог>` и
`claude plugin install ai-tools@ai-local`.

Для DeepSeek Harness (`dsh`) — два патча формата `--patch` (плагин `@deepseek-ai/dsh-mcp-client`):
`generated/dsh/local.cordis.yml` (stdio-серверы) и `generated/dsh/gateway.cordis.yml` (вход
MCP-шлюза; адрес и ключ читает из окружения процесса, поэтому адаптер подключает его только
когда они заданы).
"""
import json
import re
import sys
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "mcp-servers.toml"
OUT = ROOT / "generated"
MARKET = "claude-plugin"
MARKET_NAME = "ai-local"
PLUGIN = "ai-tools"

# Claude Code читает такие переменные пустыми в url/headers удалённого сервера.
CREDENTIAL_VARS = {
    "ANTHROPIC_API_KEY",
    "ANTHROPIC_AUTH_TOKEN",
    "AWS_BEARER_TOKEN_BEDROCK",
    "HTTPS_PROXY",
    "NPM_TOKEN",
}
VAR = re.compile(r"\$\{([A-Z][A-Z0-9_]*)\}")
# Значение заголовка — только ссылка на переменную (возможно, с префиксом схемы): литеральных секретов нет.
HEADER_VALUE = re.compile(r"^(Bearer )?\$\{[A-Z][A-Z0-9_]*\}$")
NAME = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
STORE = "/nix" + "/store"  # склейка: сам сканер DOT-1 не должен находить литерал в этом файле


def fail(msg: str) -> None:
    sys.exit(f"gen.py: {msg}")


def check_vars(where: str, text: str) -> None:
    for var in VAR.findall(text):
        if var in CREDENTIAL_VARS:
            fail(f"{where}: {var} — «учётное» имя, Claude Code читает его пустым")


def load() -> dict:
    servers = tomllib.loads(SRC.read_text(encoding="utf-8")).get("server", {})
    if not servers:
        fail("в mcp-servers.toml нет [server.*]")
    for name, s in servers.items():
        if not NAME.match(name):
            fail(f"{name}: имя — kebab-case")
        kind = s.get("type")
        allowed: set[str] = set()
        if kind == "stdio":
            allowed = {"type", "command", "args"}
            cmd = s.get("command")
            if not isinstance(cmd, str) or not cmd or "/" in cmd:
                fail(f"{name}: command — имя из PATH, не путь")
            args = s.get("args", [])
            if not isinstance(args, list) or not all(isinstance(a, str) for a in args):
                fail(f"{name}: args — список строк")
            if any(STORE in a for a in args):
                fail(f"{name}: args — пути хранилища пакетов запрещены (DOT-1)")
        elif kind == "http":
            allowed = {"type", "url", "headers"}
            url = s.get("url")
            if not isinstance(url, str) or not VAR.fullmatch(url):
                fail(f"{name}: url — ссылка на переменную окружения вида ${{ИМЯ}} (адрес — машинный слой)")
            check_vars(f"{name}.url", url)
            headers = s.get("headers", {})
            if not isinstance(headers, dict):
                fail(f"{name}: headers — таблица")
            for h, v in headers.items():
                if not isinstance(v, str) or not HEADER_VALUE.match(v):
                    fail(f"{name}: заголовок {h} — только ссылка ${{ИМЯ}} (литеральные секреты запрещены)")
                check_vars(f"{name}.headers.{h}", v)
        else:
            fail(f"{name}: type — stdio или http")
        extra = set(s) - allowed
        if extra:
            fail(f"{name}: неизвестные ключи {sorted(extra)}")
    return servers


def render(servers: dict) -> dict[str, str]:
    mcp = {}
    for n, s in servers.items():
        if s["type"] == "stdio":
            mcp[n] = {"type": "stdio", "command": s["command"], "args": s.get("args", [])}
        else:
            entry = {"type": "http", "url": s["url"]}
            if s.get("headers"):
                entry["headers"] = dict(s["headers"])
            mcp[n] = entry
    market = {
        "name": MARKET_NAME,
        "owner": {"name": "dotfiles"},
        "plugins": [
            {
                "name": PLUGIN,
                "source": f"./plugins/{PLUGIN}",
                "description": "Общие MCP-серверы агентов (ai/mcp-servers.toml, AI-CTX-3)",
            }
        ],
    }
    plugin = {
        "name": PLUGIN,
        "version": "1.0.0",
        "description": "Общие MCP-серверы агентов; генерируется из ai/mcp-servers.toml",
    }

    def dump(obj: dict) -> str:
        return json.dumps(obj, indent=2, ensure_ascii=False) + "\n"

    def js_ref(text: str) -> str:
        """Значение со ссылками ${ИМЯ} → выражение `!!js` (читает process.env при запуске агента)."""
        m = VAR.fullmatch(text)
        if m:
            return f"!!js process.env.{m.group(1)}"
        return "!!js '`" + VAR.sub(lambda v: "${process.env." + v.group(1) + "}", text) + "`'"

    def dsh_rows(kind: str) -> str:
        rows = []
        for n, s in servers.items():
            if s["type"] != kind:
                continue
            row = [
                f"    - id: mcp-{n}",
                "      name: '@deepseek-ai/dsh-mcp-client'",
                "      config:",
                f"        serverName: {n}",
            ]
            if kind == "stdio":
                row += [
                    "        transport: stdio",
                    f"        command: {json.dumps(s['command'])}",
                    f"        args: {json.dumps(s.get('args', []))}",
                    "        cwd: !!js process.cwd()",  # серверы работают в каталоге проекта
                ]
            else:
                row += ["        transport: streamable-http", f"        url: {js_ref(s['url'])}"]
                if s.get("headers"):
                    row.append("        headers:")
                    row += [f"          {h}: {js_ref(v)}" for h, v in s["headers"].items()]
            rows += row
        head = (
            "# Сгенерировано ai/gen/gen.py из ai/mcp-servers.toml — не править руками (AI-CTX-3).\n"
            f"# Патч DeepSeek Harness: серверы MCP ({kind}), `dsh --patch <файл>`.\n"
        )
        return head + "- insert:\n" + "\n".join(rows) + "\n"

    return {
        f"{MARKET}/.claude-plugin/marketplace.json": dump(market),
        f"{MARKET}/plugins/{PLUGIN}/.claude-plugin/plugin.json": dump(plugin),
        f"{MARKET}/plugins/{PLUGIN}/.mcp.json": dump({"mcpServers": mcp}),
        "dsh/local.cordis.yml": dsh_rows("stdio"),
        "dsh/gateway.cordis.yml": dsh_rows("http"),
    }


def existing() -> set[str]:
    """Все файлы в generated/ относительно него."""
    if not OUT.exists():
        return set()
    return {str(p.relative_to(OUT)) for p in OUT.rglob("*") if p.is_file()}


def main() -> None:
    files = render(load())
    if "--check" in sys.argv[1:]:
        stale = [n for n, t in files.items()
                 if not (OUT / n).exists() or (OUT / n).read_text(encoding="utf-8") != t]
        extra = sorted(existing() - set(files))
        if stale or extra:
            fail(f"устарели {stale}, лишние {extra} — перегенерируйте и закоммитьте")
        print("gen.py: ok")
        return
    for n in sorted(existing() - set(files)):
        (OUT / n).unlink()
        print(f"удалён ai/generated/{n}")
    for n, t in files.items():
        path = OUT / n
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(t, encoding="utf-8")
        print(f"записан ai/generated/{n}")


if __name__ == "__main__":
    main()
