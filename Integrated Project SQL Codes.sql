
SELECT 
*
FROM 
data_dictionary;

-- Ok, bring up the employee table. It has info on all of our workers, but note that the email addresses have not been added. We will have to send
-- them reports and figures, so let's update it. Luckily the emails for our department are easy: first_name.last_name@ndogowater.gov.
SELECT
*
FROM
employee;

/*We can determine the email address for each employee by:
- selecting the employee_name column
- replacing the space with a full stop
- make it lowercase
- and stitch it all together */

SELECT 
CONCAT (LOWER (replace (employee_name,' ','.')),'@ndogowater.gov') 
FROM
employee;

update
employee
set email = CONCAT (LOWER (replace (employee_name,' ','.')),'@ndogowater.gov');

set session sql_safe_updates = off;

SELECT
LENGTH(phone_number)
FROM
employee;

UPDATE employee 
SET 
    phone_number = trim(phone_number);
    
/*Use the employee table to count how many of our employees live in each town. Think carefully about what function we should use and how we
should aggregate the data.  */

select town_name, count(*) as number_of_employees
from employee
group by town_name ;

/* Let's first look at the number of records each employee collected. So find the correct table, figure out what function to use and how to group, order
and limit the results to only see the top 3 employee_ids with the highest number of locations visited. */

select * from visits;

SELECT 
    assigned_employee_id, COUNT(*) AS number_of_visits
FROM
    visits
GROUP BY assigned_employee_id
ORDER BY number_of_visits DESC
LIMIT 3;

/* Make a note of the top 3 assigned_employee_id and use them to create a query that looks up the employee's info. Since you're a pro at finding
stuff in a database now, you can figure this one out. You should have a column of names, email addresses and phone numbers for our top dogs.  */

SELECT 
    employee_name, email, phone_number
FROM
    employee
where
assigned_employee_id in  (1,30,34) ;

/*  Looking at the location table, let’s focus on the province_name, town_name and location_type to understand where the water sources are in
Maji Ndogo.  */

select province_name, town_name , location_type
from location;

/*  Create a query that counts the number of records per town  */

select town_name, count(*) as number_of_records
from location
group by town_name
order by number_of_records desc;

-- Now count the records per province.

select province_name, count(*) as number_of_records
from location
group by province_name
order by number_of_records desc;

/*   Can you find a way to do the following:
1. Create a result set showing:
• province_name
• town_name
• An aggregated count of records for each town (consider naming this records_per_town).
• Ensure your data is grouped by both province_name and town_name.
2. Order your results primarily by province_name. Within each province, further sort the towns by their record counts in descending order.   */

SELECT 
    province_name, town_name, COUNT(*) AS records_per_town
FROM
    location
GROUP BY province_name , town_name
ORDER BY province_name , records_per_town DESC;

-- Finally, look at the number of records for each location type

select location_type, count(*) as number_of_records
from location
group by location_type;

/* We can see that there are more rural sources than urban, but it's really hard to understand those numbers. Percentages are more relatable.
If we use SQL as a very overpowered calculator: */

SELECT ROUND(23740 / (15910 + 23740) * 100) AS percentages_of_water_sorces_in_rural_comm;

/*   These are the questions that I am curious about.
1. How many people did we survey in total?
2. How many wells, taps and rivers are there?
3. How many people share particular types of water sources on average?
4. How many people are getting water from each type of source?   */

-- 1. How many people did we survey in total?
SELECT SUM(number_of_people_served) AS total_people_surveyed
FROM water_source;

-- 2 How many wells, taps and rivers are there?
SELECT type_of_water_source, COUNT(*) AS total_sources
FROM water_source
WHERE type_of_water_source IN ('Well', 'Tap', 'River','tap_in_home_broken','tap_in_home','shared_tap' )
GROUP BY type_of_water_source;

-- TUTORIAL 
SELECT type_of_water_source, COUNT(*) AS total_sources
FROM water_source
GROUP BY type_of_water_source
ORDER BY type_of_water_source desc ;



