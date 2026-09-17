#!/usr/bin/env python3
"""SQLite chunk store + cosine search (no sqlite-vec; portable single file)."""
from __future__ import annotations

import argparse
import json
import math
import sqlite3
import struct
import sys
from pathlib import Path
from typing import Iterable, List, Sequence, Tuple

SCHEMA = """
CREATE TABLE IF NOT EXISTS meta (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS chunks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  source TEXT NOT NULL,
  heading TEXT,
  content TEXT NOT NULL,
  embedding BLOB NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_chunks_source ON chunks(source);
"""


def pack_f32(vec: Sequence[float]) -> bytes:
    return struct.pack(f"{len(vec)}f", *vec)


def unpack_f32(blob: bytes) -> List[float]:
    n = len(blob) // 4
    return list(struct.unpack(f"{n}f", blob))


def cosine(a: Sequence[float], b: Sequence[float]) -> float:
    dot = sum(x * y for x, y in zip(a, b))
    na = math.sqrt(sum(x * x for x in a))
    nb = math.sqrt(sum(x * x for x in b))
    if na == 0 or nb == 0:
        return 0.0
    return dot / (na * nb)


def init_db(path: Path, model_id: str, dim: int) -> sqlite3.Connection:
    path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(path))
    conn.executescript(SCHEMA)
    conn.execute(
        "INSERT OR REPLACE INTO meta(key, value) VALUES (?, ?)",
        ("embed_model", model_id),
    )
    conn.execute(
        "INSERT OR REPLACE INTO meta(key, value) VALUES (?, ?)",
        ("embed_dim", str(dim)),
    )
    conn.commit()
    return conn


def cmd_init(args: argparse.Namespace) -> None:
    init_db(Path(args.db), args.model, args.dim)
    print(args.db)


def cmd_clear(args: argparse.Namespace) -> None:
    conn = sqlite3.connect(args.db)
    conn.execute("DELETE FROM chunks")
    conn.commit()
    conn.close()


def cmd_insert(args: argparse.Namespace) -> None:
    row = json.loads(sys.stdin.read())
    vec = row["embedding"]
    conn = sqlite3.connect(args.db)
    conn.execute(
        "INSERT INTO chunks(source, heading, content, embedding) VALUES (?, ?, ?, ?)",
        (row["source"], row.get("heading"), row["content"], pack_f32(vec)),
    )
    conn.commit()
    conn.close()


def cmd_search(args: argparse.Namespace) -> None:
    q = json.loads(sys.stdin.read())
    qvec = q["embedding"]
    conn = sqlite3.connect(args.db)
    rows = conn.execute("SELECT source, heading, content, embedding FROM chunks").fetchall()
    conn.close()
    scored: List[Tuple[float, str, str | None, str]] = []
    for source, heading, content, blob in rows:
        score = cosine(qvec, unpack_f32(blob))
        scored.append((score, source, heading, content))
    scored.sort(key=lambda x: x[0], reverse=True)
    out = []
    for score, source, heading, content in scored[: args.k]:
        out.append(
            {
                "score": score,
                "source": source,
                "heading": heading,
                "content": content,
            }
        )
    print(json.dumps(out, indent=2))


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--db", required=True)
    sub = p.add_subparsers(dest="cmd", required=True)

    s_init = sub.add_parser("init")
    s_init.add_argument("--model", default="bge-small-en-v1.5-Q4_K_M")
    s_init.add_argument("--dim", type=int, default=384)
    s_init.set_defaults(func=cmd_init)

    s_clear = sub.add_parser("clear")
    s_clear.set_defaults(func=cmd_clear)

    s_ins = sub.add_parser("insert")
    s_ins.set_defaults(func=cmd_insert)

    s_search = sub.add_parser("search")
    s_search.add_argument("-k", type=int, default=5)
    s_search.set_defaults(func=cmd_search)

    args = p.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
