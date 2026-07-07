"""Generate data, verify both queries agree, time them, dump EXPLAIN plans.

Run directly or via the repo harness. Exits non-zero if results differ.
"""

from __future__ import annotations

import pathlib
import statistics
import time

import duckdb

HERE = pathlib.Path(__file__).parent
RESULTS = HERE / "results"
RESULTS.mkdir(exist_ok=True)

N_ORDERS = 5_000_000
N_STORES = 50

NAIVE = """
SELECT s.region, SUM(o.amount) AS revenue
FROM orders o
JOIN stores s ON o.store_id = s.store_id
GROUP BY s.region
ORDER BY s.region
"""

OPTIMIZED = """
WITH per_store AS (
    SELECT store_id, SUM(amount) AS store_revenue
    FROM orders
    GROUP BY store_id
)
SELECT s.region, SUM(p.store_revenue) AS revenue
FROM per_store p
JOIN stores s ON p.store_id = s.store_id
GROUP BY s.region
ORDER BY s.region
"""


def timeit(con: duckdb.DuckDBPyConnection, sql: str, runs: int = 5) -> float:
    """Median wall time over `runs` executions (first run warms caches)."""
    con.execute(sql).fetchall()  # warm-up, not timed
    times = []
    for _ in range(runs):
        t0 = time.perf_counter()
        con.execute(sql).fetchall()
        times.append(time.perf_counter() - t0)
    return statistics.median(times)


def main() -> int:
    con = duckdb.connect()
    con.execute(f"""
        CREATE TABLE stores AS
        SELECT i AS store_id,
               'region_' || (i % 5) AS region
        FROM range({N_STORES}) t(i);

        CREATE TABLE orders AS
        SELECT (random() * {N_STORES - 1})::INTEGER AS store_id,
               (random() * 500)::DECIMAL(10,2)      AS amount
        FROM range({N_ORDERS});
    """)

    naive_rows = con.execute(NAIVE).fetchall()
    opt_rows = con.execute(OPTIMIZED).fetchall()
    if naive_rows != opt_rows:
        print("FAIL: queries disagree")
        print("naive:", naive_rows)
        print("optimized:", opt_rows)
        return 1
    print(f"results identical across {len(naive_rows)} regions")

    for name, sql in (("before", NAIVE), ("after", OPTIMIZED)):
        plan = con.execute(f"EXPLAIN {sql}").fetchall()
        (RESULTS / f"explain_{name}.txt").write_text(
            "\n".join(r[1] for r in plan)
        )

    t_naive = timeit(con, NAIVE)
    t_opt = timeit(con, OPTIMIZED)
    speedup = t_naive / t_opt if t_opt > 0 else float("inf")

    report = (
        f"rows in fact table : {N_ORDERS:,}\n"
        f"naive (join->agg)  : {t_naive * 1000:.1f} ms (median of 5)\n"
        f"optimized (agg->join): {t_opt * 1000:.1f} ms (median of 5)\n"
        f"speedup            : {speedup:.2f}x\n"
        "note: absolute numbers vary by machine; the EXPLAIN plans in this\n"
        "directory show WHY — compare rows flowing into the join in each plan.\n"
    )
    (RESULTS / "timings.txt").write_text(report)
    print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
