#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sqlite3
import sys
import urllib.error
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from rag_db import cosine, unpack_f32


def discover_path(base: str) -> str:
    import urllib.request as ur

    for path in ("/v1/embeddings", "/embedding", "/embeddings"):
        try:
            req = ur.Request(
                f"{base}{path}",
                data=json.dumps({"input": "ping"}).encode(),
                headers={"Content-Type": "application/json"},
                method="POST",
            )
            with ur.urlopen(req, timeout=30) as resp:
                body = json.loads(resp.read().decode())
            if "data" in body:
                return path
        except (urllib.error.URLError, json.JSONDecodeError, KeyError):
            continue
    return "/v1/embeddings"


def embed(base: str, path: str, text: str) -> list[float]:
    req = urllib.request.Request(
        f"{base}{path}",
        data=json.dumps({"input": text}).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=120) as resp:
        return json.loads(resp.read().decode())["data"][0]["embedding"]


def search_db(db: Path, qvec: list[float], k: int) -> list[dict]:
    conn = sqlite3.connect(str(db))
    rows = conn.execute("SELECT source, heading, content, embedding FROM chunks").fetchall()
    conn.close()
    scored = []
    for source, heading, content, blob in rows:
        scored.append((cosine(qvec, unpack_f32(blob)), source, heading, content))
    scored.sort(key=lambda x: x[0], reverse=True)
    out = []
    for score, source, heading, content in scored[:k]:
        out.append({"score": score, "source": source, "heading": heading, "content": content})
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("question")
    ap.add_argument("--db", type=Path, required=True)
    ap.add_argument("--base", default="http://127.0.0.1:8081")
    ap.add_argument("-k", type=int, default=5)
    ap.add_argument("--chat", action="store_true")
    ap.add_argument("--chat-port", type=int, default=8080)
    ap.add_argument("--prompt", type=Path)
    args = ap.parse_args()

    base = args.base.rstrip("/")
    path = discover_path(base)
    qvec = embed(base, path, args.question)
    hits = search_db(args.db, qvec, args.k)

    if not args.chat:
        for h in hits:
            print(f"--- score={h['score']:.3f} source={h['source']} ---")
            if h.get("heading"):
                print(f"## {h['heading']}")
            print(h["content"][:4000])
            print()
        return

    system = (
        args.prompt.read_text(encoding="utf-8")
        if args.prompt and args.prompt.is_file()
        else "Answer only from context. Cite source paths."
    )
    context = "\n\n---\n\n".join(f"[{h['source']}]\n{h['content']}" for h in hits)
    messages = [
        {"role": "system", "content": system},
        {"role": "user", "content": f"Context:\n{context}\n\nQuestion: {args.question}"},
    ]
    req = urllib.request.Request(
        f"http://127.0.0.1:{args.chat_port}/v1/chat/completions",
        data=json.dumps({"messages": messages, "stream": False}).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=300) as resp:
        body = json.loads(resp.read().decode())
    print(body["choices"][0]["message"]["content"])


if __name__ == "__main__":
    main()
