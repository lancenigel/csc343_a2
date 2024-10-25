-- Assignment 2 Query 5

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO A2VetClinic;
DROP TABLE IF EXISTS q5 CASCADE;

CREATE TABLE q5 (
    p_id INT NOT NULL,
        num_complex INT NOT NULL
);

-- Drop views for intermediate steps
DROP VIEW IF EXISTS AverageAppointmentLengthPerSpecies CASCADE;
DROP VIEW IF EXISTS ComplexAppointments CASCADE;
DROP VIEW IF EXISTS ComplexPatientAppointments CASCADE;
DROP VIEW IF EXISTS ComplexPatients CASCADE;

-- Step 1: Calculate average appointment length for each species
CREATE VIEW AverageAppointmentLengthPerSpecies AS
    SELECT a.species_id, AVG(a.end_time - a.start_time) AS avg_appointment_length
    FROM appointments a
    GROUP BY a.species_id;

-- Step 2: Identify complex appointments (those that take more than twice the average time for the species)
CREATE VIEW ComplexAppointments AS
    SELECT a.appointment_id, a.patient_id, a.species_id
    FROM appointments a
    JOIN AverageAppointmentLengthPerSpecies avg_s ON a.species_id = avg_s.species_id
    WHERE (a.end_time - a.start_time) > 2 * avg_s.avg_appointment_length;

-- Step 3: Count the number of complex appointments per patient
CREATE VIEW ComplexPatientAppointments AS
    SELECT ca.patient_id AS p_id, COUNT(ca.appointment_id) AS num_complex
    FROM ComplexAppointments ca
    GROUP BY ca.patient_id;

-- Step 4: Identify patients with the most complex appointments
CREATE VIEW ComplexPatients AS
    SELECT p_id, num_complex
    FROM ComplexPatientAppointments
    WHERE num_complex = (SELECT MAX(num_complex) FROM ComplexPatientAppointments);

-- Insert final result into q5
INSERT INTO q5
SELECT cp.p_id, cp.num_complex
FROM ComplexPatients cp;
