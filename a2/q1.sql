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
DROP VIEW IF EXISTS PatientYears CASCADE;
DROP VIEW IF EXISTS DiagnosticYears CASCADE;
DROP VIEW IF EXISTS PatientsWithCompleteDiagnosticHistory CASCADE;
DROP VIEW IF EXISTS PatientsOverdue CASCADE;

-- Step 1: Find active patients (with appointments in the last three calendar years)
CREATE VIEW ActivePatients AS
SELECT DISTINCT p.p_id, p.name AS patient_name, p.c_id, c.name AS client_name, c.email
FROM Patient p
JOIN Client c ON p.c_id = c.c_id
JOIN Appointment a ON p.p_id = a.p_id
WHERE EXTRACT(YEAR FROM a.scheduled_date) BETWEEN EXTRACT(YEAR FROM CURRENT_DATE) - 2 AND EXTRACT(YEAR FROM CURRENT_DATE);

-- Step 2: Determine the first appointment year for each active patient
CREATE VIEW FirstAppointmentYear AS
SELECT ap.p_id, MIN(EXTRACT(YEAR FROM a.scheduled_date)) AS first_appointment_year
FROM ActivePatients ap
JOIN Appointment a ON ap.p_id = a.p_id
GROUP BY ap.p_id;

-- Step 3: Generate required years for each patient
CREATE VIEW PatientYears AS
SELECT ap.p_id, generate_series(fa.first_appointment_year, EXTRACT(YEAR FROM CURRENT_DATE) - 1)::int AS year
FROM ActivePatients ap
JOIN FirstAppointmentYear fa ON ap.p_id = fa.p_id;

-- Step 4: Find years when patients had diagnostic testing
CREATE VIEW DiagnosticYears AS
SELECT DISTINCT a.p_id, EXTRACT(YEAR FROM a.scheduled_date)::int AS year
FROM Appointment a
JOIN ScheduledProcedure sp ON a.a_id = sp.a_id
JOIN Procedure pr ON sp.pr_id = pr.pr_id
WHERE pr.name = 'diagnostic testing';

-- Step 5: Find patients who have had diagnostic testing in all required years
CREATE VIEW PatientsWithCompleteDiagnosticHistory AS
SELECT py.p_id
FROM PatientYears py
LEFT JOIN DiagnosticYears dy ON py.p_id = dy.p_id AND py.year = dy.year
GROUP BY py.p_id
HAVING COUNT(*) = COUNT(dy.year);

-- Step 6: Find patients who have not had or scheduled diagnostic testing this year
CREATE VIEW PatientsOverdue AS
SELECT ap.c_id, ap.client_name, ap.email, ap.patient_name
FROM ActivePatients ap
JOIN PatientsWithCompleteDiagnosticHistory pwh ON ap.p_id = pwh.p_id
WHERE NOT EXISTS (
    SELECT 1
    FROM Appointment a
    JOIN ScheduledProcedure sp ON a.a_id = sp.a_id
    JOIN Procedure pr ON sp.pr_id = pr.pr_id
    WHERE pr.name = 'diagnostic testing'
      AND a.p_id = ap.p_id
      AND EXTRACT(YEAR FROM a.scheduled_date) = EXTRACT(YEAR FROM CURRENT_DATE)
);

-- Insert the final result into q1
INSERT INTO q1 (c_id, client_name, email, patient_name)
SELECT p.c_id, p.client_name, p.email, p.patient_name
FROM PatientsOverdue p;
