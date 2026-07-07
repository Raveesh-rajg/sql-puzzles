WITH RECURSIVE
-- Traversal 1: root-down, for depth and path.
chain AS (
    SELECT emp_id, name, 1 AS depth, name AS path
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    SELECT e.emp_id, e.name, c.depth + 1, c.path || ' > ' || e.name
    FROM employees e
    JOIN chain c ON e.manager_id = c.emp_id
    -- cycle guard for untrusted data: AND c.path NOT LIKE '%' || e.name || '%'
),

-- Traversal 2: transitive closure (ancestor, descendant), for report counts.
closure AS (
    SELECT manager_id AS ancestor, emp_id AS descendant
    FROM employees
    WHERE manager_id IS NOT NULL

    UNION ALL

    SELECT cl.ancestor, e.emp_id
    FROM closure cl
    JOIN employees e ON e.manager_id = cl.descendant
)

SELECT
    c.name,
    c.depth,
    c.path,
    COALESCE(r.total_reports, 0) AS total_reports
FROM chain c
LEFT JOIN (
    SELECT ancestor, COUNT(*) AS total_reports
    FROM closure
    GROUP BY ancestor
) r ON r.ancestor = c.emp_id
ORDER BY c.path;
