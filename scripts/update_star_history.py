#!/usr/bin/env python3
"""Render seven days of actual star totals from GitHub starred_at timestamps on stdin."""

from datetime import datetime, timedelta, timezone
from html import escape
from math import ceil, floor, log10
from pathlib import Path
import sys


def daily_totals(timestamps, today):
    days = [today - timedelta(days=6 - i) for i in range(7)]
    starred_days = [datetime.fromisoformat(t.replace("Z", "+00:00")).astimezone(timezone.utc).date()
                    for t in timestamps]
    return [(day, sum(starred <= day for starred in starred_days)) for day in days]


def curve(points):
    """Monotone cubic interpolation: round corners without overshooting daily totals."""
    slopes = [(b[1] - a[1]) / (b[0] - a[0]) for a, b in zip(points, points[1:])]
    tangents = [slopes[0]]
    for left, right in zip(slopes, slopes[1:]):
        tangents.append(0 if left * right <= 0 else 2 * left * right / (left + right))
    tangents.append(slopes[-1])
    parts = [f"M {points[0][0]:.2f},{points[0][1]:.2f}"]
    for i, (a, b) in enumerate(zip(points, points[1:])):
        dx = (b[0] - a[0]) / 3
        parts.append(f"C {a[0] + dx:.2f},{a[1] + tangents[i] * dx:.2f} "
                     f"{b[0] - dx:.2f},{b[1] - tangents[i + 1] * dx:.2f} {b[0]:.2f},{b[1]:.2f}")
    return " ".join(parts)


def render(totals, dark=False):
    ink, muted, grid, accent, background = (
        ("#e6edf3", "#919ba6", "#30363d", "#9bbbc1", "#0d1117") if dark else
        ("#24292f", "#656d76", "#d8dee4", "#507a82", "#ffffff")
    )
    left, right, top, bottom = 52, 764, 102, 254
    maximum = max(4, max(count for _, count in totals))
    magnitude = 10 ** floor(log10(maximum / 4))
    step = next(n * magnitude for n in (1, 2, 5, 10) if n * magnitude >= maximum / 4)
    step = max(1, step)
    ceiling = ceil(maximum / step) * step
    points = [(left + i * (right - left) / 6, bottom - count / ceiling * (bottom - top))
              for i, (_, count) in enumerate(totals)]
    path = curve(points)
    last_day, current = totals[-1]
    description = "; ".join(f"{day.isoformat()}: {count}" for day, count in totals)
    parts = [
        '<svg xmlns="http://www.w3.org/2000/svg" width="800" height="320" viewBox="0 0 800 320" role="img" aria-labelledby="title desc">',
        '<title id="title">MDear star history — last 7 days</title>',
        f'<desc id="desc">Daily cumulative totals of current GitHub stars, in UTC. {escape(description)}. Today is partial.</desc>',
        f'<rect width="800" height="320" fill="{background}"/>',
        '<g font-family="-apple-system,BlinkMacSystemFont,Segoe UI,Arial,sans-serif">',
        f'<text x="28" y="34" fill="{ink}" font-size="17" font-weight="600">Star history</text>',
        f'<text x="28" y="57" fill="{muted}" font-size="12">Last 7 days · Daily totals · UTC</text>',
        f'<text x="764" y="35" text-anchor="end" fill="{ink}" font-size="22" font-weight="600">{current} stars</text>',
    ]
    for value in range(0, ceiling + 1, step):
        y = bottom - value / ceiling * (bottom - top)
        parts.append(f'<path d="M {left},{y:.2f} H {right}" stroke="{grid}" stroke-width="0.7"/>')
        parts.append(f'<text x="{left - 12}" y="{y + 4:.2f}" text-anchor="end" fill="{muted}" font-size="11">{value}</text>')
    parts.append(f'<path d="{path}" fill="none" stroke="{accent}" stroke-width="2.5" stroke-linecap="round"/>')
    for (day, count), (x, y) in zip(totals, points):
        label = "Today" if day == last_day else day.strftime("%d %b")
        parts.append(f'<circle cx="{x:.2f}" cy="{y:.2f}" r="3" fill="{accent}"><title>{day.isoformat()}: {count} stars</title></circle>')
        parts.append(f'<text x="{x:.2f}" y="279" text-anchor="middle" fill="{muted}" font-size="11">{label}</text>')
    parts.append(f'<text x="28" y="307" fill="{muted}" font-size="10">GitHub · Updated {last_day.isoformat()} · Today is partial</text>')
    parts.append('</g></svg>\n')
    return "\n".join(parts)


def main():
    timestamps = [line.strip() for line in sys.stdin if line.strip()]
    totals = daily_totals(timestamps, datetime.now(timezone.utc).date())
    output = Path(__file__).resolve().parents[1] / "docs" / "images"
    output.mkdir(parents=True, exist_ok=True)
    for theme in ("light", "dark"):
        (output / f"star-history-{theme}.svg").write_text(render(totals, theme == "dark"), encoding="utf-8")


if __name__ == "__main__":
    main()
