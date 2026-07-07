# 05 — Org chart rollups (recursive CTEs)

## Problem

`employees(emp_id, name, manager_id)` — a self-referencing hierarchy with the CEO's
`manager_id` NULL. For every employee return: their **depth** (CEO = 1), the full
**management path** ("Dana > Alex > Priya"), and their **total report count** —
direct and indirect subordinates.

## The trick

Two different recursive traversals, because the two outputs walk the tree in
different directions:

1. **Root-down chain** for depth and path: anchor on the CEO, join children onto the
   growing result, carry `depth + 1` and `path || ' > ' || name` along.
2. **Transitive closure** for report counts: start from every direct
   (manager, employee) edge, then repeatedly extend each ancestor's set with its
   descendants' children. Counting rows of the closure grouped by ancestor gives
   total reports. Trying to compute subordinate counts inside the root-down pass is
   the classic dead end — that pass knows ancestors, not descendants.

## Production concerns

- **Cycles.** A bad `manager_id` edit creating a loop makes the recursion infinite.
  Engines cap recursion depth (Snowflake errors at 100 iterations by default), but
  the robust guard is refusing to extend a path that already contains the employee
  (`WHERE path NOT LIKE '%' || name || '%'`) — noted in the solution, omitted from
  the main query for clarity.
- **Closure size.** The closure has one row per (ancestor, descendant) pair — for
  deep, wide trees this is O(n·depth). Fine for org charts (thousands of rows),
  wrong tool for social graphs.

## Snowflake notes

Same `WITH RECURSIVE` syntax (Snowflake also offers `CONNECT BY` and the
`SYS_CONNECT_BY_PATH` function, which produces the path column in one pass —
vendor-locked but worth knowing it exists).
