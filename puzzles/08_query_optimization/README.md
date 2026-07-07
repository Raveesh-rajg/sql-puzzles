# 08 — Query optimization: pre-aggregate before you join

## Problem

A 5M-row `orders` fact joins a 50-row `stores` dimension to report revenue by
region. Two logically identical queries:

**Naive** — join first, aggregate after. The hash join processes all 5M rows, and
the aggregation groups 5M joined rows by a string column:

```sql
SELECT s.region, SUM(o.amount)
FROM orders o JOIN stores s ON o.store_id = s.store_id
GROUP BY s.region;
```

**Optimized** — aggregate to the join key first (5M → 50 rows), then join 50×50:

```sql
WITH per_store AS (
    SELECT store_id, SUM(amount) AS store_revenue
    FROM orders GROUP BY store_id
)
SELECT s.region, SUM(p.store_revenue)
FROM per_store p JOIN stores s ON p.store_id = s.store_id
GROUP BY s.region;
```

`benchmark.py` generates the data, verifies both return byte-identical results,
times both over several runs, and writes each `EXPLAIN` plan to `results/`.

## What the EXPLAIN plans show

In the naive plan the `HASH_GROUP_BY` sits **above** the join and receives ~5M rows;
in the optimized plan the `HASH_GROUP_BY` sits **below** the join and the join
receives 50. Row counts flowing between operators — not operator names — are the
first thing to read in any plan.

Honest caveat, measured rather than hidden: DuckDB's vectorized hash join is fast
enough that the gap here is real but modest (see `results/timings.txt` — numbers
vary by machine). The pattern matters most when the join is expensive: joins across
network boundaries, exploding fan-out joins (join *multiplies* rows before a
distinct-count), or MPP engines where the join shuffles data between nodes.

## The same idea in Snowflake

Aggregate-below-join is one instance of "make the expensive operator touch fewer
rows." The Snowflake-specific versions of the same principle:

- **Partition pruning**: filters on clustered/natural-order columns skip
  micro-partitions entirely — the fastest row is one never read. Keep predicates
  sargable: `WHERE order_date >= '2026-01-01'`, never `WHERE YEAR(order_date) = 2026`.
- **Fan-out control**: joining orders→items before counting distinct orders forces
  a 10x bigger DISTINCT; count first, join after — same shape as this puzzle.
- Reading `EXPLAIN`/Query Profile: look for partition counts scanned vs total, and
  "bytes spilled" — spilling means the working set outgrew the warehouse.
