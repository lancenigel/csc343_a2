-- Part 2 Question 2: Cats Don’t Like Needles

-- Reorder the procedures for cat appointments on or after November 1, 2024
WITH CatAppointments AS (
    -- Find appointments for cats on or after November 1, 2024
    SELECT a.appointment_id
    FROM appointments a
    JOIN patients p ON a.patient_id = p.patient_id
    WHERE p.species = 'cat' AND a.appointment_date >= '2024-11-01'
),
OrderedProcedures AS (
    -- Separate 'blood work' procedures and other procedures
    SELECT p.procedure_id, p.appointment_id, p.procedure_type,
           ROW_NUMBER() OVER (PARTITION BY p.appointment_id 
                              ORDER BY CASE 
                                           WHEN p.procedure_type = 'blood work' THEN 1
                                           ELSE 0
                                        END, p.procedure_order) AS new_order
    FROM procedures p
    JOIN CatAppointments ca ON p.appointment_id = ca.appointment_id
)
-- Update the procedure order for relevant appointments
UPDATE procedures
SET procedure_order = op.new_order
FROM OrderedProcedures op
WHERE procedures.procedure_id = op.procedure_id;
