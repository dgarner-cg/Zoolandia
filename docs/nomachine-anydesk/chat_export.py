#!/usr/bin/env python3
"""Convert a Claude Code session transcript (.jsonl) into a readable log."""
import json, sys

src, dst = sys.argv[1], sys.argv[2]
out = []

def render_content(content):
    parts = []
    if isinstance(content, str):
        return [content] if content.strip() else []
    for block in content:
        if not isinstance(block, dict):
            continue
        bt = block.get("type")
        if bt == "text":
            txt = block.get("text", "").strip()
            if txt:
                parts.append(txt)
        elif bt == "thinking":
            txt = block.get("thinking", "").strip()
            if txt:
                parts.append(f"[thinking]\n{txt}")
        elif bt == "tool_use":
            name = block.get("name", "?")
            inp = json.dumps(block.get("input", {}), indent=2)
            parts.append(f"[tool call: {name}]\n{inp}")
        elif bt == "tool_result":
            c = block.get("content", "")
            if isinstance(c, list):
                c = "\n".join(
                    b.get("text", "") for b in c if isinstance(b, dict)
                )
            parts.append(f"[tool result]\n{c}")
    return parts

for line in open(src):
    line = line.strip()
    if not line:
        continue
    o = json.loads(line)
    if o.get("type") not in ("user", "assistant"):
        continue
    msg = o.get("message", {})
    role = msg.get("role", o.get("type"))
    rendered = render_content(msg.get("content", ""))
    if not rendered:
        continue
    out.append("=" * 78)
    out.append(role.upper())
    out.append("=" * 78)
    out.extend(rendered)
    out.append("")

with open(dst, "w") as f:
    f.write("\n".join(out))
print(f"Wrote {len(out)} lines to {dst}")
