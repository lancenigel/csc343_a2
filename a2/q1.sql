-- Assignment 2 Query 1

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO A2VetClinic;
DROP TABLE IF EXISTS q1 CASCADE;

CREATE TABLE q1 (
    c_id INT NOT NULL,
    client_name VARCHAR(30) NOT NULL,
    email VARCHAR(300) NOT NULL,
    patient_name VARCHAR(30) NOT NULL
);

-- Drop views for intermediate steps
DROP VIEW IF EXISTS ActivePatients CASCADE;
DROP VIEW IF EXISTS FirstAppointmentYear CASCADE;
DROP VIEW IF EXISTS YearlyDiagnosticCheck CASCADE;
DROP VIEW IF EXISTS PatientsWithoutCurrentOrScheduledDiagnosticTest CASCADE;

-- Step 1: Find active patients (with appointments in the last three calendar years)
CREATE VIEW ActivePatients AS
    SELECT p.p_id, p.name AS patient_name, p.c_id, c.name AS client_name, c.email
    FROM Patient p
    JOIN Client c ON p.c_id = c.c_id
    JOIN Appointment a ON p.p_id = a.p_id
    WHERE EXTRACT(YEAR FROM a.scheduled_date) >= EXTRACT(YEAR FROM CURRENT_DATE) - 2;

-- Step 2: Determine the first appointment year for each patient
CREATE VIEW FirstAppointmentYear AS
    SELECT p_id, MIN(EXTRACT(YEAR FROM scheduled_date)) AS first_appointment_year
    FROM Appointment
    GROUP BY p_id;

-- Step 3: Ensure diagnostic testing was done each year since the first appointment
CREATE VIEW YearlyDiagnosticCheck AS
    SELECT ap.p_id, ap.c_id, fa.first_appointment_year,
           COUNT(DISTINCT EXTRACT(YEAR FROM a.scheduled_date)) AS years_with_testing
    FROM ActivePatients ap
    JOIN Appointment a ON ap.p_id = a.p_id
    JOIN ScheduledProcedure sp ON a.a_id = sp.a_id
    JOIN Procedure pr ON sp.pr_id = pr.pr_id
    JOIN FirstAppointmentYear fa ON ap.p_id = fa.p_id
    WHERE pr.name = 'diagnostic testing'
    GROUP BY ap.p_id, ap.c_id, fa.first_appointment_year
    HAVING COUNT(DISTINCT EXTRACT(YEAR FROM a.scheduled_date)) = EXTRACT(YEAR FROM CURRENT_DATE) - fa.first_appointment_year + 1;

-- Step 4: Find patients who have not had diagnostic testing or have it scheduled but not yet completed this year
CREATE VIEW PatientsWithoutCurrentOrScheduledDiagnosticTest AS
    SELECT yd.p_id, yd.c_id
    FROM YearlyDiagnosticCheck yd
    LEFT JOIN Appointment a ON yd.p_id = a.p_id
    LEFT JOIN ScheduledProcedure sp ON a.a_id = sp.a_id
    LEFT JOIN Procedure pr ON sp.pr_id = pr.pr_id
    AND EXTRACT(YEAR FROM a.scheduled_date) = EXTRACT(YEAR FROM CURRENT_DATE)
    AND pr.name = 'diagnostic testing'
    WHERE sp.a_id IS NULL
    OR (a.scheduled_date >= CURRENT_DATE AND pr.name = 'diagnostic testing');  -- Scheduled but not completed

-- Insert the final result into q1
INSERT INTO q1
SELECT ap.c_id, ap.client_name, ap.email, ap.patient_name
FROM ActivePatients ap
JOIN PatientsWithoutCurrentOrScheduledDiagnosticTest pw ON ap.p_id = pw.p_id;
