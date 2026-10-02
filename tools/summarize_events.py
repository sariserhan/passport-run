#!/usr/bin/env python3
"""Summarize bounded device-local observations; this is not population retention data."""
import argparse
import collections
import datetime
import json
import math
from pathlib import Path


def numeric(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value)


def summarize(events):
    valid = [event for event in events if isinstance(event, dict) and isinstance(event.get("event"), str)]
    counts = collections.Counter(event["event"] for event in valid)
    wrong_rows = collections.Counter(
        (str(event.get("mode", "unknown")), str(event.get("difficulty", "unknown")), int(event["row"]) + 1)
        for event in valid if event["event"] == "wrong_tile" and numeric(event.get("row")) and event["row"] >= 0
    )
    starts = {event["run_id"] for event in valid if event["event"] in ("run_started", "run_retried") and isinstance(event.get("run_id"), str)}
    terminals = {}
    for event in valid:
        if event["event"] in ("run_failed", "run_completed", "run_ended") and event.get("run_id") in starts:
            terminals[event["run_id"]] = event
    durations = [event["elapsed_ms"] / 1000 for event in terminals.values() if numeric(event.get("elapsed_ms")) and event["elapsed_ms"] >= 0]
    failed_scores = [event["score"] for event in valid if event["event"] == "run_failed" and numeric(event.get("score"))]
    daily_sessions = collections.defaultdict(set)
    for event in valid:
        if event["event"] == "session_started" and numeric(event.get("at")) and isinstance(event.get("session_id"), str):
            try:
                date = datetime.datetime.fromtimestamp(event["at"], datetime.timezone.utc).date().isoformat()
            except (ValueError, OSError, OverflowError):
                continue
            daily_sessions[date].add(event["session_id"])
    return {
        "scope": "Last 500 events on one device; missing or truncated starts are excluded from run durations. No population D1, revenue, or share conversion is inferred.",
        "events": len(valid),
        "counts": dict(sorted(counts.items())),
        "observed_run_starts": len(starts),
        "observed_terminal_runs_with_start": len(terminals),
        "mean_observed_run_seconds": round(sum(durations) / len(durations), 2) if durations else None,
        "mean_failed_run_tiles": round(sum(failed_scores) / len(failed_scores), 2) if failed_scores else None,
        "onboarding_observations": {key: counts[key] for key in ("tutorial_started", "tutorial_completed", "home_country_selected")},
        "retry_observations": counts["run_retried"],
        "difficulty_choices": dict(collections.Counter(event.get("difficulty", "unknown") for event in valid if event["event"] == "difficulty_selected")),
        "destination_choices": dict(collections.Counter(event.get("country", "unknown") for event in valid if event["event"] == "destination_selected")),
        "long_haul_choices": counts["long_haul_selected"],
        "sessions_by_utc_day": {date: len(sessions) for date, sessions in sorted(daily_sessions.items())},
        "wrong_row_distribution": [{"mode": mode, "difficulty": difficulty, "row": row, "failures": count} for (mode, difficulty, row), count in sorted(wrong_rows.items())],
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("events", type=Path, help="Path to profile.json.events from Godot user data")
    args = parser.parse_args()
    try:
        if args.events.stat().st_size > 524288:
            parser.error("Event log exceeds the expected 512 KiB limit")
        data = json.loads(args.events.read_text())
    except (OSError, ValueError) as error:
        parser.error(str(error))
    if not isinstance(data, list):
        parser.error("Expected an array of events")
    print(json.dumps(summarize(data), indent=2))


if __name__ == "__main__":
    main()
