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

-- Drop views for each intermediate step
DROP VIEW IF EXISTS EmployeeAppointments CASCADE;
DROP VIEW IF EXISTS DaysWorked CASCADE;
DROP VIEW IF EXISTS AppointmentLengths CASCADE;
DROP VIEW IF EXISTS ClientsHelped CASCADE;
DROP VIEW IF EXISTS PatientsHelped CASCADE;
DROP VIEW IF EXISTS CoworkersCount CASCADE;
DROP VIEW IF EXISTS SuppliesUsed CASCADE;

-- View 1: Total appointments worked per employee (not just scheduled by them)
CREATE VIEW EmployeeAppointments AS
    SELECT e.e_id AS e_id, COUNT(DISTINCT a.a_id) AS num_appointments
    FROM Employee e
    LEFT JOIN ScheduledProcedureStaff sps ON e.e_id = sps.e_id
    LEFT JOIN Appointment a ON sps.a_id = a.a_id
    GROUP BY e.e_id;

-- View 2: Total distinct days worked per employee
CREATE VIEW DaysWorked AS
    SELECT e.e_id AS e_id, COUNT(DISTINCT a.scheduled_date) AS days_worked
    FROM Employee e
    LEFT JOIN ScheduledProcedureStaff sps ON e.e_id = sps.e_id
    LEFT JOIN Appointment a ON sps.a_id = a.a_id
    GROUP BY e.e_id;


-- View 3: Average appointment length per employee
CREATE VIEW AppointmentLengths AS
    SELECT e.e_id AS e_id, 
           COALESCE(AVG(a.end_time - a.start_time), INTERVAL '0 hours') AS avg_appointment_len
    FROM Employee e
    LEFT JOIN Appointment a ON e.e_id = a.scheduled_by
    GROUP BY e.e_id;

-- View 4: Total distinct clients helped per employee
CREATE VIEW ClientsHelped AS
    SELECT e.e_id AS e_id, COUNT(DISTINCT c.c_id) AS clients_helped
    FROM Employee e
    LEFT JOIN ScheduledProcedureStaff sps ON e.e_id = sps.e_id
    LEFT JOIN Appointment a ON sps.a_id = a.a_id
    LEFT JOIN Patient p ON a.p_id = p.p_id
    LEFT JOIN Client c ON p.c_id = c.c_id
    GROUP BY e.e_id;

-- View 5: Total distinct patients helped per employee
CREATE VIEW PatientsHelped AS
    SELECT e.e_id AS e_id, COUNT(DISTINCT a.p_id) AS patients_helped
    FROM Employee e
    LEFT JOIN ScheduledProcedureStaff sps ON e.e_id = sps.e_id
    LEFT JOIN Appointment a ON sps.a_id = a.a_id
    GROUP BY e.e_id;


-- View 6: Total distinct coworkers worked with per employee
CREATE VIEW CoworkersCount AS
    SELECT e.e_id AS e_id, 
           COALESCE(COUNT(DISTINCT co.e_id), 0) AS num_coworkers
    FROM Employee e
    LEFT JOIN ScheduledProcedureStaff sps ON e.e_id = sps.e_id
    LEFT JOIN ScheduledProcedureStaff co ON sps.a_id = co.a_id AND e.e_id != co.e_id  -- Exclude the employee themselves
    GROUP BY e.e_id;


-- View 7: Total supplies used per employee (supplies related to procedures performed by the employee)
CREATE VIEW SuppliesUsed AS
    SELECT e.e_id AS e_id, 
           COALESCE(SUM(ps.quantity), 0) AS total_supplies
    FROM Employee e
    LEFT JOIN ScheduledProcedureStaff sps ON e.e_id = sps.e_id
    LEFT JOIN ProcedureSupply ps ON sps.pr_id = ps.pr_id
    GROUP BY e.e_id;

-- Insert the final result into q2
INSERT INTO q2
SELECT e.e_id AS e_id, 
       e.name, 
       EXTRACT(YEAR FROM e.start_date) AS hire_year,
       COALESCE(a.num_appointments, 0),
       COALESCE(dw.days_worked, 0),
       COALESCE(al.avg_appointment_len, INTERVAL '0 hours'),
       COALESCE(ch.clients_helped, 0),
       COALESCE(ph.patients_helped, 0),
       COALESCE(cc.num_coworkers, 0),
       COALESCE(su.total_supplies, 0)
FROM Employee e
LEFT JOIN EmployeeAppointments a ON e.e_id = a.e_id
LEFT JOIN DaysWorked dw ON e.e_id = dw.e_id
LEFT JOIN AppointmentLengths al ON e.e_id = al.e_id
LEFT JOIN ClientsHelped ch ON e.e_id = ch.e_id
LEFT JOIN PatientsHelped ph ON e.e_id = ph.e_id
LEFT JOIN CoworkersCount cc ON e.e_id = cc.e_id
LEFT JOIN SuppliesUsed su ON e.e_id = su.e_id;
