# 07 — Pivot & unpivot, the portable way

## Problem

`monthly_sales(product, sales_month, amount)` is tall/tidy. Produce a wide report:
one row per product, one column per month (Jan–Mar 2026), missing months as **0,
not NULL**. Then know how to reverse it.

## The trick

Conditional aggregation — the pivot that works on every engine:

```sql
SELECT product,
       COALESCE(SUM(CASE WHEN sales_month = '2026-01' THEN amount END), 0) AS jan_2026,
       ...
GROUP BY product
```

Points that come up in review:

- **`SUM(CASE ...)`, and the CASE has no ELSE.** `CASE` without ELSE yields NULL,
  which `SUM` ignores. Writing `ELSE 0` also works for SUM but breaks the same
  pattern with `COUNT` (counts the zeros) and `AVG` (averages them in) — omitting
  ELSE is the habit that survives changing the aggregate.
- **The outer `COALESCE` handles fully-missing months** (gadget has no February):
  SUM over an empty set is NULL, and a revenue report with NULLs invites "is it
  missing data or zero sales?" questions.
- **Pivot columns are static.** SQL requires the column list at parse time. Dynamic
  months need templating (dbt's `dbt_utils.pivot` generates exactly this CASE
  pattern from a runtime column query) or the vendor pivot with dynamic syntax.

## Unpivoting back

Portable: one `SELECT product, '2026-01' AS sales_month, jan_2026 AS amount` per
column glued with `UNION ALL`. Vendor: `UNPIVOT` (DuckDB and Snowflake both have
it). Caveat when round-tripping: our pivot manufactured 0 for gadget's missing
February, so unpivoting yields a row that didn't exist originally — pivot with
COALESCE is lossy about "zero vs absent."

## Snowflake notes

`PIVOT` syntax exists (`SELECT * FROM src PIVOT(SUM(amount) FOR sales_month IN
('2026-01','2026-02','2026-03'))`) and since 2024 supports `ANY` for dynamic
columns. Conditional aggregation remains the readable default in dbt models.
