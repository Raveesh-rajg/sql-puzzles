-- Portable pivot: conditional aggregation.
-- CASE without ELSE -> NULL -> ignored by SUM; COALESCE turns empty months into 0.
SELECT
    product,
    COALESCE(SUM(CASE WHEN sales_month = '2026-01' THEN amount END), 0) AS jan_2026,
    COALESCE(SUM(CASE WHEN sales_month = '2026-02' THEN amount END), 0) AS feb_2026,
    COALESCE(SUM(CASE WHEN sales_month = '2026-03' THEN amount END), 0) AS mar_2026
FROM monthly_sales
GROUP BY product
ORDER BY product;
