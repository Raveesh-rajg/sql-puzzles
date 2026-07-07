# 04 — Top-N per group, with ties done honestly

## Problem

`sales(category, product, revenue)`. Return the **top 2 products by revenue in each
category**. If products tie at a rank inside the top 2, return all of them — a tie
for first place must not be broken arbitrarily.

## The trick

The choice of ranking function *is* the business logic:

- `ROW_NUMBER()` — exactly N rows, ties broken arbitrarily (or by your tie-break
  key). Wrong here: with laptop and phone tied for #1, one of them silently vanishes,
  and which one can change between runs unless the ORDER BY is fully deterministic.
- `RANK()` — ties share a rank, next rank *skips* (1, 1, 3). "Top 2" would return
  only the two tied leaders, excluding the actual second-best product.
- `DENSE_RANK()` — ties share a rank, no gaps (1, 1, 2). "Top 2 ranks" returns the
  tied leaders *and* the runner-up. That matches the requirement.

The planted data has exactly this tie, so the three functions give three different
answers — a good interview exercise is predicting all three before running them.

`QUALIFY` filters on the window function directly, avoiding the subquery wrapper.

## Alternatives considered

- Correlated subquery (`WHERE (SELECT COUNT(DISTINCT revenue) ... ) <= 2`):
  quadratic and unreadable; predates window functions.
- Snowflake `MAX_BY`/`ARRAY_AGG(...)[0:2]`: fine for top-1, awkward for tie
  semantics.

## Snowflake notes

Identical — `QUALIFY` and all three ranking functions behave the same.
