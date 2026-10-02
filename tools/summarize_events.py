#!/usr/bin/env python3
"""Summarize the bounded, device-local Passport Run event log (not a retention dashboard)."""
import argparse
import collections
import json
from pathlib import Path


def summarize(events):
    valid = [e for e in events if isinstance(e, dict) and isinstance(e.get("event"), str)]
    counts = collections.Counter(e["event"] for e in valid)
    failures = [e for e in valid if e["event"] == "run_failed"]
    wrong_rows = collections.Counter(
        (str(e.get("mode", "unknown")), int(e.get("row", 0)) + 1)
        for e in valid if e["event"] == "wrong_tile" and isinstance(e.get("row"), (int, float))
    )
    scores = [int(e["score"]) for e in failures if isinstance(e.get("score"), (int, float))]
    return {
        "scope": "Last 500 local events only; no population retention or verified rankings.",
        "events": len(valid),
        "counts": dict(sorted(counts.items())),
        "mean_failed_run_tiles": round(sum(scores) / len(scores), 2) if scores else None,
        "wrong_row_distribution": [
            {"mode": mode, "row": row, "failures": count}
            for (mode, row), count in sorted(wrong_rows.items())
        ],
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("events", type=Path, help="Path to profile.json.events from Godot user data")
    args = parser.parse_args()
    if args.events.stat().st_size > 524288:
        parser.error("Event log exceeds the expected 512 KiB limit")
    try:
        data = json.loads(args.events.read_text())
    except (OSError, ValueError) as error:
        parser.error(str(error))
    if not isinstance(data, list):
        parser.error("Expected an array of events")
    print(json.dumps(summarize(data), indent=2))


if __name__ == "__main__":
    main()
