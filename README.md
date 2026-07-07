# SQL Puzzles — a study guide with runnable proofs

Eight genuinely hard SQL problems, each with a schema, sample data, a verified
solution, and a written explanation of the approach and its alternatives. Every
solution executes against DuckDB in CI (`python harness.py`) and is checked against
an expected result — nothing here is pseudocode. Snowflake portability notes are
included where syntax differs.

## Why DuckDB as the runner

The puzzles are about SQL patterns, not vendor features. DuckDB runs anywhere with
zero setup (`pip install duckdb`), supports modern SQL (window frames, `QUALIFY`,
recursive CTEs), and makes the repo verifiable by CI on every commit. Each README
notes the Snowflake dialect differences — usually just `DATEADD`/`DATEDIFF` and
interval syntax.

## The puzzles

| # | Puzzle | Core pattern | The trap it teaches |
|---|--------|--------------|---------------------|
| 01 | Longest login streak | Gaps & islands (`date − row_number()`) | Duplicate rows silently break the island key |
| 02 | Sessionization | `LAG` + cumulative flag sum | Sessions are defined by gaps, not fixed windows |
| 03 | Running balance & moving average | Window frames | `ROWS` vs `RANGE`, and missing dates corrupting "7-day" averages |
| 04 | Top-N per group | `DENSE_RANK` + `QUALIFY` | `ROW_NUMBER` silently drops tied winners |
| 05 | Org chart rollups | Recursive CTE | Depth ≠ path; cycle protection |
| 06 | Record deduplication | `ROW_NUMBER` over business key | `DISTINCT` can't dedup when *any* column differs |
| 07 | Pivot & unpivot | Conditional aggregation | Portable pivots vs vendor `PIVOT` syntax |
| 08 | Query optimization | Pre-aggregation before join | Reading `EXPLAIN`, join-input sizes, measured before/after |

## Run everything

```bash
pip install duckdb
python harness.py            # runs all puzzles, checks outputs, ~10s
python harness.py 03         # run a single puzzle
```

Each puzzle directory contains:

```
puzzles/NN_name/
├── README.md      # problem statement, approach, alternatives, Snowflake notes
├── setup.sql      # schema + sample data (crafted to include the edge cases)
├── solution.sql   # the verified solution
└── expected.csv   # what the harness asserts against
```

Puzzle 08 is script-based (`benchmark.py`): it generates a 5M-row fact table,
runs the naive and optimized versions, verifies both return identical results, and
writes the `EXPLAIN` plans and timings to `results/`.

## How to study with this repo

Read the problem statement in each puzzle's README, write your own solution against
`setup.sql` before opening `solution.sql`, then diff your approach against the
explanation. The sample data in every puzzle deliberately contains the edge case
that breaks the obvious first attempt — if your query passes, you handled it.
