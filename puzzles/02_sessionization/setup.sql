CREATE OR REPLACE TABLE events (
    user_id  VARCHAR   NOT NULL,
    event_ts TIMESTAMP NOT NULL
);

INSERT INTO events VALUES
-- alice session 1: gaps of 10 and 15 minutes
('alice', TIMESTAMP '2026-03-01 09:00:00'),
('alice', TIMESTAMP '2026-03-01 09:10:00'),
('alice', TIMESTAMP '2026-03-01 09:25:00'),
-- 31-minute gap -> alice session 2
('alice', TIMESTAMP '2026-03-01 09:56:00'),
('alice', TIMESTAMP '2026-03-01 10:20:00'),
-- bob: gap of EXACTLY 30 minutes -> still session 1 (rule is "> 30")
('bob',   TIMESTAMP '2026-03-01 10:00:00'),
('bob',   TIMESTAMP '2026-03-01 10:30:00'),
-- 31-minute gap -> bob session 2, a single-event session
('bob',   TIMESTAMP '2026-03-01 11:01:00');
