-- Assignment 2 Query 4

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO A2VetClinic;
DROP TABLE IF EXISTS q4 CASCADE;

CREATE TABLE q4 (
    mentee INT NOT NULL,
    mentor INT
);

-- Drop views for each intermediate step
DROP VIEW IF EXISTS Mentees CASCADE;
DROP VIEW IF EXISTS Mentors CASCADE;
DROP VIEW IF EXISTS MenteeSpecies CASCADE;
DROP VIEW IF EXISTS MentorSpecies CASCADE;
DROP VIEW IF EXISTS MenteeMentorPairs CASCADE;
DROP VIEW IF EXISTS MentorMenteeSpeciesMatch CASCADE;

-- Step 1: Identify Mentees (employees hired in the last 90 days who have worked on at least one appointment)
CREATE VIEW Mentees AS
SELECT DISTINCT e.e_id AS mentee
FROM Employee e
JOIN ScheduledProcedureStaff sps ON e.e_id = sps.e_id
WHERE e.start_date >= (CURRENT_DATE - INTERVAL '90 days')
  AND e.start_date <= CURRENT_DATE;

-- Step 2: Identify Mentors (employees hired at least 2 years ago)
CREATE VIEW Mentors AS
SELECT e.e_id AS mentor
FROM Employee e
WHERE e.start_date <= (CURRENT_DATE - INTERVAL '2 years');

-- Step 3: Find species each mentee has worked with
CREATE VIEW MenteeSpecies AS
SELECT DISTINCT ms.mentee, p.species
FROM Mentees ms
JOIN ScheduledProcedureStaff sps ON ms.mentee = sps.e_id
JOIN Appointment a ON sps.a_id = a.a_id
JOIN Patient p ON a.p_id = p.p_id;

-- Step 4: Find species each mentor has worked with
CREATE VIEW MentorSpecies AS
SELECT DISTINCT me.mentor, p.species
FROM Mentors me
JOIN ScheduledProcedureStaff sps ON me.mentor = sps.e_id
JOIN Appointment a ON sps.a_id = a.a_id
JOIN Patient p ON a.p_id = p.p_id;

-- Step 5: Generate all possible mentee-mentor pairs
CREATE VIEW MenteeMentorPairs AS
SELECT ms.mentee, me.mentor
FROM Mentees ms
CROSS JOIN Mentors me;

-- Step 6: Check if mentors have worked with all species the mentee has
CREATE VIEW MentorMenteeSpeciesMatch AS
SELECT mmp.mentee, mmp.mentor,
       COUNT(DISTINCT ms.species) AS mentee_species_count,
       COUNT(DISTINCT CASE WHEN mns.species IS NOT NULL THEN ms.species END) AS matched_species_count
FROM MenteeMentorPairs mmp
JOIN MenteeSpecies ms ON mmp.mentee = ms.mentee
LEFT JOIN MentorSpecies mns ON mmp.mentor = mns.mentor AND ms.species = mns.species
GROUP BY mmp.mentee, mmp.mentor;

-- Step 7: Select mentors who have worked with all species of the mentee
INSERT INTO q4
SELECT mentee, mentor
FROM MentorMenteeSpeciesMatch
WHERE matched_species_count = mentee_species_count

UNION

-- Include mentees with no matching mentors
SELECT mentee, NULL AS mentor
FROM Mentees
WHERE mentee NOT IN (
    SELECT mentee
    FROM MentorMenteeSpeciesMatch
    WHERE matched_species_count = mentee_species_count
);
