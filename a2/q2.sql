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

-- View 1: Total appointments worked per employee
CREATE VIEW EmployeeAppointments AS
    SELECT e.employee_id AS e_id, COUNT(DISTINCT a.appointment_id) AS num_appointments
    FROM employees e
    LEFT JOIN appointments a ON e.employee_id = a.employee_id
    GROUP BY e.employee_id;

-- View 2: Total distinct days worked per employee
CREATE VIEW DaysWorked AS
    SELECT e.employee_id AS e_id, COUNT(DISTINCT DATE(a.appointment_date)) AS days_worked
    FROM employees e
    LEFT JOIN appointments a ON e.employee_id = a.employee_id
    GROUP BY e.employee_id;

-- View 3: Average appointment length per employee
CREATE VIEW AppointmentLengths AS
    SELECT e.employee_id AS e_id, 
           COALESCE(AVG(a.end_time - a.start_time), INTERVAL '0 hours') AS avg_appointment_len
    FROM employees e
    LEFT JOIN appointments a ON e.employee_id = a.employee_id
    GROUP BY e.employee_id;

-- View 4: Total distinct clients helped per employee
CREATE VIEW ClientsHelped AS
    SELECT e.employee_id AS e_id, COUNT(DISTINCT a.client_id) AS clients_helped
    FROM employees e
    LEFT JOIN appointments a ON e.employee_id = a.employee_id
    GROUP BY e.employee_id;

-- View 5: Total distinct patients helped per employee
CREATE VIEW PatientsHelped AS
    SELECT e.employee_id AS e_id, COUNT(DISTINCT a.patient_id) AS patients_helped
    FROM employees e
    LEFT JOIN appointments a ON e.employee_id = a.employee_id
    GROUP BY e.employee_id;

-- View 6: Total distinct coworkers worked with per employee
CREATE VIEW CoworkersCount AS
    SELECT e.employee_id AS e_id, 
           COALESCE(COUNT(DISTINCT co.employee_id), 0) AS num_coworkers
    FROM employees e
    LEFT JOIN appointments a ON e.employee_id = a.employee_id
    LEFT JOIN appointments co ON a.appointment_id = co.appointment_id AND e.employee_id != co.employee_id
    GROUP BY e.employee_id;

-- View 7: Total supplies used per employee
CREATE VIEW SuppliesUsed AS
    SELECT e.employee_id AS e_id, 
           COALESCE(SUM(s.quantity), 0) AS total_supplies
    FROM employees e
    LEFT JOIN appointments a ON e.employee_id = a.employee_id
    LEFT JOIN supplies_used s ON a.appointment_id = s.appointment_id
    GROUP BY e.employee_id;

-- Insert the final results into q2
INSERT INTO q2
SELECT e.employee_id AS e_id, 
       e.name, 
       EXTRACT(YEAR FROM e.hire_date) AS hire_year,
       COALESCE(a.num_appointments, 0),
       COALESCE(dw.days_worked, 0),
       COALESCE(al.avg_appointment_len, INTERVAL '0 hours'),
       COALESCE(ch.clients_helped, 0),
       COALESCE(ph.patients_helped, 0),
       COALESCE(cc.num_coworkers, 0),
       COALESCE(su.total_supplies, 0)
FROM employees e
LEFT JOIN EmployeeAppointments a ON e.employee_id = a.e_id
LEFT JOIN DaysWorked dw ON e.employee_id = dw.e_id
LEFT JOIN AppointmentLengths al ON e.employee_id = al.e_id
LEFT JOIN ClientsHelped ch ON e.employee_id = ch.e_id
LEFT JOIN PatientsHelped ph ON e.employee_id = ph.e_id
LEFT JOIN CoworkersCount cc ON e.employee_id = cc.e_id
LEFT JOIN SuppliesUsed su ON e.employee_id = su.e_id;
