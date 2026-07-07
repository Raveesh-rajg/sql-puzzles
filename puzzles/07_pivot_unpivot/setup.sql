CREATE OR REPLACE TABLE monthly_sales (
    product     VARCHAR NOT NULL,
    sales_month VARCHAR NOT NULL,   -- 'YYYY-MM'
    amount      INTEGER NOT NULL
);

INSERT INTO monthly_sales VALUES
('widget', '2026-01', 100),
('widget', '2026-02', 150),
('widget', '2026-03', 120),
('gadget', '2026-01',  80),
-- gadget has NO February row: the report must show 0, not NULL
('gadget', '2026-03',  90);
