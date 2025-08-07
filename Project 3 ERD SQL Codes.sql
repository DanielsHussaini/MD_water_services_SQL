/*  To integrate the auditor's report, we will need to access many of the tables in the database, so it is important to understand the database structure.
To do this we really need to understand the relationships first, so we know where to pull information from. Can you please get the ERD for the
md_water_services database? Spend a few minutes looking at the diagram.  */

DROP TABLE IF EXISTS `auditor_report`;
CREATE TABLE `auditor_report` (
`location_id` VARCHAR(32),
`type_of_water_source` VARCHAR(64),
`true_water_source_score` int DEFAULT NULL,
`statements` VARCHAR(255)
);

-- Chidis query
SELECT
auditor_report.location_id AS audit_location,
auditor_report.true_water_source_score,
visits.location_id AS visit_location,
visits.record_id
FROM
auditor_report
JOIN
visits
ON auditor_report.location_id = visits.location_id;


/*  We need to tackle a couple of questions here.
1. Is there a difference in the scores?
2. If so, are there patterns? For the first question, we will have to compare the quality scores in the water_quality table to the auditor's scores. The auditor_report table
used location_id, but the quality scores table only has a record_id we can use. The visits table links location_id and record_id, so we
can link the auditor_report table and water_quality using the visits table. */

SELECT 
    au.location_id,
    au.true_water_source_score AS auditor_score,
    wq.subjective_quality_score AS surveyor_score,
    v.record_id
FROM
    auditor_report AS au
        JOIN
    visits AS v ON au.location_id = v.location_id
        JOIN
    water_quality AS wq ON v.record_id = wq.record_id
    where  au.true_water_source_score =  wq.subjective_quality_score 
 and  v.visit_count = 1;
    

-- But that means that 102 records are incorrect. So let's look at those. You can do it by adding one character in the last query!
SELECT 
    au.location_id,
    au.true_water_source_score AS auditor_score,
    wq.subjective_quality_score AS surveyor_score,
    v.record_id
FROM
    auditor_report AS au
        JOIN
    visits AS v ON au.location_id = v.location_id
        JOIN
    water_quality AS wq ON v.record_id = wq.record_id
    where  au.true_water_source_score !=  wq.subjective_quality_score 
 and  v.visit_count = 1;
 
 -- So, to do this, we need to grab the type_of_water_source column from the water_source table and call it survey_source, using the
-- source_id column to JOIN. Also select the type_of_water_source from the auditor_report table, and call it auditor_source.

SELECT 
    au.location_id,
    au.type_of_water_source AS auditor_source,
    ws.type_of_water_source as surveyor_source,
    au.true_water_source_score AS auditor_score,
    wq.subjective_quality_score AS surveyor_score,
    v.record_id
FROM
    auditor_report AS au
        JOIN
    visits AS v ON au.location_id = v.location_id
        JOIN
    water_quality AS wq ON v.record_id = wq.record_id
        JOIN
    water_source AS ws ON v.source_id = ws.source_id
WHERE
    au.true_water_source_score != wq.subjective_quality_score
        AND v.visit_count = 1;

/*  Linking records to employees
Next up, let's look at where these errors may have come from. At some of the locations, employees assigned scores incorrectly, and those records
ended up in this results set.  */

/*  In either case, the employees are the source of the errors, so let's JOIN the assigned_employee_id for all the people on our list from the visits
table to our query. Remember, our query shows the shows the 102 incorrect records, so when we join the employee data, we can see which
employees made these incorrect records.  */

SELECT 
    au.location_id,
    em.assigned_employee_id,
    au.true_water_source_score AS auditor_score,
    wq.subjective_quality_score AS surveyor_score,
    v.record_id
FROM
    auditor_report AS au
        JOIN
    visits AS v ON au.location_id = v.location_id
        JOIN
    water_quality AS wq ON v.record_id = wq.record_id
        JOIN
    employee AS em ON v.assigned_employee_id = em.assigned_employee_id
WHERE
    au.true_water_source_score != wq.subjective_quality_score
        AND v.visit_count = 1;
        
-- So now we can link the incorrect records to the employees who recorded them. The ID's don't help us to identify them. We have employees' names
-- stored along with their IDs, so let's fetch their names from the employees table instead of the ID's.

SELECT 
    au.location_id,
    em.employee_name,
    au.true_water_source_score AS auditor_score,
    wq.subjective_quality_score AS surveyor_score,
    v.record_id
FROM
    auditor_report AS au
        JOIN
    visits AS v ON au.location_id = v.location_id
        JOIN
    water_quality AS wq ON v.record_id = wq.record_id
        JOIN
    employee AS em ON v.assigned_employee_id = em.assigned_employee_id
