CREATE OR REPLACE TABLE transactions (
    txn_id     INTEGER NOT NULL,
    account_id VARCHAR NOT NULL,
    txn_date   DATE    NOT NULL,
    amount     INTEGER NOT NULL   -- cents omitted for readability; signed
);

INSERT INTO transactions VALUES
-- account A: includes two same-day transactions (txn 1 and 2)
(1, 'A', DATE '2026-01-01',  1000),
(2, 'A', DATE '2026-01-01',  -200),
(3, 'A', DATE '2026-01-03',  -300),
(4, 'A', DATE '2026-01-10',    50),
-- account B: same-day pair on Jan 5 — the RANGE-frame trap rows
(5, 'B', DATE '2026-01-02',   500),
(6, 'B', DATE '2026-01-05',  -500),
(7, 'B', DATE '2026-01-05',  -100);
