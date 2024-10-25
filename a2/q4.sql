--- Assignment 2 Query 4

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO A2VetClinic;
DROP TABLE IF EXISTS q4 CASCADE;

CREATE TABLE q4 (
    mentee INT NOT NULL,
    mentor INT
);

-- Drop views for each intermediate step
DROP VIEW IF EXISTS NewEmployees CASCADE;
DROP VIEW IF EXISTS ExperiencedEmployees CASCADE;
DROP VIEW IF EXISTS MenteeSpecies CASCADE;
DROP VIEW IF EXISTS MentorSpecies CASCADE;
DROP VIEW IF EXISTS MentorshipMatches CASCADE;

-- Step 1: Find new employees (mentees) who have been hired in the last 90 days (and are not future hires)
CREATE VIEW NewEmployees AS
    SELECT e.e_id AS mentee
    FROM Employee e
    WHERE e.start_date <= CURRENT_DATE  -- Exclude future employees
    AND AGE(CURRENT_DATE, e.start_date) < INTERVAL '90 days'
    AND EXISTS (SELECT 1 FROM ScheduledProcedureStaff sps WHERE sps.e_id = e.e_id);

-- Step 2: Find experienced employees (mentors) who have been working for at least 2 years
CREATE VIEW ExperiencedEmployees AS
    SELECT e.e_id AS mentor
    FROM Employee e
    WHERE AGE(CURRENT_DATE, e.start_date) >= INTERVAL '2 years';

-- Step 3: List all species that each mentee has worked with
CREATE VIEW MenteeSpecies AS
    SELECT sps.e_id AS mentee, p.species
    FROM ScheduledProcedureStaff sps
    JOIN Appointment a ON sps.a_id = a.a_id
    JOIN Patient p ON a.p_id = p.p_id
    JOIN NewEmployees ne ON sps.e_id = ne.mentee
    GROUP BY sps.e_id, p.species;

-- Step 4: List all species that each mentor has worked with
CREATE VIEW MentorSpecies AS
    SELECT sps.e_id AS mentor, p.species
    FROM ScheduledProcedureStaff sps
    JOIN Appointment a ON sps.a_id = a.a_id
    JOIN Patient p ON a.p_id = p.p_id
    JOIN ExperiencedEmployees ee ON sps.e_id = ee.mentor
    GROUP BY sps.e_id, p.species;

-- Step 5: Match mentees to mentors who have worked with all species the mentee has handled
CREATE VIEW MentorshipMatches AS
    SELECT m.mentee, e.mentor
    FROM MenteeSpecies m
    LEFT JOIN MentorSpecies e ON m.species = e.species
    GROUP BY m.mentee, e.mentor
    HAVING COUNT(DISTINCT m.species) = (
        SELECT COUNT(DISTINCT ms.species)
        FROM MenteeSpecies ms
        WHERE ms.mentee = m.mentee
    );

-- Insert the final result into q4
INSERT INTO q4
SELECT mentee, mentor
FROM MentorshipMatches;
