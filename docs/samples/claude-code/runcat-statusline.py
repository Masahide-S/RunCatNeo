#!/usr/bin/env python3
"""
RunCat Neo — Claude Code statusLine sample.

Writes ~/.claude/runcat-usage.json shaped like:

    {
      "title": "Claude Code",
      "symbol": "staroflife",
      "metricsBarValue": "69%",
      "metrics": [
        {"title": "Model", "formattedValue": "Sonnet 4.5"},
        {"title": "5h", "formattedValue": "69%", "normalizedValue": 0.69},
        {"title": "7d", "formattedValue": "12%", "normalizedValue": 0.12}
      ],
      "lastUpdatedDate": "2026-07-18T10:11:15Z"
    }

Reads rate limit data from Claude app's plan-usage-history.json.
"""

import json
import os
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

OUT = Path(os.environ.get("RUNCAT_OUT_FILE", str(Path.home() / ".claude" / "runcat-usage.json")))


def format_duration(ms):
    """Format milliseconds to human-readable duration."""
    if ms is None:
        return None
    seconds = ms / 1000
    if seconds < 60:
        return f"{int(seconds)}s"
    minutes = seconds / 60
    if minutes < 60:
        return f"{int(minutes)}m"
    hours = minutes / 60
    return f"{hours:.1f}h"


try:
    payload = json.load(sys.stdin)
    if not isinstance(payload, dict):
        payload = {}
except Exception:
    payload = {}

# Extract data from payload
model = (payload.get("model") or {}).get("display_name") or "Claude Code"

# Read rate limits from Claude app's plan usage history
usage_file = Path.home() / "Library" / "Application Support" / "Claude" / "plan-usage-history.json"
five_hour_pct = None
seven_day_pct = None

try:
    with open(usage_file) as f:
        usage_data = json.load(f)
        if usage_data.get("samples"):
            # Get the most recent sample
            latest = usage_data["samples"][-1]
            usage = latest.get("u", {})
            five_hour_pct = usage.get("fh")  # five_hour percentage
            seven_day_pct = usage.get("sd")  # seven_day percentage
except Exception:
    pass  # If file doesn't exist or is unreadable, continue without rate limits

# Build metrics
metrics = [{"title": "Model", "formattedValue": model}]

# 5h rate limit
if five_hour_pct is not None:
    metrics.append({
        "title": "5h",
        "formattedValue": f"{five_hour_pct}%",
        "normalizedValue": round(five_hour_pct / 100, 4)
    })

# 7d rate limit
if seven_day_pct is not None:
    metrics.append({
        "title": "7d",
        "formattedValue": f"{seven_day_pct}%",
        "normalizedValue": round(seven_day_pct / 100, 4)
    })

# Build snapshot
snapshot = {
    "title": "Claude Code",
    "symbol": "staroflife",
    "metrics": metrics,
    "lastUpdatedDate": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
}

# Set metrics bar value to 5h rate limit
if five_hour_pct is not None:
    snapshot["metricsBarValue"] = f"{five_hour_pct}%"

OUT.parent.mkdir(parents=True, exist_ok=True)
fd, tmp = tempfile.mkstemp(prefix=".runcat-", dir=str(OUT.parent))
with os.fdopen(fd, "w", encoding="utf-8") as f:
    json.dump(snapshot, f, ensure_ascii=False)
os.replace(tmp, OUT)

print(model)
