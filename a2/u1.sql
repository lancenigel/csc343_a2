-- Part 2, Question 1: Reduce the price of food-related supplies by half

-- Step 1: Update the price of food-related supplies by reducing it by half
UPDATE RetailSupply
SET price = price / 2
WHERE s_id IN (
    SELECT s.s_id
    FROM Supply s
    WHERE s.name ILIKE '%food%'
);
