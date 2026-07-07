-- Pass 1: flag rows that start a new session (first event OR gap > 30 min).
WITH flagged AS (
    SELECT
        user_id,
        event_ts,
        CASE
            WHEN LAG(event_ts) OVER w IS NULL THEN 1                 -- first event ever
            WHEN event_ts - LAG(event_ts) OVER w
                 > INTERVAL 30 MINUTE THEN 1                          -- strict: exactly 30:00 stays
            ELSE 0
        END AS is_new_session
        -- Snowflake: DATEDIFF('second', LAG(event_ts) OVER w, event_ts) > 1800
    FROM events
    WINDOW w AS (PARTITION BY user_id ORDER BY event_ts)
),

-- Pass 2: cumulative sum of flags -> session number per user.
numbered AS (
    SELECT
        user_id,
        event_ts,
        SUM(is_new_session) OVER (
            PARTITION BY user_id ORDER BY event_ts
            ROWS UNBOUNDED PRECEDING
        ) AS session_num
    FROM flagged
)

SELECT
    user_id,
    session_num,
    MIN(event_ts) AS session_start,
    MAX(event_ts) AS session_end,
    COUNT(*)      AS n_events
FROM numbered
GROUP BY user_id, session_num
ORDER BY user_id, session_num;
