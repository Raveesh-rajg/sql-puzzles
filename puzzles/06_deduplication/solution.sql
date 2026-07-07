SELECT
    customer_id,
    record_id,
    email,
    city,
    updated_at
FROM customers
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY updated_at DESC,
             record_id  DESC     -- deterministic tie-break within a batch
) = 1
ORDER BY customer_id;
