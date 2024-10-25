-- Assignment 2 Query 3

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO A2VetClinic;
DROP TABLE IF EXISTS q3 CASCADE;

CREATE TABLE q3 (
    e_id INT NOT NULL,
    time_worked INTERVAL NOT NULL
);

-- Drop views for each intermediate step
DROP VIEW IF EXISTS RVT CASCADE;
DROP VIEW IF EXISTS DailyHours CASCADE;
DROP VIEW IF EXISTS ExhaustingDays CASCADE;
DROP VIEW IF EXISTS WeeklyExhaustingDays CASCADE;
DROP VIEW IF EXISTS OverworkedVetTechs CASCADE;

-- Step 1: Filter Vet Techs (RVTs)
CREATE VIEW RVT AS
    SELECT e.employee_id AS e_id
    FROM employees e
    WHERE e.role = 'RVT';

-- Step 2: Calculate total hours worked per day for each vet tech
CREATE VIEW DailyHours AS
    SELECT a.employee_id AS e_id, DATE(a.appointment_date) AS work_day, 
           SUM(a.end_time - a.start_time) AS total_hours_worked
    FROM appointments a
    JOIN RVT r ON a.employee_id = r.e_id
    GROUP BY a.employee_id, DATE(a.appointment_date);

-- Step 3: Find exhausting days (days with 8 or more hours worked)
CREATE VIEW ExhaustingDays AS
    SELECT e_id, work_day
    FROM DailyHours
    WHERE total_hours_worked >= INTERVAL '8 hours';

-- Step 4: Count exhausting days per week (Monday to Friday)
CREATE VIEW WeeklyExhaustingDays AS
    SELECT e_id, DATE_TRUNC('week', work_day)::date AS week_start,
           COUNT(work_day) AS exhausting_days_in_week
    FROM ExhaustingDays
    GROUP BY e_id, DATE_TRUNC('week', work_day)
    HAVING COUNT(work_day) >= 2; -- At least two exhausting days per week

-- Step 5: Find vet techs who had at least 3 weeks with two or more exhausting days
CREATE VIEW OverworkedVetTechs AS
    SELECT e_id, COUNT(DISTINCT week_start) AS exhausting_weeks
    FROM WeeklyExhaustingDays
    GROUP BY e_id
    HAVING COUNT(DISTINCT week_start) >= 3; -- At least three weeks with exhausting days

-- Insert final result into q3
INSERT INTO q3
SELECT owt.e_id, 
       SUM(dh.total_hours_worked) AS time_worked
FROM OverworkedVetTechs owt
JOIN DailyHours dh ON owt.e_id = dh.e_id
GROUP BY owt.e_id;
