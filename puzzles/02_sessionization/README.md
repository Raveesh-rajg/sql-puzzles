# 02 — Sessionization (30-minute inactivity timeout)

## Problem

`events(user_id, event_ts)` is a raw clickstream. Group each user's events into
**sessions**, where a new session starts when more than 30 minutes pass since the
user's previous event. Return one row per session: user, session number, start,
end, and event count.

## The trick

Two window passes:

1. **Flag session starts.** `LAG(event_ts)` gives the previous event; the row starts
   a new session if the gap exceeds 30 minutes *or* there is no previous event
   (`LAG` is NULL — forgetting this drops every user's first session flag).
2. **Turn flags into ids.** A running `SUM(is_new_session)` over the ordered events
   converts the 0/1 flags into a session number that increments at every boundary —
   the same cumulative-sum trick that powers most "carry a group id forward" problems.

Then it's a plain `GROUP BY`.

## Edge cases planted in the data

- A gap of **exactly 30:00** (bob, 10:00 → 10:30): the rule is *more than* 30
  minutes, so this stays one session. Off-by-one boundary handling is where most
  attempts diverge.
- A single-event session (bob's 11:01): start = end, count = 1.

## Alternatives considered

- Vendor sessionization functions (e.g., `SESSIONIZE` in some engines,
  `MATCH_RECOGNIZE` in Snowflake): less portable; `MATCH_RECOGNIZE` shines when the
  session definition involves event *patterns*, not just time gaps.
- Self-join on time ranges: quadratic; never do this on clickstream volumes.

## Snowflake notes

Replace the interval comparison with `DATEDIFF('minute', prev_ts, event_ts) > 30`
(note: `DATEDIFF` counts minute *boundaries*, so for exact semantics prefer
`TIMESTAMPDIFF` or compare epoch seconds: `DATEDIFF('second', ...) > 1800`).
