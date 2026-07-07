"""Test harness: runs every puzzle's setup + solution against DuckDB and
compares the result to expected.csv. Exit code 0 only if all pass.

Usage:
    python harness.py         # all puzzles
    python harness.py 03      # only puzzle 03
"""

from __future__ import annotations

import csv
import io
import pathlib
import subprocess
import sys

import duckdb

ROOT = pathlib.Path(__file__).parent
PUZZLES = ROOT / "puzzles"


def run_sql_puzzle(puzzle_dir: pathlib.Path) -> tuple[bool, str]:
    setup = (puzzle_dir / "setup.sql").read_text()
    solution = (puzzle_dir / "solution.sql").read_text()
    expected_path = puzzle_dir / "expected.csv"

    con = duckdb.connect()
    try:
        con.execute(setup)
        rel = con.sql(solution)
        got_cols = [c.lower() for c in rel.columns]
        got_rows = [[_norm(v) for v in row] for row in rel.fetchall()]
    finally:
        con.close()

    with open(expected_path, newline="") as f:
        reader = csv.reader(f)
        exp_cols = [c.lower() for c in next(reader)]
        exp_rows = [[cell for cell in row] for row in reader]

    if got_cols != exp_cols:
        return False, f"columns differ:\n  got      {got_cols}\n  expected {exp_cols}"
    got_str = [[str(v) for v in row] for row in got_rows]
    if got_str != exp_rows:
        buf = io.StringIO()
        buf.write("rows differ:\n")
        for i, (g, e) in enumerate(zip(got_str, exp_rows)):
            marker = "  " if g == e else "->"
            buf.write(f"{marker} row {i}: got {g} expected {e}\n")
        if len(got_str) != len(exp_rows):
            buf.write(f"row count: got {len(got_str)}, expected {len(exp_rows)}\n")
        return False, buf.getvalue()
    return True, f"{len(got_rows)} rows match"


def _norm(v):
    """Normalize DB values for CSV comparison."""
    if v is None:
        return ""
    if isinstance(v, float) and v == int(v):
        return int(v)
    if hasattr(v, "date") and callable(getattr(v, "date", None)):
        # datetime -> ISO seconds
        try:
            return v.isoformat(sep=" ", timespec="seconds")
        except TypeError:
            return v.isoformat()
    return v


def run_script_puzzle(puzzle_dir: pathlib.Path) -> tuple[bool, str]:
    proc = subprocess.run(
        [sys.executable, str(puzzle_dir / "benchmark.py")],
        capture_output=True, text=True, cwd=puzzle_dir,
    )
    ok = proc.returncode == 0
    tail = "\n".join(proc.stdout.strip().splitlines()[-6:])
    return ok, tail if ok else proc.stdout + proc.stderr


def main() -> int:
    only = sys.argv[1] if len(sys.argv) > 1 else None
    failures = 0
    for puzzle_dir in sorted(PUZZLES.iterdir()):
        if not puzzle_dir.is_dir():
            continue
        if only and not puzzle_dir.name.startswith(only):
            continue
        if (puzzle_dir / "benchmark.py").exists():
            ok, msg = run_script_puzzle(puzzle_dir)
        else:
            ok, msg = run_sql_puzzle(puzzle_dir)
        status = "PASS" if ok else "FAIL"
        print(f"[{status}] {puzzle_dir.name}: {msg.splitlines()[0] if ok else ''}")
        if not ok:
            print(msg)
            failures += 1
    print(f"\n{'ALL PASS' if failures == 0 else f'{failures} FAILURE(S)'}")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
