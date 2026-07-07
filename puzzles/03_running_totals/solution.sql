SELECT
    account_id,
    txn_id,
    txn_date,
    amount,
    SUM(amount) OVER (
        PARTITION BY account_id
        ORDER BY txn_date, txn_id          -- deterministic: tie-break same-day rows
        ROWS UNBOUNDED PRECEDING           -- explicit: never rely on the RANGE default
    ) AS running_balance
FROM transactions
ORDER BY account_id, txn_date, txn_id;
