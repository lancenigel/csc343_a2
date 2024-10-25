-- Part 2 Question 2: Reorder procedures for cat appointments

-- Step 1: Find all appointments for cats on or after November 1, 2024
WITH CatAppointments AS (
    SELECT a.a_id
    FROM Appointment a
    JOIN Patient p ON a.p_id = p.p_id
    WHERE p.species = 'cat' AND a.scheduled_date >= '2024-11-01'
),

-- Step 2: Generate unique new pr_order values for each procedure
OrderedProcedures AS (
    SELECT sp.a_id, sp.pr_id,
           ROW_NUMBER() OVER (
               PARTITION BY sp.a_id
               ORDER BY CASE WHEN pr.name = 'blood work' THEN 2 ELSE 1 END, sp.pr_order
           ) AS new_order
    FROM ScheduledProcedure sp
    JOIN Procedure pr ON sp.pr_id = pr.pr_id
    JOIN CatAppointments ca ON sp.a_id = ca.a_id
)

-- Step 3: Insert reordered procedures into a temporary table
CREATE TEMP TABLE TempScheduledProcedure AS
SELECT sp.a_id, sp.pr_id, op.new_order AS pr_order
FROM ScheduledProcedure sp
JOIN OrderedProcedures op ON sp.a_id = op.a_id AND sp.pr_id = op.pr_id;

-- Step 4: Delete the old records for affected appointments
DELETE FROM ScheduledProcedure
WHERE a_id IN (SELECT a_id FROM CatAppointments);

-- Step 5: Insert reordered procedures from the temporary table back into ScheduledProcedure
INSERT INTO ScheduledProcedure (a_id, pr_id, pr_order)
SELECT a_id, pr_id, pr_order
FROM TempScheduledProcedure;

-- Drop the temporary table
DROP TABLE TempScheduledProcedure;
