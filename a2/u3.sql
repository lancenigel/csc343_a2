-- Part 2 Question 3: Client Cleanup

-- Step 1: Identify clients who have not had any appointments on or after January 1, 2019
WITH InactiveClients AS (
    SELECT c.client_id
    FROM clients c
    LEFT JOIN appointments a ON c.client_id = a.client_id
    GROUP BY c.client_id
    HAVING MAX(a.appointment_date) < '2019-01-01' OR MAX(a.appointment_date) IS NULL
),

-- Step 2: Include clients who have no pets recorded in the system
ClientsWithoutPets AS (
    SELECT c.client_id
    FROM clients c
    LEFT JOIN pets p ON c.client_id = p.client_id
    WHERE p.pet_id IS NULL
)

-- Step 3: Delete clients who meet the criteria (no recent appointments or no pets)
DELETE FROM clients
WHERE client_id IN (
    SELECT client_id FROM InactiveClients
    UNION
    SELECT client_id FROM ClientsWithoutPets
);
