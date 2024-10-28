-- Assignment 2 Query 3

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO A2VetClinic;
DROP TABLE IF EXISTS q3 CASCADE;

CREATE TABLE q3 (
    e_id INT NOT NULL,
    time_worked INTERVAL NOT NULL
);

-- Step 1: Get RVT Appointments
WITH RVTAppointments AS (
    SELECT
        sps.e_id,
        a.scheduled_date AS work_day,
        a.start_time,
        a.end_time
    FROM ScheduledProcedureStaff sps
    JOIN Appointment a ON sps.a_id = a.a_id
    JOIN Qualification q ON sps.e_id = q.e_id
    WHERE q.qualification = 'RVT'
),

-- Step 2: Order Appointments and Identify New Blocks
OrderedAppointments AS (
    SELECT
        e_id,
        work_day,
        start_time,
        end_time,
        ROW_NUMBER() OVER (PARTITION BY e_id, work_day ORDER BY start_time) AS rn,
        LAG(end_time) OVER (PARTITION BY e_id, work_day ORDER BY start_time) AS prev_end_time
    FROM RVTAppointments
),
AppointmentsWithFlags AS (
    SELECT
        *,
        CASE
            WHEN prev_end_time IS NULL THEN 1
            WHEN start_time > prev_end_time THEN 1
            ELSE 0
        END AS is_new_block
    FROM OrderedAppointments
),

-- Step 3: Assign Block Numbers
AppointmentsWithGroups AS (
    SELECT
        *,
        SUM(is_new_block) OVER (PARTITION BY e_id, work_day ORDER BY start_time) AS block_number
    FROM AppointmentsWithFlags
),

-- Step 4: Calculate Block Durations
BlockDurations AS (
    SELECT
        e_id,
        work_day,
        block_number,
        MIN(start_time) AS block_start_time,
        MAX(end_time) AS block_end_time
    FROM AppointmentsWithGroups
    GROUP BY e_id, work_day, block_number
),
BlockDurationsWithLength AS (
    SELECT
        e_id,
        work_day,
        (block_end_time - block_start_time) AS block_duration
    FROM BlockDurations
),

-- Step 5: Find the Longest Block per Day
MaxBlockDurations AS (
    SELECT
        e_id,
        work_day,
        MAX(block_duration) AS max_block_duration
    FROM BlockDurationsWithLength
    GROUP BY e_id, work_day
),

-- Step 6: Identify Exhausting Days
ExhaustingDays AS (
    SELECT
        e_id,
        work_day,
        max_block_duration
    FROM MaxBlockDurations
    WHERE max_block_duration >= INTERVAL '8 hours'
),

-- Step 7: Count Exhausting Days per Week
WeeklyExhaustingDays AS (
    SELECT
        e_id,
        DATE_TRUNC('week', work_day)::date AS week_start,
        COUNT(*) AS exhausting_days_in_week
    FROM ExhaustingDays
    GROUP BY e_id, DATE_TRUNC('week', work_day)
    HAVING COUNT(*) >= 2  -- At least two exhausting days per week
),

-- Step 8: Find Overworked Vet Techs
OverworkedVetTechs AS (
    SELECT e_id, COUNT(*) AS exhausting_weeks
    FROM WeeklyExhaustingDays
    GROUP BY e_id
    HAVING COUNT(*) >= 3  -- At least three weeks with exhausting days
)

-- Step 9: Calculate Total Time Worked on Exhausting Days
INSERT INTO q3
SELECT
    owt.e_id,
    SUM(ed.max_block_duration) AS time_worked
FROM OverworkedVetTechs owt
JOIN ExhaustingDays ed ON owt.e_id = ed.e_id
GROUP BY owt.e_id;
