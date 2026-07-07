-- DENSE_RANK: tied leaders share rank 1, runner-up gets rank 2 (no gap),
-- so "top 2 ranks" keeps ties AND the true second-best.
SELECT
    category,
    product,
    revenue,
    DENSE_RANK() OVER (
        PARTITION BY category ORDER BY revenue DESC
    ) AS revenue_rank
FROM sales
QUALIFY revenue_rank <= 2
ORDER BY category, revenue DESC, product;