WHERE
    au.true_water_source_score != wq.subjective_quality_score
        AND v.visit_count = 1;

/*  Well this query is massive and complex, so maybe it is a good idea to save this as a CTE, so when we do more analysis, we can just call that CTE
like it was a table. Call it something  */

-- Let's first get a unique list of employees from this table. Think back to the start of your SQL journey to answer this one. I got 17 employees.

with incorrect_records as (

SELECT 
    au.location_id,
    em.employee_name,
    au.true_water_source_score AS auditor_score,
    wq.subjective_quality_score AS surveyor_score,
    v.record_id
FROM
    auditor_report AS au
        JOIN
    visits AS v ON au.location_id = v.location_id
        JOIN
    water_quality AS wq ON v.record_id = wq.record_id
        JOIN
    employee AS em ON v.assigned_employee_id = em.assigned_employee_id
WHERE
    au.true_water_source_score != wq.subjective_quality_score
        AND v.visit_count = 1
        limit 6
        )
        select * from incorrect_records;
        
-- Let's first get a unique list of employees from this table. Think back to the start of your SQL journey to answer this one. I got 17 employees.

with incorrect_records as (
SELECT 
    au.location_id,
    em.employee_name,
    au.true_water_source_score AS auditor_score,
    wq.subjective_quality_score AS surveyor_score,
    v.record_id
FROM
    auditor_report AS au
        JOIN
    visits AS v ON au.location_id = v.location_id
        JOIN
    water_quality AS wq ON v.record_id = wq.record_id
        JOIN
    employee AS em ON v.assigned_employee_id = em.assigned_employee_id
WHERE
    au.true_water_source_score != wq.subjective_quality_score
        AND v.visit_count = 1
      
        )

SELECT DISTINCT
    employee_name
FROM
    incorrect_records;

/*  Next, let's try to calculate how many mistakes each employee made. So basically we want to count how many times their name is in
Incorrect_records list, and then group them by name, right?  */

with incorrect_records as (
SELECT 
    au.location_id,
    em.employee_name,
    au.true_water_source_score AS auditor_score,
    wq.subjective_quality_score AS surveyor_score,
    v.record_id
FROM
    auditor_report AS au
        JOIN
    visits AS v ON au.location_id = v.location_id
        JOIN
    water_quality AS wq ON v.record_id = wq.record_id
        JOIN
    employee AS em ON v.assigned_employee_id = em.assigned_employee_id
WHERE
    au.true_water_source_score != wq.subjective_quality_score
        AND v.visit_count = 1
      
        )

SELECT DISTINCT
    employee_name,
    count(employee_name) as number_of_mistakes
FROM
    incorrect_records
group by employee_name
order by number_of_mistakes desc;


-- let's try to find all of the employees who have an above-average number of mistakes.

with incorrect_records as (
SELECT 
    au.location_id,
    em.employee_name,
    au.true_water_source_score AS auditor_score,
    wq.subjective_quality_score AS surveyor_score,
    v.record_id
FROM
    auditor_report AS au
        JOIN
    visits AS v ON au.location_id = v.location_id
        JOIN
    water_quality AS wq ON v.record_id = wq.record_id
        JOIN
    employee AS em ON v.assigned_employee_id = em.assigned_employee_id
WHERE
    au.true_water_source_score != wq.subjective_quality_score
        AND v.visit_count = 1
      
        ),
Error_count as (
SELECT 
    employee_name,
    count(employee_name) as number_of_mistakes
FROM
    incorrect_records
group by employee_name)
SELECT
AVG(number_of_mistakes) as Avg_error_count_per_emp
FROM
error_count;

/*  Finaly we have to compare each employee's error_count with avg_error_count_per_empl. We will call this results set our suspect_list.
Remember that we can't use an aggregate result in WHERE, so we have to use avg_error_count_per_empl as a subquery.  */

with incorrect_records as (
SELECT 
    au.location_id,
    em.employee_name,
    au.true_water_source_score AS auditor_score,
    wq.subjective_quality_score AS surveyor_score,
    v.record_id
FROM
    auditor_report AS au
        JOIN
    visits AS v ON au.location_id = v.location_id
        JOIN
    water_quality AS wq ON v.record_id = wq.record_id
        JOIN
    employee AS em ON v.assigned_employee_id = em.assigned_employee_id
WHERE
    au.true_water_source_score != wq.subjective_quality_score
        AND v.visit_count = 1
      
        )

SELECT DISTINCT
    employee_name,
    count(employee_name) as number_of_mistakes
FROM
    incorrect_records
group by employee_name
order by number_of_mistakes desc;


-- let's try to find all of the employees who have an above-average number of mistakes.

