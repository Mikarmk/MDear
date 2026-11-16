import importlib.util
from datetime import date
from pathlib import Path
import unittest
from xml.etree import ElementTree


spec = importlib.util.spec_from_file_location(
    "star_history", Path(__file__).resolve().parents[1] / "scripts/update_star_history.py"
)
chart = importlib.util.module_from_spec(spec)
spec.loader.exec_module(chart)


class StarHistoryTests(unittest.TestCase):
    def test_recent_window_keeps_older_stars_in_the_total(self):
        totals = chart.daily_totals([
            "2026-08-25T06:12:41Z", "2026-11-15T23:59:59Z", "2026-11-16T00:00:00Z"
        ], date(2026, 11, 16))
        self.assertEqual(totals[0], (date(2026, 11, 10), 1))
        self.assertEqual(totals[-2], (date(2026, 11, 15), 2))
        self.assertEqual(totals[-1], (date(2026, 11, 16), 3))

    def test_dates_are_binned_in_utc(self):
        totals = chart.daily_totals(["2026-11-16T01:00:00+03:00"], date(2026, 11, 16))
        self.assertEqual(totals[-2][1], 1)

    def test_empty_history_and_year_boundary_render_in_both_themes(self):
        totals = chart.daily_totals([], date(2027, 1, 2))
        self.assertEqual(totals[0][0], date(2026, 12, 27))
        for dark in (False, True):
            svg = chart.render(totals, dark)
            root = ElementTree.fromstring(svg)
            self.assertNotIn("nan", svg.lower())
            self.assertIn("0 stars", svg)
            self.assertEqual(len(root.findall("{http://www.w3.org/2000/svg}g/{http://www.w3.org/2000/svg}circle")), 7)

    def test_smooth_curve_does_not_invent_an_early_rise(self):
        points = [(i * 100, 100 if i < 6 else 0) for i in range(7)]
        commands = chart.curve(points).split("C ")
        for segment in commands[1:-1]:
            self.assertTrue(all(float(p.split(",")[1]) == 100 for p in segment.split()))
        last = [tuple(map(float, p.split(","))) for p in commands[-1].split()]
        self.assertTrue(all(0 <= y <= 100 for _, y in last))
        self.assertEqual(last[-1], (600, 0))


if __name__ == "__main__":
    unittest.main()
