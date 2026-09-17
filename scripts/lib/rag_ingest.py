#!/usr/bin/env python3
"""Embed corpus chunks via llamafile HTTP API and write knowledge.db."""
from __future__ import annotations

import argparse
import json
import sys
import urllib.error
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from chunk_corpus import chunk_file, iter_files
from rag_db import init_db, pack_f32


def discover_path(base: str) -> str:
    for path in ("/v1/embeddings", "/embedding", "/embeddings"):
        try:
            req = urllib.request.Request(
                f"{base}{path}",
                data=json.dumps({"input": "ping"}).encode(),
                headers={"Content-Type": "application/json"},
                method="POST",
            )
            with urllib.request.urlopen(req, timeout=30) as resp:
                body = json.loads(resp.read().decode())
            if "data" in body:
                return path
        except (urllib.error.URLError, json.JSONDecodeError, KeyError):
            continue
    return "/v1/embeddings"


def embed(base: str, path: str, text: str) -> list[float]:
    attempt = text
    for _ in range(4):
        payload = json.dumps({"input": attempt}).encode()
        req = urllib.request.Request(
            f"{base}{path}",
            data=payload,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                body = json.loads(resp.read().decode())
            return body["data"][0]["embedding"]
        except urllib.error.HTTPError as e:
            if e.code != 400 or len(attempt) < 200:
                raise
            attempt = attempt[: max(200, len(attempt) // 2)]
    raise RuntimeError("embedding failed after truncation retries")


def wait_server(base: str, tries: int) -> None:
    import time

    for _ in range(tries):
        for suffix in ("/health", "/v1/models"):
            try:
                urllib.request.urlopen(f"{base}{suffix}", timeout=2)
                return
            except urllib.error.URLError:
                pass
        time.sleep(1)
    raise SystemExit(f"Embedding server not reachable at {base}")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--corpus", type=Path, required=True)
    ap.add_argument("--db", type=Path, required=True)
    ap.add_argument("--base", default="http://127.0.0.1:8081")
    ap.add_argument("--overlap", type=int, default=200)
    ap.add_argument("--limit-files", type=int, default=0)
    ap.add_argument("--model", default="bge-small-en-v1.5-Q4_K_M")
    ap.add_argument("--wait", type=int, default=60)
    args = ap.parse_args()

    wait_server(args.base, args.wait)
    embed_path = discover_path(args.base.rstrip("/"))
    print(f"Embed endpoint: {args.base}{embed_path}", file=sys.stderr)

    conn = init_db(args.db, args.model, 384)
    conn.execute("DELETE FROM chunks")
    conn.commit()

    files = iter_files(args.corpus)
    if args.limit_files > 0:
        files = files[: args.limit_files]

    count = 0
    for path in files:
        for ch in chunk_file(path, args.corpus, args.overlap):
            vec = embed(args.base.rstrip("/"), embed_path, ch["content"])
            conn.execute(
                "INSERT INTO chunks(source, heading, content, embedding) VALUES (?, ?, ?, ?)",
                (ch["source"], ch.get("heading"), ch["content"], pack_f32(vec)),
            )
            count += 1
            if count % 20 == 0:
                print(f"Indexed {count} chunks...", file=sys.stderr)
    conn.commit()
    conn.close()
    print(f"Done. {count} chunks -> {args.db}")


if __name__ == "__main__":
    main()
