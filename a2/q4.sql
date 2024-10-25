-- Assignment 2 Query 4

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO A2VetClinic;
DROP TABLE IF EXISTS q4 CASCADE;

CREATE TABLE q4 (
    mentee INT NOT NULL,
    mentor INT
);

-- Drop views for each intermediate step
DROP VIEW IF EXISTS MenteeSpecies CASCADE;
DROP VIEW IF EXISTS MentorSpecies CASCADE;
DROP VIEW IF EXISTS MentorshipMatches CASCADE;

-- Step 1: Mentees and the species they have worked with
CREATE VIEW MenteeSpecies AS
    SELECT DISTINCT e.e_id AS mentee, p.species
    FROM Employee e
    JOIN Appointment a ON e.e_id = a.scheduled_by
    JOIN Patient p ON a.p_id = p.p_id
    WHERE e.start_date >= '2024-09-01'; -- Filter mentees by hire date

-- Step 2: Mentors and the species they have worked with
CREATE VIEW MentorSpecies AS
    SELECT DISTINCT e.e_id AS mentor, p.species
    FROM Employee e
    JOIN Appointment a ON e.e_id = a.scheduled_by
    JOIN Patient p ON a.p_id = p.p_id
    WHERE e.start_date < '2024-09-01'; -- Filter mentors by hire date

-- Step 3: Match mentees to mentors who have worked with the same species
-- Add DISTINCT and LEFT JOIN to prevent duplicate rows
CREATE VIEW MentorshipMatches AS
    -- Mentees who have matching mentors
    SELECT DISTINCT m.mentee, e.mentor
    FROM MenteeSpecies m
    LEFT JOIN MentorSpecies e ON m.species = e.species
    WHERE e.mentor IS NOT NULL -- Only include mentors with matching species

    UNION
    -- Mentees who do not have any matching mentors, return them with NULL for mentor
    SELECT DISTINCT m.mentee, NULL AS mentor
    FROM MenteeSpecies m
    LEFT JOIN MentorSpecies e ON m.species = e.species
    WHERE e.mentor IS NULL;

-- Step 4: Insert the final result into q4
INSERT INTO q4
SELECT mentee, mentor
FROM MentorshipMatches
ORDER BY mentee, mentor;
