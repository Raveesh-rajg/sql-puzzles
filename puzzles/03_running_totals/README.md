# 03 — Running balance & the ROWS/RANGE trap

## Problem

`transactions(txn_id, account_id, txn_date, amount)` — signed amounts. Produce a
statement per account: every transaction with the **running balance after it**, in
chronological order. Same-day transactions settle in `txn_id` order.

## The trick

A cumulative window sum — but the interesting part is the frame:

```sql
SUM(amount) OVER (
    PARTITION BY account_id
    ORDER BY txn_date, txn_id
    ROWS UNBOUNDED PRECEDING
)
```

The trap is what happens **without** `ROWS`. When you write `ORDER BY` in a window
and no frame, the default frame is `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT
ROW`. `RANGE` treats *peers* (rows tied on the ORDER BY keys) as one unit: if two
transactions share the same sort key, both get the balance *after both* — your
statement shows the same balance twice and the intermediate balance is unrecoverable.
Two defenses, and the solution uses both: make the ordering deterministic (`txn_id`
tie-break) and say `ROWS` explicitly.

Account B in `setup.sql` has two same-day transactions to make the failure
observable: run the solution with the frame clause deleted and `txn_id` removed from
ORDER BY, and rows 6 and 7 both show −100.

## Related pattern: moving averages over sparse dates

A "7-day moving average" as `ROWS BETWEEN 6 PRECEDING AND CURRENT ROW` is only
correct if every calendar day has exactly one row. With missing days it silently
becomes a "last 7 *observations*" average. Fixes: join to a calendar spine first
(`generate_series` / dbt's `date_spine`), or use `RANGE BETWEEN INTERVAL 6 DAY
PRECEDING AND CURRENT ROW` where supported. This is the mirror image of the main
trap — there `RANGE` was the bug, here it's the fix; the lesson is that frames are
a semantic choice, not boilerplate.

## Snowflake notes

Identical syntax; Snowflake also defaults to `RANGE ... CURRENT ROW` with the same
peer behavior, but does not support `RANGE` with interval bounds — use the calendar
spine there.
