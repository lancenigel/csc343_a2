-- Part 2 Question 3: Client Cleanup

-- Step 1: Identify clients who have not had any appointments since January 1, 2019
CREATE TEMP TABLE InactiveClients AS
    SELECT c.c_id
    FROM Client c
    LEFT JOIN Patient p ON c.c_id = p.c_id
    LEFT JOIN Appointment a ON p.p_id = a.p_id
    GROUP BY c.c_id
    HAVING MAX(a.scheduled_date) < '2019-01-01' OR MAX(a.scheduled_date) IS NULL;

-- Step 2: Include clients who have no pets registered in the system
CREATE TEMP TABLE ClientsWithoutPets AS
    SELECT c.c_id
    FROM Client c
    LEFT JOIN Patient p ON c.c_id = p.c_id
    WHERE p.p_id IS NULL;

-- Step 3: Find all clients who should be deleted (either no pets or no recent appointments)
CREATE TEMP TABLE ClientsToDelete AS
    SELECT c_id
    FROM InactiveClients
    UNION
    SELECT c_id
    FROM ClientsWithoutPets;

-- Step 4: Delete scheduled procedures for patients belonging to clients who are about to be deleted
DELETE FROM ScheduledProcedure
WHERE a_id IN (
    SELECT a.a_id 
    FROM Appointment a
    JOIN Patient p ON a.p_id = p.p_id
    WHERE p.c_id IN (SELECT c_id FROM ClientsToDelete)
);

-- Step 5: **Delete from ScheduledProcedureStaff** before deleting appointments
DELETE FROM ScheduledProcedureStaff
WHERE a_id IN (
    SELECT a.a_id 
    FROM Appointment a
    JOIN Patient p ON a.p_id = p.p_id
    WHERE p.c_id IN (SELECT c_id FROM ClientsToDelete)
);

-- Step 6: Delete appointments for patients belonging to clients who are about to be deleted
DELETE FROM Appointment
WHERE p_id IN (SELECT p.p_id FROM Patient p WHERE p.c_id IN (SELECT c_id FROM ClientsToDelete));

-- Step 7: Delete pets belonging to clients who are about to be deleted
DELETE FROM Patient
WHERE c_id IN (SELECT c_id FROM ClientsToDelete);

-- Step 8: Delete the clients who have no pets or no recent appointments
DELETE FROM Client
WHERE c_id IN (SELECT c_id FROM ClientsToDelete);
