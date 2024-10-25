-- NOTE: we have included some constraints in a comment in cases where
-- enforcing the constraint using SQL would be costly. For all parts of A2,
-- you may assume that these constraints hold, unless we explicitly specify
-- otherwise. Don't make any additional assumptions, regarding constraints
-- not enforced by the schema, or provided in the comments (even if the
-- constraint was specified in A1).

DROP SCHEMA IF EXISTS A2VetClinic CASCADE;
CREATE SCHEMA A2VetClinic;
SET SEARCH_PATH TO A2VetClinic;


-- A human client at the clinic, their name <name>, email <email>,
-- and phone number <phone>.
CREATE TABLE Client (
	c_id INT PRIMARY KEY,
	name VARCHAR(30) NOT NULL,
	email VARCHAR(300) NOT NULL,
	phone VARCHAR(15) NOT NULL
);


-- An animal patient at the clinic, that belongs to client <c_id>,
-- is of the species <species>, and has the name <name>,
-- birth date <birth_date>, and weighs <weight>.
CREATE TABLE Patient (
	p_id INT PRIMARY KEY,
	c_id INT NOT NULL REFERENCES Client(c_id),
	name VARCHAR(30) NOT NULL,
	species VARCHAR(30) NOT NULL,
	birth_date DATE NOT NULL,
	weight float NOT NULL
);


-- An employee at the clinic, with the name <name>.
-- Their first day at the clinic is <start_date>.
CREATE TABLE Employee (
	e_id INT PRIMARY KEY,
	name VARCHAR(30) NOT NULL,
	start_date DATE NOT NULL
);


-- Clinic epmployee <e_id> has the qualification <qualification> e.g.,
-- doctor of veterinary medicine.
CREATE TABLE Qualification (
	e_id INT REFERENCES Employee(e_id),
	qualification VARCHAR(200) NOT NULL,
	PRIMARY KEY (e_id, qualification)
);


-- A supply available at the clinic.
-- <name> is the supply's name.
-- <in_stock> is the number of units of the supply available.
-- <restricted> specifies whether the supply is restricted.
-- <reusable> specifies whether the supply is disposable.
CREATE TABLE Supply (
	s_id INT PRIMARY KEY,
	name VARCHAR(100) NOT NULL,
	in_stock INT NOT NULL CHECK (in_stock >= 0),
	restricted BOOLEAN NOT NULL,
	reusable BOOLEAN NOT NULL
);


-- A supply, that can be purchased by clients, whose price is <price>.
-- You may assume:
--	* A retail supply is a non-restricted supply.
CREATE TABLE RetailSupply (
	s_id INT PRIMARY KEY REFERENCES Supply(s_id),
	price REAL NOT NULL CHECK (price > 0.0)
);


-- A procedure at the clinic, with the name <name>.
CREATE TABLE Procedure (
	pr_id INT PRIMARY KEY,
	name VARCHAR(100) NOT NULL
);


-- An employee must have qualification <required_qual> to perform
-- the procedure <pr_id>.
-- You may assume:
--   * Each procedure requires at least one qualification
--     i.e., Procedure[pr_id] \subseteq ProcedureQualifications[pr_id].
CREATE TABLE ProcedureQualification (
	pr_id INT REFERENCES Procedure(pr_id),
	required_qual VARCHAR(200),
	PRIMARY KEY (pr_id, required_qual)
);


-- Procedure <pr_id> requires <quantity> units of supply <s_id>.
CREATE TABLE ProcedureSupply (
	pr_id INT REFERENCES Procedure(pr_id),
	s_id INT REFERENCES Supply(s_id),
	quantity INT NOT NULL CHECK (quantity > 0),
	PRIMARY KEY (pr_id, s_id)
);


-- An appointment is scheduled for patient <p_id> by employee
-- <scheduled_by> for date <scheduled_date>, from <start_time>
-- to <end_time>.
CREATE TABLE Appointment (
	a_id INT PRIMARY KEY,
	p_id INT NOT NULL REFERENCES Patient(p_id),
	scheduled_date DATE NOT NULL
		CHECK (EXTRACT(ISODOW FROM scheduled_date) < 6),
	start_time TIME NOT NULL CHECK (start_time >= TIME '06:00'),
	end_time TIME NOT NULL CHECK (end_time <= TIME '23:00'),
	scheduled_by INT NOT NULL REFERENCES Employee(e_id),
	CHECK (start_time < end_time),
	UNIQUE (p_id, scheduled_date, start_time)
);


-- The procedure <pr_id> will be performed as part of the appointment <a_id>,
-- in the order specified by <pr_order>.
-- You may assume:
-- 	* Every appointment in the Appointment relation has at least one procedure.
-- 	  i.e., Appointment[a_id] \subseteq ScheduledProcedure[a_id].
--  * Appointment <a_id> has exactly one procedure with <pr_order> value 1,
--    and subsequent values of <pr_order> for that <a_id> are sequential.
CREATE TABLE ScheduledProcedure (
	a_id INT REFERENCES Appointment(a_id),
	pr_id INT REFERENCES Procedure(pr_id),
	pr_order INT NOT NULL CHECK (pr_order >= 1),
	PRIMARY KEY (a_id, pr_order)
);


-- Employee <e_id> will perform the procedure <pr_id>,
-- as part of the appointment <a_id>.
-- You may assume:
--  * <a_id>, <pr_id> is in the ScheduledProcedure relation.
-- 	* At least one employee performs a procedure in an appointment.
--	  i.e., ScheduledProcedure[a_id, pr_id] \subseteq
--	  ScheduledProcedureStaff[a_id, pr_id].
--  * Employee <e_id> was hired on/prior to the appointment <a_id>'s date.
-- 	* Employee <e_id>'s appointments don't overlap.
--	* The qualifications required for <pr_id> are satisfied by at least
--    one staff member performing the procedure.
CREATE TABLE ScheduledProcedureStaff (
	a_id INT REFERENCES Appointment(a_id),
	pr_id INT REFERENCES Procedure(pr_id),
	e_id INT REFERENCES Employee(e_id),
	PRIMARY KEY (a_id, pr_id, e_id)
);
