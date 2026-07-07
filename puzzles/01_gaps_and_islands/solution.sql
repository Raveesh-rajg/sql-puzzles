-- Gaps & islands via the date-minus-row_number trick.
-- Step 0 (the trap): dedup to one row per user-day BEFORE numbering.
WITH distinct_days AS (
    SELECT DISTINCT user_id, login_date
    FROM logins
),

islands AS (
    SELECT
        user_id,
        login_date,
        -- constant within a run of consecutive dates
        login_date - CAST(ROW_NUMBER() OVER (
            PARTITION BY user_id ORDER BY login_date
        ) AS INTEGER) AS island_key          -- Snowflake: DATEADD(day, -rn, login_date)
    FROM distinct_days
),

streaks AS (
    SELECT
        user_id,
        COUNT(*)        AS streak_len,
        MIN(login_date) AS streak_start,
        MAX(login_date) AS streak_end
    FROM islands
    GROUP BY user_id, island_key
)

SELECT
    user_id,
    streak_len AS longest_streak,
    streak_start,
    streak_end
FROM streaks
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY user_id
    ORDER BY streak_len DESC, streak_start   -- tie -> earliest streak
) = 1
ORDER BY user_id;
