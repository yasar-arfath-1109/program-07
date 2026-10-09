#!/bin/bash

MYSQL="mysql -h127.0.0.1 -P3306 -uroot -proot"

echo "========================================"
echo " Marksheet SQL Assignment"
echo "========================================"

if [ ! -f "student_solution.sql" ]; then
    echo "FAIL: student_solution.sql file not found."
    exit 1
fi

echo "Creating fresh CollegeDB database..."

$MYSQL -e "DROP DATABASE IF EXISTS CollegeDB;"
$MYSQL -e "CREATE DATABASE CollegeDB;"

echo "Executing student_solution.sql..."

if ! $MYSQL CollegeDB < student_solution.sql; then
    echo "FAIL: Error while executing student_solution.sql"
    exit 1
fi

echo ""
echo "Checking Marksheet table..."
echo ""

MARKS=0

# Test 1: Table exists
TABLE=$($MYSQL -N -s CollegeDB -e "
SELECT COUNT(*)
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA='CollegeDB'
AND TABLE_NAME='Marksheet';
")

if [ "$TABLE" -eq 1 ]; then
    echo "PASS: Marksheet table exists."
    MARKS=$((MARKS+2))
else
    echo "FAIL: Marksheet table was not created."
    exit 1
fi

# Test 2: Required columns exist
COLUMNS=$($MYSQL -N -s CollegeDB -e "
SELECT COUNT(*)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='CollegeDB'
AND TABLE_NAME='Marksheet'
AND COLUMN_NAME IN ('RollNo','Name','Department','Marks');
")

if [ "$COLUMNS" -eq 4 ]; then
    echo "PASS: All required columns exist."
    MARKS=$((MARKS+2))
else
    echo "FAIL: Required columns are missing."
fi

# Test 3: All 5 records inserted
RECORDS=$($MYSQL -N -s CollegeDB -e "
SELECT COUNT(*)
FROM Marksheet;
")

if [ "$RECORDS" -eq 5 ]; then
    echo "PASS: All 5 records inserted."
    MARKS=$((MARKS+2))
else
    echo "FAIL: Expected 5 records, found $RECORDS."
fi

# Test 4: Students with marks > 80
HIGH_MARKS=$($MYSQL -N -s CollegeDB -e "
SELECT COUNT(*)
FROM Marksheet
WHERE Marks > 80;
")

if [ "$HIGH_MARKS" -eq 3 ]; then
    echo "PASS: Correct students found with Marks > 80."
    MARKS=$((MARKS+2))
else
    echo "FAIL: Incorrect records for Marks > 80."
fi

# Test 5: Verify expected students
EXPECTED=$($MYSQL -N -s CollegeDB -e "
SELECT GROUP_CONCAT(Name ORDER BY Marks DESC SEPARATOR ',')
FROM Marksheet
WHERE Marks > 80;
")

if [ "$EXPECTED" = "Karthik,Rahul,Arun" ]; then
    echo "PASS: Correct descending order: Karthik, Rahul, Arun."
    MARKS=$((MARKS+2))
else
    echo "FAIL: Expected descending order is Karthik, Rahul, Arun."
fi

echo ""
echo "========================================"
echo "Students with Marks Greater Than 80"
echo "========================================"

$MYSQL CollegeDB -e "
SELECT *
FROM Marksheet
WHERE Marks > 80
ORDER BY Marks DESC;
"

echo ""
echo "========================================"
echo "Total Marks: $MARKS / 10"
echo "========================================"

if [ "$MARKS" -eq 10 ]; then
    echo "SUCCESS: All test cases passed."
    exit 0
else
    echo "Some test cases failed."
    exit 1
fi
