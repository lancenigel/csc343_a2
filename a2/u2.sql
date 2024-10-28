-- Part 2 Question 2: Reorder procedures for cat appointments

-- Step 1: Create a temporary table for cat appointments
CREATE TEMP TABLE CatAppointments AS
SELECT a.a_id
FROM Appointment a
JOIN Patient p ON a.p_id = p.p_id
WHERE
    p.species = 'cat' AND
    a.scheduled_date >= '2024-11-01';

-- Step 2: Create a temporary table for ordered procedures
CREATE TEMP TABLE OrderedProcedures AS
SELECT
    sp.a_id,
    sp.pr_id,
    ROW_NUMBER() OVER (
        PARTITION BY sp.a_id
        ORDER BY
            CASE WHEN pr.name = 'blood work' THEN 2 ELSE 1 END,
            sp.pr_order
    ) AS new_pr_order
FROM ScheduledProcedure sp
JOIN Procedure pr ON sp.pr_id = pr.pr_id
WHERE sp.a_id IN (SELECT a_id FROM CatAppointments);

-- Step 3: Delete old procedures for affected appointments
DELETE FROM ScheduledProcedure
WHERE a_id IN (SELECT a_id FROM CatAppointments);

-- Step 4: Insert reordered procedures back into ScheduledProcedure
INSERT INTO ScheduledProcedure (a_id, pr_id, pr_order)
SELECT a_id, pr_id, new_pr_order
FROM OrderedProcedures;

-- Step 5: Drop temporary tables
DROP TABLE OrderedProcedures;
DROP TABLE CatAppointments;
