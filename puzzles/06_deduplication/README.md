# 06 — Deduplication: keep the latest version of every record

## Problem

`customers(record_id, customer_id, email, city, updated_at)` accumulates a new row
every time a source system re-sends a customer profile. Return exactly **one row
per `customer_id`**: the most recent version. Ties on `updated_at` (same batch)
resolve to the highest `record_id`.

## The trick

```sql
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY updated_at DESC, record_id DESC
) = 1
```

The pattern matters more than the puzzle: this is the standard "latest record"
idiom in every warehouse staging layer (dbt's dedup snippet is exactly this).
Details that separate a correct version from a flaky one:

- **`DISTINCT` cannot do this job.** It removes rows only when *every* column
  matches; two versions differing in one field both survive. `GROUP BY customer_id`
  with `MAX(...)` on each column is worse — it stitches together a Frankenstein row
  (newest email with oldest city) that never existed.
- **The tie-break is mandatory.** Customer 101 in the data has two versions with the
  same timestamp. Without `record_id DESC`, `ROW_NUMBER` picks nondeterministically —
  the query returns different answers run to run, which shows up as phantom diffs in
  dbt CI.
- `ROW_NUMBER`, not `RANK`: with ties you want exactly one row, and RANK=1 would
  return both tied versions.

## Alternatives considered

- Correlated `WHERE updated_at = (SELECT MAX ...)`: still returns both rows on ties;
  needs a second tie-break subquery.
- DuckDB/Snowflake `MAX_BY(col, updated_at)` per column: same Frankenstein risk on
  ties unless the ordering key is made unique first.

## Snowflake notes

Identical, `QUALIFY` included.
