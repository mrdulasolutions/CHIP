#!/usr/bin/env python3
"""Split markdown/text under corpus by ## headings with overlap."""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

SKIP_NAMES = {".fetched", ".gitkeep"}
SKIP_SUFFIX = {".pdf"}
# Stay under llamafile embed ubatch (~512 tokens default); sub-split long sections
# bge-small embed server defaults to 512-token slots; keep chunks well under that
MAX_CHUNK_CHARS = 700


def iter_files(corpus: Path) -> list[Path]:
    out: list[Path] = []
    for p in sorted(corpus.rglob("*")):
        if not p.is_file():
            continue
        if p.name in SKIP_NAMES or p.name.startswith("."):
            continue
        if p.suffix.lower() in {".md", ".txt"}:
            out.append(p)
    return out


def split_long(text: str, max_chars: int) -> list[str]:
    if len(text) <= max_chars:
        return [text]
    parts: list[str] = []
    start = 0
    while start < len(text):
        end = min(start + max_chars, len(text))
        if end < len(text):
            cut = text.rfind("\n\n", start, end)
            if cut <= start:
                cut = text.rfind(" ", start, end)
            if cut > start:
                end = cut
        parts.append(text[start:end].strip())
        start = max(end - 200, end) if end < len(text) else end
    return [p for p in parts if p]


def chunk_file(path: Path, corpus: Path, overlap: int) -> list[dict]:
    rel = path.relative_to(corpus).as_posix()
    text = path.read_text(encoding="utf-8", errors="replace")
    parts = re.split(r"(?m)^##\s+", text)
    chunks: list[dict] = []
    if len(parts) == 1:
        body = parts[0].strip()
        if body:
            full = f"# {rel}\n\n{body}"
            subs = split_long(full, MAX_CHUNK_CHARS)
            for sub_i, sub in enumerate(subs):
                h = f"part {sub_i + 1}" if len(subs) > 1 else None
                chunks.append({"source": rel, "heading": h, "content": sub})
        return chunks

    preamble = parts[0].strip()
    for i, section in enumerate(parts[1:], start=1):
        lines = section.splitlines()
        heading = lines[0].strip() if lines else f"section-{i}"
        body = "\n".join(lines[1:]).strip()
        header = f"# {rel}\n## {heading}\n\n"
        piece = header + body
        if preamble and i == 1:
            piece = f"# {rel}\n\n{preamble}\n\n## {heading}\n\n{body}"
        if overlap > 0 and len(piece) > overlap * 4:
            # tail overlap from previous chunk stored in content prefix
            pass
        subs = split_long(piece, MAX_CHUNK_CHARS)
        for sub_i, sub in enumerate(subs):
            suffix = f" (part {sub_i + 1})" if len(subs) > 1 else ""
            chunks.append(
                {
                    "source": rel,
                    "heading": (heading or "") + suffix if suffix else heading,
                    "content": sub,
                }
            )

    # Add overlap: prepend tail of previous chunk
    if overlap > 0 and len(chunks) > 1:
        merged = [chunks[0]]
        for c in chunks[1:]:
            prev = merged[-1]["content"]
            tail = prev[-overlap:] if len(prev) > overlap else prev
            c = dict(c)
            c["content"] = f"...{tail}\n\n{c['content']}"
            merged.append(c)
        chunks = merged
    # Overlap can push past the embed limit; enforce cap again
    final: list[dict] = []
    for c in chunks:
        for sub_i, sub in enumerate(split_long(c["content"], MAX_CHUNK_CHARS)):
            suffix = f" (part {sub_i + 1})" if sub_i else ""
            final.append(
                {
                    "source": c["source"],
                    "heading": (c.get("heading") or "") + suffix if suffix else c.get("heading"),
                    "content": sub,
                }
            )
    return final


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("corpus", type=Path)
    ap.add_argument("--overlap", type=int, default=200)
    ap.add_argument("--limit-files", type=int, default=0, help="0 = all")
    args = ap.parse_args()
    files = iter_files(args.corpus)
    if args.limit_files > 0:
        files = files[: args.limit_files]
    for path in files:
        for ch in chunk_file(path, args.corpus, args.overlap):
            print(json.dumps(ch, ensure_ascii=False))


if __name__ == "__main__":
    main()
