#!/usr/bin/env bash
# Recompute the "📊 Progress Tracking" block in concepts/README.md from the
# concept table itself (written = linked rows, read/revised = ✅ marks).
# Usage:  ./scripts/progress.sh        (rewrites the block in place)
#         ./scripts/progress.sh --check (prints counts, does not edit)
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readme="$here/../concepts/README.md"

python3 - "$readme" "${1:-}" <<'PY'
import re, sys
path, flag = sys.argv[1], (sys.argv[2] if len(sys.argv) > 2 else "")
lines = open(path, encoding="utf-8").read().split("\n")

# --- find the concept table: rows between "## Concepts" and the next "## " ---
start = next(i for i, l in enumerate(lines) if l.strip() == "## Concepts")
end = next((i for i in range(start + 1, len(lines)) if lines[i].startswith("## ")), len(lines))

total = written = read = revised = 0
for l in lines[start:end]:
    if not l.startswith("|"):
        continue
    cells = [c.strip() for c in l.strip().strip("|").split("|")]
    if len(cells) != 5:                       # skip malformed / non-data rows
        continue
    section, concept, r, v, _last = cells
    if concept in ("Concept", "") or set(concept) <= set("-: "):  # header/separator
        continue
    total += 1
    if "](" in concept:                       # a link → written
        written += 1
    if r == "✅":
        read += 1
    if v == "✅":
        revised += 1

def pct(n):
    return round(100 * n / total) if total else 0

backlog = total - written
completed = read  # "completed" = read at least once (first pass done)

if flag == "--check":
    print(f"total={total} written={written} ({pct(written)}%) "
          f"read={read} ({pct(read)}%) revised={revised} ({pct(revised)}%)")
    sys.exit(0)

block = [
    "",
    f"Track your overall concepts: **{completed} / {total} completed ({pct(completed)}%)** *(read + revised)*",
    "",
    f"- **Written:** {written} / {total} — **{pct(written)}%** *({backlog} in backlog — the `*(todo)*` rows)*",
    f"- **Read:** {read} / {total} — **{pct(read)}%**",
    f"- **Revised:** {revised} / {total} — **{pct(revised)}%**",
    "",
    "> Tick `☐ → ✅` in the table as you go; run `scripts/progress.sh` to refresh these counts.",
    "",
]

# --- replace the block between the "## 📊 Progress Tracking" heading and the next "## " ---
h = next(i for i, l in enumerate(lines) if l.startswith("## ") and "Progress Tracking" in l)
nxt = next(i for i in range(h + 1, len(lines)) if lines[i].startswith("## "))
lines[h + 1:nxt] = block
open(path, "w", encoding="utf-8").write("\n".join(lines))
print(f"Updated: completed {completed}/{total} ({pct(completed)}%) · "
      f"written {written} · read {read} · revised {revised}")
PY