-- 3. How many people share particular types of water sources on average?
SELECT type_of_water_source, AVG(number_of_people_served) AS avg_people_per_source
FROM water_source
GROUP BY type_of_water_source;

SELECT type_of_water_source, 
    ROUND(AVG(number_of_people_served)) AS Avg_people_per_source
FROM
    water_source
GROUP BY type_of_water_source;



-- 4. How many people are getting water from each type of source? 
SELECT 
  type_of_water_source, 
  SUM(number_of_people_served) AS total_people
FROM visits
JOIN water_source ON visits.source_id = water_source.source_id
GROUP BY type_of_water_source;

SELECT 
    type_of_water_source,
    SUM(number_of_people_served) AS Total_people_served
FROM
    water_source
GROUP BY type_of_water_source
ORDER BY Total_people_served DESC;


/*   It's a little hard to comprehend these numbers, but you can see that one of these is dominating. To make it a bit simpler to interpret, let's use
percentages. First, we need the total number of citizens then use the result of that and divide each of the SUM(number_of_people_served) by
that number, times 100, to get percentages.

Make a note of the number of people surveyed in the first question we answered. I get a total of about 27 million citizens!

Next, calculate the percentages using the total we just got.   */

-- TUTORIAL 
SELECT 
    type_of_water_source,
    Round((SUM(number_of_people_served) / (SELECT 
            SUM(number_of_people_served)
        FROM
            water_source)) * 100) AS percentage_people_served
FROM
    water_source
GROUP BY type_of_water_source
ORDER BY percentage_people_served DESC;


/*   At some point, we will have to fix or improve all of the infrastructure, so we should start thinking about how we can make a data-driven decision
how to do it. I think a simple approach is to fix the things that affect most people first. So let's write a query that ranks each type of source based
on how many people in total use it. RANK() should tell you we are going to need a window function to do this, so let's think through the problem.    */



-- So use a window function on the total people served column, converting it into a rank.
-- TUTORIAL 
select 
type_of_water_source, SUM(number_of_people_served) AS Total_people_served, 
rank() over (order by SUM(number_of_people_served) desc) as Rank_of_population_served
from water_source
where type_of_water_source != 'tap_in_home'  
group by type_of_water_source ;

/*   So create a query to do this, and keep these requirements in mind:
1. The sources within each type should be assigned a rank.
2. Limit the results to only improvable sources.
3. Think about how to partition, filter and order the results set.
4. Order the results to see the top of the list.   */

/* ────────────────────────────────────────────────────────────────
   RANK improvable sources by the number of people they serve
   ──────────────────────────────────────────────────────────────── */

select 
* ,
rank() over (partition by type_of_water_source order by number_of_people_served desc) as Rank_as_priority
from water_source
where type_of_water_source != 'tap_in_home' 
order by type_of_water_source, number_of_people_served desc;

/*     Ok, these are some of the things I think are worth looking at:
1. How long did the survey take?
2. What is the average total queue time for water?
3. What is the average queue time on different days?
4. How can we communicate this information efficiently?     */

/*  Question 1:
To calculate how long the survey took, we need to get the first and last dates (which functions can find the largest/smallest value), and subtract
them. Remember with DateTime data, we can't just subtract the values. We have to use a function to get the difference in days.  */

-- FIRST DATE
SELECT 
    MIN(time_of_record) as First_date
FROM
    visits;

-- LAST DATE
SELECT max(time_of_record) as Last_date
from visits;

-- TOTAL SURVEY DAYS
 select
 datediff(max(time_of_record),min(time_of_record)) as Total_survey_dates
from visits;

/*Question 2:
Let's see how long people have to queue on average in Maji Ndogo. Keep in mind that many sources like taps_in_home have no queues. These
are just recorded as 0 in the time_in_queue column, so when we calculate averages, we need to exclude those rows. Try using NULLIF() do to
this.*/