with incorrect_records as (
SELECT 
    au.location_id,
    em.employee_name,
    au.true_water_source_score AS auditor_score,
    wq.subjective_quality_score AS surveyor_score,
    v.record_id
FROM
    auditor_report AS au
        JOIN
    visits AS v ON au.location_id = v.location_id
        JOIN
    water_quality AS wq ON v.record_id = wq.record_id
        JOIN
    employee AS em ON v.assigned_employee_id = em.assigned_employee_id
WHERE
    au.true_water_source_score != wq.subjective_quality_score
        AND v.visit_count = 1
      
        ),
error_count as (
SELECT 
    employee_name,
    count(*) as number_of_mistakes
FROM
    incorrect_records
group by employee_name)
SELECT
employee_name, 
number_of_mistakes
FROM error_count
WHERE
number_of_mistakes > (select avg(number_of_mistakes) from  error_count);

/*We should look at the Incorrect_records table again, and isolate all of the records these four employees gathered. We should also look at the
statements for these records to look for patterns.*/

CREATE VIEW Incorrect_records AS
    (SELECT 
        v.location_id,
        v.record_id,
        e.employee_name,
        au.true_water_source_score AS auditor_score,
        wq.subjective_quality_score AS surveyor_score,
        au.statements AS statements
    FROM
        visits v
            JOIN
        auditor_report au ON v.location_id = au.location_id
            JOIN
        water_quality wq ON v.record_id = wq.record_id
        JOIN
        employee e ON v.assigned_employee_id = e.assigned_employee_id
    WHERE
        au.true_water_source_score != wq.subjective_quality_score
            AND v.visit_count = 1);
            
SELECT 
    *
FROM
    Incorrect_records;
            
-- Number of mistakes per employee

WITH error_count AS (
SELECT
	employee_name,
    count(employee_name) AS number_of_mistakes
FROM
	Incorrect_records
GROUP BY employee_name)
-- Query
SELECT 
	*
FROM
	error_count
ORDER BY number_of_mistakes DESC;

-- suspect list 
WITH error_count AS (
SELECT
	employee_name,
    count(employee_name) AS number_of_mistakes
FROM
	Incorrect_records
GROUP BY
	employee_name
    )
-- Query
SELECT
	AVG(number_of_mistakes) AS average_number_of_mistakes
FROM
	error_count;
WITH error_count AS (
SELECT 
	employee_name,
    count(employee_name) AS number_of_mistakes
FROM
	Incorrect_records
GROUP BY employee_name
)

-- QUery
SELECT
	employee_name,
    number_of_mistakes
FROM
	error_count
WHERE 
	number_of_mistakes > (SELECT AVG(number_of_mistakes) FROM error_count)
GROUP BY employee_name;


WITH error_count AS (
SELECT
	employee_name,
    count(employee_name) AS number_of_mistakes
FROM
	Incorrect_records
GROUP BY employee_name), -- calculates the number of mistakes each employee made
suspect_list AS(
SELECT
	employee_name,
    number_of_mistakes
FROM
	error_count
WHERE
	number_of_mistakes > (SELECT AVG(number_of_mistakes) FROM error_count))
-- Query
SELECT
	employee_name,
    location_id,
    statements
FROM
	Incorrect_records
WHERE
	employee_name IN (SELECT employee_name FROM suspect_list);
    
-- find mention of cash in statement
WITH error_count AS (
SELECT
	employee_name,
    count(employee_name) AS number_of_mistakes
FROM
	Incorrect_records
GROUP BY
	employee_name
    )
-- Query
SELECT
	AVG(number_of_mistakes) AS average_number_of_mistakes
FROM
	error_count;
WITH error_count AS (
SELECT 
	employee_name,
    count(employee_name) AS number_of_mistakes
FROM
	Incorrect_records
GROUP BY employee_name
)

-- QUery
SELECT
	employee_name,
    number_of_mistakes
FROM
	error_count
WHERE 
	number_of_mistakes > (SELECT AVG(number_of_mistakes) FROM error_count)
GROUP BY employee_name;


WITH error_count AS (
SELECT
	employee_name,
    count(employee_name) AS number_of_mistakes
FROM
	Incorrect_records
GROUP BY employee_name), -- calculates the number of mistakes each employee made
suspect_list AS(
SELECT
	employee_name,
    number_of_mistakes
FROM
	error_count
WHERE
	number_of_mistakes > (SELECT AVG(number_of_mistakes) FROM error_count))
-- Query
SELECT
	employee_name,
    location_id,
    statements
FROM
	Incorrect_records
WHERE
	employee_name IN (SELECT employee_name FROM suspect_list)
    and  statements like '%cash%'
    ;