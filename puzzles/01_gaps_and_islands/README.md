# 01 — Longest login streak (gaps & islands)

## Problem

`logins(user_id, login_date)` records one row per app open — a user opening the app
twice in a day produces two rows. For each user, find their **longest streak of
consecutive calendar days** with at least one login, and when it started and ended.
If two streaks tie, return the earliest.

## The trick

Consecutive dates share a constant difference from a consecutive counter. Assign
`ROW_NUMBER()` ordered by date within each user: for a run of consecutive dates,
`login_date − row_number` is constant — that constant is the island id. Group by it.

The planted trap: **duplicate login days**. If you compute `ROW_NUMBER()` over raw
rows, a duplicated date increments the counter without incrementing the date, which
shears the island key mid-streak and splits one streak into two. Deduplicate to one
row per (user, day) *before* numbering. Carol's data in `setup.sql` has a duplicated
day for exactly this reason.

## Alternatives considered

- `LAG` + "gap > 1 day" flag + cumulative sum: same result, one extra window pass,
  but generalizes better when "consecutive" means something fuzzier (e.g., gaps of
  up to 2 days still count) — the flag condition absorbs the business rule.
- A recursive CTE walking day by day: correct, O(days) recursion depth, never worth
  it for this shape.

## Snowflake notes

Identical logic. `login_date - rn` becomes `DATEADD(day, -rn, login_date)`.
`QUALIFY` works in both engines.
