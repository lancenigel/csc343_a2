-- Assignment 2 Query 3

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO A2VetClinic;
DROP TABLE IF EXISTS q3 CASCADE;

CREATE TABLE q3 (
    e_id INT NOT NULL,
    time_worked INTERVAL NOT NULL
);

-- Drop views for each intermediate step
DROP VIEW IF EXISTS RVTs CASCADE;
DROP VIEW IF EXISTS DailyHours CASCADE;
DROP VIEW IF EXISTS ExhaustingDays CASCADE;
DROP VIEW IF EXISTS WeeklyExhaustingDays CASCADE;
DROP VIEW IF EXISTS OverworkedVetTechs CASCADE;

-- Step 1: Filter Vet Techs (RVTs)
CREATE VIEW RVTs AS
    SELECT e.e_id
    FROM Employee e
    JOIN Qualification q ON e.e_id = q.e_id
    WHERE q.qualification = 'RVT';

-- Step 2: Calculate total hours worked per day for each vet tech
CREATE VIEW DailyHours AS
    SELECT a.scheduled_by AS e_id, a.scheduled_date AS work_day, 
           SUM(DISTINCT a.end_time - a.start_time) AS total_hours_worked
    FROM Appointment a
    JOIN RVTs r ON a.scheduled_by = r.e_id
    GROUP BY a.scheduled_by, a.scheduled_date;

-- Step 3: Find exhausting days (days with 8 or more hours worked)
CREATE VIEW ExhaustingDays AS
    SELECT e_id, work_day
    FROM DailyHours
    WHERE total_hours_worked >= INTERVAL '8 hours';

-- Step 4: Count exhausting days per week (custom week start on Sunday)
CREATE VIEW WeeklyExhaustingDays AS
    SELECT e_id, (DATE_TRUNC('week', work_day + INTERVAL '1 day') - INTERVAL '1 day')::date AS week_start,
           COUNT(work_day) AS exhausting_days_in_week
    FROM ExhaustingDays
    GROUP BY e_id, (DATE_TRUNC('week', work_day + INTERVAL '1 day') - INTERVAL '1 day')
    HAVING COUNT(work_day) >= 2; -- At least two exhausting days per week


-- Step 5: Find vet techs who had at least 3 weeks with two or more exhausting days
CREATE VIEW OverworkedVetTechs AS
    SELECT e_id, COUNT(DISTINCT week_start) AS exhausting_weeks
    FROM WeeklyExhaustingDays
    GROUP BY e_id
    HAVING COUNT(DISTINCT week_start) >= 3; -- At least three weeks with exhausting days

-- Step 6: Calculate total hours worked only on exhausting days for overworked vet techs
INSERT INTO q3
SELECT owt.e_id, 
       SUM(dh.total_hours_worked) AS time_worked
FROM OverworkedVetTechs owt
JOIN WeeklyExhaustingDays wed ON owt.e_id = wed.e_id
-- Join only on exhausting days, not entire weeks
JOIN ExhaustingDays ed ON wed.e_id = ed.e_id AND DATE_TRUNC('week', ed.work_day) = wed.week_start
JOIN DailyHours dh ON ed.e_id = dh.e_id AND ed.work_day = dh.work_day
GROUP BY owt.e_id;