Select round(avg(nullif(time_in_queue,0))) as Avg_time_in_queue_min
from visits;

/*  Question 3:
So let's look at the queue times aggregated across the different days of the week.  */



SELECT 
    DAYNAME(time_of_record) AS day_of_week,
    ROUND(AVG(NULLIF(time_in_queue, 0))) AS Avg_time_in_queue_min
FROM
    visits
group by day_of_week
order by Avg_time_in_queue_min desc ;

/*  Question 4:
We can also look at what time during the day people collect water. Try to order the results in a meaningful way.  */

SELECT 
    TIME_FORMAT(STR_TO_DATE(HOUR(time_of_record), '%H'),
            '%H:00') AS Hour_of_day,
    ROUND(AVG(NULLIF(time_in_queue, 0))) AS Avg_time_in_queue_min
FROM
    visits
GROUP BY Hour_of_day
ORDER BY Hour_of_day;

/*  Ok, so here's your challenge: Fill out the query for the rest of the days, and run it. Make sure to specify the day in the CASE() function, and the
alias.  */

SELECT 
    TIME_FORMAT(TIME(time_of_record) , '%H:00') AS Hour_of_day,
    ROUND(AVG(CASE
                WHEN DAYNAME(time_of_record) = 'Sunday' THEN time_in_queue
                ELSE NULL
            END),
            0) AS Sunday,
    ROUND(AVG(CASE
                WHEN DAYNAME(time_of_record) = 'Monday' THEN time_in_queue
                ELSE NULL
            END),
            0) AS Monday,
    ROUND(AVG(CASE
                WHEN DAYNAME(time_of_record) = 'Tuesday' THEN time_in_queue
                ELSE NULL
            END),
            0) AS Tuesday,
    ROUND(AVG(CASE
                WHEN DAYNAME(time_of_record) = 'Wednesday' THEN time_in_queue
                ELSE NULL
            END),
            0) AS Wednesday,
    ROUND(AVG(CASE
                WHEN DAYNAME(time_of_record) = 'Thursday' THEN time_in_queue
                ELSE NULL
            END),
            0) AS Thursday,
    ROUND(AVG(CASE
                WHEN DAYNAME(time_of_record) = 'Friday' THEN time_in_queue
                ELSE NULL
            END),
            0) AS Friday,
    ROUND(AVG(CASE
                WHEN DAYNAME(time_of_record) = 'Saturday' THEN time_in_queue
                ELSE NULL
            END),
            0) AS Saturday
FROM
    visits
WHERE
    time_in_queue != 0
GROUP BY Hour_of_day
ORDER BY Hour_of_day;


SELECT 
  CONCAT(
    LPAD(DAY(time_of_record), 2, '0'), ' ',
    MONTHNAME(time_of_record), ' ',
    YEAR(time_of_record)
  ) AS formatted_date
FROM visits;

/*  What are the names of the two worst-performing employees who visited the fewest sites, and how many sites did the
 worst-performing employee visit? Modify your queries from the “Honouring the workers” section.  */
 
 
 SELECT 
    assigned_employee_id, COUNT(DISTINCT source_id) AS worse_sites_visited
FROM
    visits

GROUP BY assigned_employee_id
ORDER BY worse_sites_visited ASC
LIMIT 2;
 
select count(location_id)
from visits
where assigned_employee_id = 20 ;

select count(location_id)
from visits
where assigned_employee_id = 22 ;


SELECT 
    location_id,
    time_in_queue,
    AVG(time_in_queue) OVER (PARTITION BY location_id ORDER BY visit_count) AS total_avg_queue_time
FROM 
    visits
WHERE 
visit_count > 1 -- Only shared taps were visited > 1
ORDER BY 
    location_id, time_of_record;
    
select town_name, count(*) as number_of_employees
from employee
where  town_name ='Kilimani' and   town_name =
group by town_name ;
