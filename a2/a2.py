"""CSC343 Assignment 2

=== CSC343 Fall 2024 ===
Department of Computer Science,
University of Toronto

This code is provided solely for the personal and private use of
students taking the CSC343 course at the University of Toronto.
Copying for purposes other than this use is expressly prohibited.
All forms of distribution of this code, whether as given or with
any changes, are expressly prohibited.

Authors: Jacqueline Smith and Marina Tawfik

All of the files in this directory and all subdirectories are:
Copyright (c) 2024

=== Module Description ===

This file contains the VetClinic class and some simple testing functions.
"""

import os.path
from typing import Optional
from dataclasses import dataclass
from datetime import date
from datetime import datetime, time
import psycopg2 as pg
import psycopg2.extensions as pg_ext


class VetClinic:
    """A class that can work with data conforming to the schema used in A2.

    === Instance Attributes ===
    connection: connection to a PostgreSQL database of Markus-related
        information.

    Representation invariants:
    - The database to which <connection> holds a reference conforms to the
      schema used in A2.
    """

    connection: Optional[pg_ext.connection]

    def __init__(self) -> None:
        """Initialize this VetClinic instance, with no database connection
        yet.
        """
        self.connection = None

    def connect(self, dbname: str, username: str, password: str) -> bool:
        """Establish a connection to the database <dbname> using the
        username <username> and password <password>, and assign it to the
        instance attribute <connection>. In addition, set the search path
        to A2VetClinic.

        Return True if the connection was made successfully, False otherwise.
        I.e., do NOT throw an error if making the connection fails.

        >>> a2 = VetClinic()
        >>> # The following example will only work if you change the dbname
        >>> # and password to your own credentials.
        >>> a2.connect("csc343h-madaran4", "madaran4", "")
        True
        >>> # In this example, the connection cannot be made.
        >>> a2.connect("invalid", "nonsense", "incorrect")
        False
        """
        try:
            self.connection = pg.connect(
                dbname=dbname,
                user=username,
                password=password,
                options="-c search_path=A2VetClinic",
            )
            return True
        except pg.Error:
            return False

    def disconnect(self) -> bool:
        """Close this instance's connection to the database.

        Return True if closing the connection was successful, False otherwise.
        I.e., do NOT throw an error if closing the connection fails.

        >>> a2 = VetClinic()
        >>> # The following example will only work if you change the dbname
        >>> # and password to your own credentials.
        >>> a2.connect("csc343h-madaran4", "madaran4", "")
        True
        >>> a2.disconnect()
        True
        """
        try:
            if self.connection and not self.connection.closed:
                self.connection.close()
            return True
        except pg.Error:
            return False

    def calculate_vacation_credit(self, day: date) -> dict[str, float]:
        """Return a mapping of employees to their accumulative vacation credit
        as of date <day>.

        The key of the mapping should be of the form "name (e_id)" e.g.,
        "Marina Tawfik (20)". The value is the vacation credit, accumulated by
        <day>. This value can be calculated as follows:

        + Calculate the number of months that the employee would have worked by
          <day>, based on their start_date. For simplicity, we will only
          consider the resolution at the level of months e.g., an employee who
          started on 2024-02-01 would be considered to have worked 0 months by
          2024-02-29, but would have worked 1 month by 2024-03-01.
          An employee hired after <day> would have worked 0 months.

        + The vacation credit is calculated based on the number of months:
            First 75 months              |   1.25 days per month
            For the next 76-150 months   |   1.5 days per month
            For the next 151-225 months  |   1.75 days per month
            226+ months                  |   2.0 days per month
          so an employee who worked a total of 80 months would be entitled to:
          (75 * 1.25) + ((80 - 75) * 1.5) = 101.25 days

        NOTE: Don't round your result.

        Return an empty dictionary if the operation was unsuccessful i.e.,
        your method should NOT throw an error.
        """
        if not self.connection:
            return {}

        try:
            with self.connection.cursor() as cursor:
                # Step 1: Fetch all employees and their start dates
                cursor.execute("SELECT e_id, name, start_date FROM Employee;")
                employees = cursor.fetchall()

                result = {}

                # Step 2: Calculate months worked and vacation credit for each employee
                for e_id, name, start_date in employees:
                    # If the start date is after the given day, the employee worked 0 months
                    if start_date > day:
                        months_worked = 0
                    else:
                        # Calculate the number of months between start_date and the given day
                        months_worked = (day.year - start_date.year) * 12 + (
                            day.month - start_date.month
                        )
                        if day.day < start_date.day:
                            months_worked -= 1  # Only count complete months

                    # Step 3: Calculate vacation credit
                    if months_worked <= 0:
                        vacation_credit = 0.0
                    else:
                        if months_worked > 225:
                            vacation_credit = (
                                (75 * 1.25)
                                + (75 * 1.5)
                                + (75 * 1.75)
                                + ((months_worked - 225) * 2.0)
                            )
                        elif months_worked > 150:
                            vacation_credit = (
                                (75 * 1.25)
                                + (75 * 1.5)
                                + ((months_worked - 150) * 1.75)
                            )
                        elif months_worked > 75:
                            vacation_credit = (75 * 1.25) + ((months_worked - 75) * 1.5)
                        else:
                            vacation_credit = months_worked * 1.25

                    # Step 4: Add the employee and their vacation credit to the result
                    result[f"{name} ({e_id})"] = vacation_credit

                return result

        except pg.Error:
            return {}

    def record_employee(self, name: str, qualifications: list[str]) -> int:
        """Record the employee with name <name>, who has zero or more
        qualifications <qualifications> by updating the Employee and
        Qualification relations appropriately.
        The employee id is 1 + the maximum current e_id.
        The employee start date is the current date.

        Return the employee id of the new hire, or -1 if the operation was
        unsuccessful i.e., your method should NOT throw an error.

        Note: The qualifications in <qualifications> needn't appear in the
        ProcedureQualification relation.
        """
        if not self.connection:
            return -1

        try:
            with self.connection.cursor() as cursor:
                # Step 1: Find the current maximum e_id and calculate new e_id
                cursor.execute("SELECT COALESCE(MAX(e_id), 0) + 1 FROM Employee;")
                new_e_id = cursor.fetchone()[0]

                # Step 2: Insert the new employee into the Employee table
                cursor.execute(
                    "INSERT INTO Employee (e_id, name, start_date) VALUES (%s, %s, CURRENT_DATE);",
                    (new_e_id, name),
                )

                # Step 3: Insert qualifications into the Qualification table
                for qualification in qualifications:
                    cursor.execute(
                        "INSERT INTO Qualification (e_id, qualification) VALUES (%s, %s);",
                        (new_e_id, qualification),
                    )

                # Step 4: Commit the transaction
                self.connection.commit()
                return new_e_id

        except pg.Error:
            # If something goes wrong, roll back the transaction
            self.connection.rollback()
            return -1

    def reschedule_appointments(self, e_id: int, orig_day: date, new_day: date) -> int:
        if not self.connection:
            return 0

        try:
            with self.connection.cursor() as cursor:
                # Step 1: Check if the employee exists
                cursor.execute("SELECT COUNT(*) FROM Employee WHERE e_id = %s", (e_id,))
                if cursor.fetchone()[0] == 0:
                    return 0  # e_id is not valid

                # Step 2: Get target appointments where employee e_id worked on orig_day
                cursor.execute(
                    """
                    SELECT a.a_id, a.start_time, a.end_time, a.p_id
                    FROM Appointment a
                    JOIN ScheduledProcedureStaff sps ON a.a_id = sps.a_id
                    WHERE sps.e_id = %s AND a.scheduled_date = %s
                    ORDER BY a.start_time;
                """,
                    (e_id, orig_day),
                )
                target_appointments = cursor.fetchall()

                if not target_appointments:
                    return 0  # No appointments found

                rescheduled_count = 0
                available_time = datetime.combine(
                    new_day, time(6, 0)
                )  # Start from 6:00 AM

                for appointment in target_appointments:
                    a_id, start_time, end_time, p_id = (
                        appointment  # Fetching the appointment details
                    )

                    # Step 3: Convert start_time and end_time to datetime objects
                    start_datetime = datetime.combine(new_day, start_time)
                    end_datetime = datetime.combine(new_day, end_time)
                    duration = end_datetime - start_datetime

                    # Try to reschedule the appointment, looking for a free time slot
                    while available_time.time() <= time(
                        23, 0
                    ):  # Ensure we stay within the day's bounds
                        # Step 4: Check availability on new_day for both employee and patient
                        cursor.execute(
                            """
                            SELECT COUNT(*)
                            FROM Appointment
                            WHERE scheduled_date = %s
                            AND (
                                (start_time, end_time) OVERLAPS (%s, %s)
                                OR p_id = %s
                            );
                        """,
                            (
                                new_day,
                                available_time.time(),
                                (available_time + duration).time(),
                                p_id,
                            ),
                        )

                        # Step 5: If no conflicts, reschedule the appointment
                        if cursor.fetchone()[0] == 0:
                            # No conflict, so we can reschedule the appointment
                            cursor.execute(
                                """
                                UPDATE Appointment
                                SET scheduled_date = %s, start_time = %s, end_time = %s
                                WHERE a_id = %s;
                            """,
                                (
                                    new_day,
                                    available_time.time(),
                                    (available_time + duration).time(),
                                    a_id,
                                ),
                            )

                            # Update the staff assignments for the appointment
                            cursor.execute(
                                """
                                UPDATE ScheduledProcedureStaff
                                SET a_id = %s
                                WHERE a_id = %s;
                            """,
                                (a_id, a_id),
                            )

                            # Move available_time forward by the duration of the appointment
                            available_time += duration
                            rescheduled_count += 1
                            break  # Move on to the next appointment

                        # If there's a conflict, move the available time forward and check again
                        available_time += duration

                # Commit the changes to the database
                self.connection.commit()

                return rescheduled_count

        except pg.Error:
            self.connection.rollback()
            return 0


