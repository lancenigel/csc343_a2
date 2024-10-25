-- Assignment 2 Query 4

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO A2VetClinic;
DROP TABLE IF EXISTS q4 CASCADE;

CREATE TABLE q4 (
    mentee INT NOT NULL,
    mentor INT
);

-- Drop views for intermediate steps
DROP VIEW IF EXISTS NewEmployees CASCADE;
DROP VIEW IF EXISTS ExperiencedEmployees CASCADE;
DROP VIEW IF EXISTS MenteeSpecies CASCADE;
DROP VIEW IF EXISTS MentorSpecies CASCADE;
DROP VIEW IF EXISTS MentorshipMatches CASCADE;

-- Step 1: Find new employees (mentees) who have been hired in the last 90 days
CREATE VIEW NewEmployees AS
    SELECT e.employee_id AS mentee
    FROM employees e
    WHERE AGE(CURRENT_DATE, e.hire_date) < INTERVAL '90 days'
      AND EXISTS (SELECT 1 FROM appointments a WHERE a.employee_id = e.employee_id);

-- Step 2: Find experienced employees (mentors) who have been working for at least 2 years
CREATE VIEW ExperiencedEmployees AS
    SELECT e.employee_id AS mentor
    FROM employees e
    WHERE AGE(CURRENT_DATE, e.hire_date) >= INTERVAL '2 years';

-- Step 3: List all species that each mentee has worked with
CREATE VIEW MenteeSpecies AS
    SELECT e.employee_id AS mentee, a.species_id
    FROM appointments a
    JOIN NewEmployees e ON a.employee_id = e.mentee
    GROUP BY e.employee_id, a.species_id;

-- Step 4: List all species that each mentor has worked with
CREATE VIEW MentorSpecies AS
    SELECT e.employee_id AS mentor, a.species_id
    FROM appointments a
    JOIN ExperiencedEmployees e ON a.employee_id = e.mentor
    GROUP BY e.employee_id, a.species_id;

-- Step 5: Match mentees to mentors who have worked with all species the mentee has handled
CREATE VIEW MentorshipMatches AS
    SELECT m.mentee, e.mentor
    FROM MenteeSpecies m
    LEFT JOIN MentorSpecies e ON m.species_id = e.species_id
    GROUP BY m.mentee, e.mentor
    HAVING COUNT(DISTINCT m.species_id) = (SELECT COUNT(DISTINCT ms.species_id)
                                           FROM MenteeSpecies ms
                                           WHERE ms.mentee = m.mentee);

-- Insert final result into q4
INSERT INTO q4
SELECT nm.mentee, mm.mentor
FROM NewEmployees nm
LEFT JOIN MentorshipMatches mm ON nm.mentee = mm.mentee;
