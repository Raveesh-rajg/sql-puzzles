CREATE OR REPLACE TABLE customers (
    record_id   INTEGER   NOT NULL,   -- unique per row
    customer_id INTEGER   NOT NULL,   -- the business key we dedup on
    email       VARCHAR   NOT NULL,
    city        VARCHAR   NOT NULL,
    updated_at  TIMESTAMP NOT NULL
);

INSERT INTO customers VALUES
-- customer 101: three versions; records 4 and 7 share a timestamp (same batch)
(1, 101, 'a@old.com',   'New York',    TIMESTAMP '2026-01-01 08:00:00'),
(4, 101, 'a@new.com',   'New York',    TIMESTAMP '2026-02-01 09:00:00'),
(7, 101, 'a@newer.com', 'Jersey City', TIMESTAMP '2026-02-01 09:00:00'),
-- customer 102: single version
(2, 102, 'b@x.com',     'Boston',      TIMESTAMP '2026-01-15 12:00:00'),
-- customer 103: exact duplicate payloads with different record_ids
(3, 103, 'c@y.com',     'Chicago',     TIMESTAMP '2026-01-20 10:00:00'),
(6, 103, 'c@y.com',     'Chicago',     TIMESTAMP '2026-01-20 10:00:00');
