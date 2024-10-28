-- Assignment 2 Query 2

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO A2VetClinic;
DROP TABLE IF EXISTS q2 CASCADE;

CREATE TABLE q2 (
    e_id INT NOT NULL,
    name VARCHAR(30) NOT NULL,
    hire_year INT NOT NULL,
    num_appointments INT NOT NULL,
    days_worked INT NOT NULL,
    avg_appointment_len INTERVAL NOT NULL,
    clients_helped INT NOT NULL,
    patients_helped INT NOT NULL,
    num_coworkers INT NOT NULL,
    total_supplies INT NOT NULL
);

-- Drop views for intermediate steps
DROP VIEW IF EXISTS EmployeeAppointments CASCADE;
DROP VIEW IF EXISTS DaysWorked CASCADE;
DROP VIEW IF EXISTS AppointmentLengths CASCADE;
DROP VIEW IF EXISTS ClientsHelped CASCADE;
DROP VIEW IF EXISTS PatientsHelped CASCADE;
DROP VIEW IF EXISTS CoworkersCount CASCADE;
DROP VIEW IF EXISTS SuppliesUsed CASCADE;

-- View 1: Total appointments worked per employee
CREATE VIEW EmployeeAppointments AS
SELECT e.e_id, COUNT(DISTINCT sps.a_id) AS num_appointments
FROM Employee e
LEFT JOIN ScheduledProcedureStaff sps ON e.e_id = sps.e_id
GROUP BY e.e_id;

-- View 2: Total distinct days worked per employee
CREATE VIEW DaysWorked AS
SELECT e.e_id, COUNT(DISTINCT a.scheduled_date) AS days_worked
FROM Employee e
LEFT JOIN ScheduledProcedureStaff sps ON e.e_id = sps.e_id
LEFT JOIN Appointment a ON sps.a_id = a.a_id
GROUP BY e.e_id;

-- View 3: Average appointment length per employee (corrected)
CREATE VIEW AppointmentLengths AS
SELECT sub.e_id,
       COALESCE(AVG(duration), INTERVAL '0 hours') AS avg_appointment_len
FROM (
    SELECT e.e_id, a.a_id, (a.end_time - a.start_time) AS duration
    FROM Employee e
    LEFT JOIN ScheduledProcedureStaff sps ON e.e_id = sps.e_id
    LEFT JOIN Appointment a ON sps.a_id = a.a_id
    GROUP BY e.e_id, a.a_id, a.end_time, a.start_time
) sub
GROUP BY sub.e_id;

-- View 4: Total distinct clients helped per employee
CREATE VIEW ClientsHelped AS
SELECT e.e_id, COUNT(DISTINCT c.c_id) AS clients_helped
FROM Employee e
LEFT JOIN ScheduledProcedureStaff sps ON e.e_id = sps.e_id
LEFT JOIN Appointment a ON sps.a_id = a.a_id
LEFT JOIN Patient p ON a.p_id = p.p_id
LEFT JOIN Client c ON p.c_id = c.c_id
GROUP BY e.e_id;

-- View 5: Total distinct patients helped per employee
CREATE VIEW PatientsHelped AS
SELECT e.e_id, COUNT(DISTINCT p.p_id) AS patients_helped
FROM Employee e
LEFT JOIN ScheduledProcedureStaff sps ON e.e_id = sps.e_id
LEFT JOIN Appointment a ON sps.a_id = a.a_id
LEFT JOIN Patient p ON a.p_id = p.p_id
GROUP BY e.e_id;

-- View 6: Total distinct coworkers per employee
CREATE VIEW CoworkersCount AS
SELECT e.e_id, COALESCE(COUNT(DISTINCT co.e_id), 0) AS num_coworkers
FROM Employee e
LEFT JOIN ScheduledProcedureStaff sps ON e.e_id = sps.e_id
LEFT JOIN ScheduledProcedureStaff co ON sps.a_id = co.a_id AND e.e_id != co.e_id
GROUP BY e.e_id;

-- View 7: Total supplies used per employee (corrected)
CREATE VIEW SuppliesUsed AS
SELECT sps_unique.e_id, COALESCE(SUM(ps.quantity), 0) AS total_supplies
FROM (
    SELECT DISTINCT e.e_id, sps.a_id, sps.pr_id
    FROM Employee e
    JOIN ScheduledProcedureStaff sps ON e.e_id = sps.e_id
) sps_unique
JOIN ProcedureSupply ps ON sps_unique.pr_id = ps.pr_id
GROUP BY sps_unique.e_id;

-- Insert the final result into q2
INSERT INTO q2
SELECT e.e_id,
       e.name,
       EXTRACT(YEAR FROM e.start_date) AS hire_year,
       COALESCE(ea.num_appointments, 0) AS num_appointments,
       COALESCE(dw.days_worked, 0) AS days_worked,
       COALESCE(al.avg_appointment_len, INTERVAL '0 hours') AS avg_appointment_len,
       COALESCE(ch.clients_helped, 0) AS clients_helped,
       COALESCE(ph.patients_helped, 0) AS patients_helped,
       COALESCE(cc.num_coworkers, 0) AS num_coworkers,
       COALESCE(su.total_supplies, 0) AS total_supplies
FROM Employee e
LEFT JOIN EmployeeAppointments ea ON e.e_id = ea.e_id
LEFT JOIN DaysWorked dw ON e.e_id = dw.e_id
LEFT JOIN AppointmentLengths al ON e.e_id = al.e_id
LEFT JOIN ClientsHelped ch ON e.e_id = ch.e_id
LEFT JOIN PatientsHelped ph ON e.e_id = ph.e_id
LEFT JOIN CoworkersCount cc ON e.e_id = cc.e_id
LEFT JOIN SuppliesUsed su ON e.e_id = su.e_id;
