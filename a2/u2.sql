-- Part 2 Question 2: Reorder procedures for cat appointments

-- Step 1: Find all appointments for cats on or after November 1, 2024
WITH CatAppointments AS (
    SELECT a.a_id
    FROM Appointment a
    JOIN Patient p ON a.p_id = p.p_id
    WHERE p.species = 'cat' AND a.scheduled_date >= '2024-11-01'
)

-- Step 2: Generate unique new pr_order values for each procedure
-- Instead of using a CTE, create a temporary table for OrderedProcedures
CREATE TEMP TABLE OrderedProcedures AS
    SELECT sp.a_id, sp.pr_id,
           ROW_NUMBER() OVER (
               PARTITION BY sp.a_id
               ORDER BY CASE WHEN pr.name = 'blood work' THEN 2 ELSE 1 END, sp.pr_order
           ) AS new_order
    FROM ScheduledProcedure sp
    JOIN Procedure pr ON sp.pr_id = pr.pr_id
    JOIN CatAppointments ca ON sp.a_id = ca.a_id;

-- Step 3: Temporarily set pr_order to a large number (to avoid conflicts with existing small values)
UPDATE ScheduledProcedure
SET pr_order = pr_order + 1000
WHERE a_id IN (SELECT a_id FROM CatAppointments);

-- Step 4: Set pr_order to the correct new_order values from OrderedProcedures
UPDATE ScheduledProcedure sp
SET pr_order = op.new_order
FROM OrderedProcedures op
WHERE sp.a_id = op.a_id AND sp.pr_id = op.pr_id;

-- Drop the temporary table to clean up after the query
DROP TABLE OrderedProcedures;
