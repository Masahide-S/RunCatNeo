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
        {"title": "5h", "formattedValue": "69% (~14:30)", "normalizedValue": 0.69},
        {"title": "7d", "formattedValue": "12% (~7/22 03:00)", "normalizedValue": 0.12}
      ],
      "lastUpdatedDate": "2026-07-18T10:11:15Z"
    }

Rate limit percentages come from Claude app's plan-usage-history.json. Reset
times come from the statusLine payload's `rate_limits` field, which requires
a recent enough Claude Code version — older versions omit it, and the "(~...)"
suffix is simply left off.
"""

import json
import os
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

OUT = Path(os.environ.get("RUNCAT_OUT_FILE", str(Path.home() / ".claude" / "runcat-usage.json")))


def format_reset(epoch_seconds):
    """Format a Unix epoch (seconds) into a short local reset time, e.g. "~14:30" or "~7/22 03:00"."""
    if epoch_seconds is None:
        return None
    now = datetime.now().astimezone()
    reset = datetime.fromtimestamp(epoch_seconds).astimezone()
    hm = reset.strftime("%H:%M")
    if reset.date() == now.date():
        return f"~{hm}"
    return f"~{reset.month}/{reset.day} {hm}"


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

# Reset times only come from the statusLine payload (plan-usage-history.json
# doesn't carry them). Requires a recent enough Claude Code version.
rate_limits = payload.get("rate_limits") or {}
five_hour_resets_at = (rate_limits.get("five_hour") or {}).get("resets_at")
seven_day_resets_at = (rate_limits.get("seven_day") or {}).get("resets_at")

# Build metrics
metrics = [{"title": "Model", "formattedValue": model}]

# 5h rate limit
if five_hour_pct is not None:
    reset = format_reset(five_hour_resets_at)
    formatted = f"{five_hour_pct}% ({reset})" if reset else f"{five_hour_pct}%"
    metrics.append({
        "title": "5h",
        "formattedValue": formatted,
        "normalizedValue": round(five_hour_pct / 100, 4)
    })

# 7d rate limit
if seven_day_pct is not None:
    reset = format_reset(seven_day_resets_at)
    formatted = f"{seven_day_pct}% ({reset})" if reset else f"{seven_day_pct}%"
    metrics.append({
        "title": "7d",
        "formattedValue": formatted,
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
