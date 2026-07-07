CREATE OR REPLACE TABLE logins (
    user_id    VARCHAR NOT NULL,
    login_date DATE    NOT NULL
);

INSERT INTO logins VALUES
-- alice: streak of 3 (Jan 1-3), then streak of 5 (Jan 5-9)
('alice', DATE '2026-01-01'),
('alice', DATE '2026-01-02'),
('alice', DATE '2026-01-03'),
('alice', DATE '2026-01-05'),
('alice', DATE '2026-01-06'),
('alice', DATE '2026-01-07'),
('alice', DATE '2026-01-08'),
('alice', DATE '2026-01-09'),
-- bob: never two days in a row -> longest streak is 1 (earliest wins the tie)
('bob',   DATE '2026-01-01'),
('bob',   DATE '2026-01-03'),
('bob',   DATE '2026-01-05'),
-- carol: one streak of 5 (Feb 10-14) BUT Feb 12 is logged twice.
-- Without dedup, row_number() splits her streak into 10-12 and 12-14.
('carol', DATE '2026-02-10'),
('carol', DATE '2026-02-11'),
('carol', DATE '2026-02-12'),
('carol', DATE '2026-02-12'),
('carol', DATE '2026-02-13'),
('carol', DATE '2026-02-14');