def setup(
    dbname: str, username: str, password: str, schema_path: str, data_path: str
) -> None:
    """Set up the testing environment for the database <dbname> using the
    username <username> and password <password> by importing the schema file
    at <schema_path> and the file containing the data at <data_path>.

    <schema_path> and <data_path> are the relative/absolute paths to the files
    containing the schema and the data respectively.
    """
    connection, cursor, schema_file, data_file = None, None, None, None
    try:
        connection = pg.connect(
            dbname=dbname,
            user=username,
            password=password,
            options="-c search_path=A2VetClinic",
        )
        cursor = connection.cursor()

        with open(schema_path, "r") as schema_file:
            cursor.execute(schema_file.read())

        with open(data_path, "r") as info_file:
            for line in info_file:
                line_elems = line.split()
                table_name = line_elems[1].lower()
                file_path = line_elems[3].strip("'")
                with open(file_path, "r") as data_file:
                    cursor.copy_from(data_file, table_name, sep=",")
        connection.commit()
    except Exception as ex:
        connection.rollback()
        raise Exception(f"Couldn't set up environment for tests: \n{ex}")
    finally:
        if cursor and not cursor.closed:
            cursor.close()
        if connection and not connection.closed:
            connection.close()


def test_basics() -> None:
    """Test basic aspects of the A2 methods."""
    # TODO: Change to your username here to connect to your own database:
    dbname = "csc343h-madaran4"
    user = "madaran4"
    password = ""

    # The following uses the relative paths to the schema file and the data file
    # we have provided. For your own tests, you will want to make your own data
    # files to use for testing.
    schema_file = "./a2_vet_schema.ddl"
    data_file = "./populate_data.sql"

    a2 = VetClinic()
    try:
        connected = a2.connect(dbname, user, password)

        # The following is an assert statement. It checks that the value for
        # connected is True. The message after the comma will be printed if
        # that is not the case (that is, if connected is False).
        # Use the same notation throughout your testing.
        assert connected, f"[Connect] Expected True | Got {connected}."

        # The following function call will set up the testing environment by
        # loading a fresh copy of the schema and the sample data we have
        # provided into your database. You can create more sample data files
        # and call the same function to load them into your database.
        # Or, if you want to set up the database yourself outside of Python,
        # comment out the following line.
        setup(dbname, user, password, schema_file, data_file)

        # --------------------- Testing record_employee ---------------------- #

        # Note: These results assume that the instance has already been
        # populated with the provided data e.g., using the setup function.
        # You will also need to manually check the contents of your instance to
        # make sure it was updated correctly.

        # No qualifications
        expected = 37
        e_id = a2.record_employee("Marina Tawfik", [])
        assert e_id == expected, f"[record_employee] Expected {expected} - Got {e_id}"

        # One qualification
        expected = 38
        e_id = a2.record_employee(
            "Sophia Huynh", ["Registered Veterinary Technician (RVT)"]
        )
        assert e_id == expected, f"[record_employee] Expected {expected} - Got {e_id}"

        # Two qualifications
        expected = 39
        e_id = a2.record_employee(
            "Jacqueline Smith",
            [
                "Registered Veterinary Technician (RVT)",
                "Doctor of Veterinary Medicine (DVM)",
            ],
        )
        assert e_id == expected, f"[record_employee] Expected {expected} - Got {e_id}"

        # ---------------- Testing calculate_vacation_credit ----------------- #

        # Note: These results assume that the instance has already been
        # populated with the provided data e.g., using the setup function.
        # Since we run all tests in the same function, the instance has been
        # changed by the above tests.

        # Since the result for this would be quite large, we have only checked
        # for a few entries in teh dictionary.
        vacation_days = a2.calculate_vacation_credit(date(2011, 9, 14))

        # Hired after the specified day
        expected = 0
        vacation_res = vacation_days.get("Jack Sigmon (18)", -1)
        assert vacation_res == expected, (
            f"[calculate_vacation_credit] Expected {expected} - " f"Got {vacation_res}"
        )

        # Hired on the specified day
        expected = 0
        vacation_res = vacation_days.get("Walter Shindle (24)", -1)
        assert vacation_res == expected, (
            f"[calculate_vacation_credit] Expected {expected} - " f"Got {vacation_res}"
        )

        # Hired before the specified day
        expected = 105.75
        vacation_res = vacation_days.get("Carolyn Bliss (1)", -1)
        assert vacation_res == expected, (
            f"[calculate_vacation_credit] Expected {expected} - " f"Got {vacation_res}"
        )

        # ----------------- Testing reschedule_appointments ------------------ #

        # Note: These results assume that the instance has already been
        # populated with the provided data e.g., using the setup function and
        # the data files provided in the starter code.
        # Since we run all tests in the same function, the instance has been
        # changed by the above tests.
        # Note that you will still need to inspect the database to ensure that
        # the changes are reflected there.

        # Two appointments to re-schedule. Target day has some appointments
        # already scheduled.
        expected = 2
        num_sched = a2.reschedule_appointments(
            1, date(2024, 11, 15), date(2024, 11, 20)
        )
        assert num_sched == expected, (
            f"[reschedule_appointments] Expected {expected} - " f"Got {num_sched}"
        )
    finally:
        a2.disconnect()


if __name__ == "__main__":
    # Un comment-out the next two lines if you would like to run the doctest
    # examples (see ">>>" in the methods connect and disconnect)
    import doctest

    doctest.testmod()

    # TODO: Put your testing code here, or call testing functions like this one:
    test_basics()
