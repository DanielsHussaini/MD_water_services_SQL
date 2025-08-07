/*Before we can analyse, we need to assemble data into a table first. It is quite complex, but once we're done, the analysis is much simpler!

07:55

Start by joining location to visits.*/

SELECT 
    l.province_name, l.town_name, l.location_id, v.visit_count
FROM
    location AS l
        JOIN
    visits AS v ON l.location_id = v.location_id;
    
    
    
-- Now, we can join the water_source table on the key shared between water_source and visits.
SELECT 
    l.province_name, l.town_name, l.location_id, v.visit_count,ws.type_of_water_source,ws.number_of_people_served
FROM
    location AS l
        JOIN
    visits AS v ON l.location_id = v.location_id
    join water_source as ws on ws.source_id=v.source_id
    ;

/* Note that there are rows where visit_count > 1. These were the sites our surveyors collected additional information for, but they happened at the
same source/location. For example, add this to your query: WHERE visits.location_id = 'AkHa00103' */
    SELECT 
    l.province_name, l.town_name, l.location_id, v.visit_count,ws.type_of_water_source,ws.number_of_people_served
FROM
    location AS l
        JOIN
    visits AS v ON l.location_id = v.location_id
    join water_source as ws on ws.source_id=v.source_id
    WHERE v.location_id = 'AkHa00103'
    ;
    
/*There you can see what I mean. For one location, there are multiple AkHa00103 records for the same location. If we aggregate, we will include
these rows, so our results will be incorrect. To fix this, we can just select rows where visits.visit_count = 1.
Remove WHERE visits.location_id = 'AkHa00103' and add the visits.visit_count = 1 as a filter.*/
  SELECT 
    l.province_name, l.town_name, l.location_id, v.visit_count,ws.type_of_water_source,ws.number_of_people_served
FROM
    location AS l
        JOIN
    visits AS v ON l.location_id = v.location_id
    join water_source as ws on ws.source_id=v.source_id
    WHERE v.visit_count = 1
    ;   
    
/*Ok, now that we verified that the table is joined correctly, we can remove the location_id and visit_count columns.
Add the location_type column from location and time_in_queue from visits to our results set.*/

SELECT 
    l.province_name, l.town_name,ws.type_of_water_source,ws.number_of_people_served,l.location_type,v.time_in_queue
FROM
    location AS l
        JOIN
    visits AS v ON l.location_id = v.location_id
    join water_source as ws on ws.source_id=v.source_id
    ;   
 /*Last one! Now we need to grab the results from the well_pollution table.
This one is a bit trickier. The well_pollution table contained only data for well. If we just use JOIN, we will do an inner join, so that only records
that are in well_pollution AND visits will be joined. We have to use a LEFT JOIN to join theresults from the well_pollution table for well
sources, and will be NULL for all of the rest. Play around with the different JOIN operations to make sure you understand why we used LEFT JOIN.*/
SELECT 
    l.province_name,
    l.town_name,
    ws.type_of_water_source,
    ws.number_of_people_served,
    l.location_type,
    v.time_in_queue,
    wp.results
FROM
    location AS l
        JOIN
    visits AS v ON l.location_id = v.location_id
        JOIN
    water_source AS ws ON ws.source_id = v.source_id
    left join well_pollution as wp on wp.source_id=v.source_id
;   

/*So this table contains the data we need for this analysis. Now we want to analyse the data in the results set. We can either create a CTE, and then
query it, or in my case, I'll make it a VIEW so it is easier to share with you. I'll call it the combined_analysis_table.*/
CREATE VIEW combined_analysis_table AS
    SELECT 
        l.province_name,
        l.town_name,
        ws.type_of_water_source,
        ws.number_of_people_served,
        l.location_type,
        v.time_in_queue,
        wp.results
    FROM
        location AS l
            JOIN
        visits AS v ON l.location_id = v.location_id
            JOIN
        water_source AS ws ON ws.source_id = v.source_id
            LEFT JOIN
        well_pollution AS wp ON wp.source_id = v.source_id
;   

/*The last analysis
We're building another pivot table! This time, we want to break down our data into provinces or towns and source types. If we understand where
the problems are, and what we need to improve at those locations, we can make an informed decision on where to send our repair teams.
We did most of this before, so I'll give you the queries I used, explain them a bit, and then we'll look at the results.
The queries I am sharing with you today are not formatted well because I am trying to fit them into my chat messages, but make sure you add com-
ments, and document your code well so you can use it again.*/

WITH province_totals AS (-- This CTE calculates the population of each province
SELECT
province_name,
SUM(number_of_people_served) AS total_ppl_serv
FROM
combined_analysis_table
GROUP BY
province_name
)
SELECT
ct.province_name,
-- These case statements create columns for each type of source.
-- The results are aggregated and percentages are calculated
ROUND((SUM(CASE WHEN type_of_water_source = 'river'
THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN type_of_water_source = 'shared_tap'
THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home'
THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home_broken'
THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN type_of_water_source = 'well'
THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS well
FROM
combined_analysis_table ct
JOIN
province_totals pt ON ct.province_name = pt.province_name
GROUP BY
ct.province_name
ORDER BY
ct.province_name;

 
-- province_totals is a CTE that calculates the sum of all the people surveyed grouped by province. If you replace the query above with this one:
SELECT
*
FROM
province_totals;


/*Let's aggregate the data per town now. You might think this is simple, but one little town makes this hard. Recall that there are two towns in Maji
Ndogo called Harare. One is in Akatsi, and one is in Kilimani. Amina is another example. So when we just aggregate by town, SQL doesn't distin-
guish between the different Harare's, so it combines their results.
To get around that, we have to group by province first, then by town, so that the duplicate towns are distinct because they are in different towns.*/
WITH town_totals AS (-- This CTE calculates the population of each province
	SELECT
		province_name, town_name,
		SUM(number_of_people_served) AS total_ppl_serv
	FROM
		combined_analysis_table
	GROUP BY
		province_name, town_name
	)
SELECT
	ct.province_name, ct.town_name,
	-- These case statements create columns for each type of source.
	-- The results are aggregated and percentages are calculated
	ROUND((SUM(CASE WHEN type_of_water_source = 'river'
				THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river,
	ROUND((SUM(CASE WHEN type_of_water_source = 'shared_tap'
				THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
	ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home'
				THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
	ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home_broken'
				THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
	ROUND((SUM(CASE WHEN type_of_water_source = 'well'
				THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well
FROM
	combined_analysis_table AS ct
JOIN
	town_totals AS tt ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name
GROUP BY
	ct.province_name, ct.town_name
ORDER BY
	ct.province_name;

/*CREATE TEMPORARY TABLE town_aggregated_water_access
WITH town_totals AS*/

CREATE TEMPORARY TABLE town_aggregated_water_access
WITH town_totals AS (
SELECT
		province_name, town_name,
		SUM(number_of_people_served) AS total_ppl_serv
	FROM
		combined_analysis_table
	GROUP BY
		province_name, town_name
	)
SELECT
	ct.province_name, ct.town_name,
	-- These case statements create columns for each type of source.
	-- The results are aggregated and percentages are calculated
	ROUND((SUM(CASE WHEN type_of_water_source = 'river'
				THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river,
	ROUND((SUM(CASE WHEN type_of_water_source = 'shared_tap'
				THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
	ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home'
				THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
	ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home_broken'
				THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
	ROUND((SUM(CASE WHEN type_of_water_source = 'well'
				THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well
FROM
	combined_analysis_table AS ct
JOIN
	town_totals AS tt ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name
GROUP BY
	ct.province_name, ct.town_name
ORDER BY
	ct.province_name;
    
SELECT * FROM town_aggregated_water_access
ORDER BY province_name;


/*There are still many gems hidden in this table. For example, which town has the highest ratio of people who have taps, but have no running water?
Running this:*/

SELECT
province_name,
town_name,
ROUND(tap_in_home_broken / (tap_in_home_broken + tap_in_home) *

100,0) AS Pct_broken_taps

FROM
town_aggregated_water_access;


-- A practical plan
CREATE TABLE Project_progress (
Project_id SERIAL PRIMARY KEY,
source_id VARCHAR(20) NOT NULL REFERENCES water_source(source_id) ON DELETE CASCADE ON UPDATE CASCADE,
Address VARCHAR(50),
Town VARCHAR(30),
Province VARCHAR(30),
Source_type VARCHAR(50),
Improvement VARCHAR(50),
Source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog', 'In progress', 'Complete')),
Date_of_completion DATE,
Comments TEXT
);

-- Project_progress_query

SELECT
location.address,
location.town_name,
location.province_name,
water_source.source_id,
water_source.type_of_water_source,
well_pollution.results
FROM
water_source
LEFT JOIN
well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
visits ON water_source.source_id = visits.source_id
INNER JOIN
location ON location.location_id = visits.location_id
WHERE
visits.visit_count = 1 -- This must always be true
AND ( -- AND one of the following (OR) options must be true as well.
well_pollution.results != 'Clean'
OR type_of_water_source IN ('tap_in_home_broken','...')
OR (type_of_water_source = 'shared_tap' AND time_in_queue >=30)
);


/*Use some control flow logic to create Install UV filter or Install RO filter values in the Improvement column where the results of the pollu-
tion tests were Contaminated: Biological and Contaminated: Chemical respectively. Think about the data you'll need, and which table to find
it in. Use ELSE NULL for the final alternative.*/


SELECT
	location.address,
	location.town_name,
	location.province_name,
	water_source.source_id,
	water_source.type_of_water_source,
	well_pollution.results,
    CASE
        WHEN
            (type_of_water_source = 'well'
                AND well_pollution.results = 'Contaminated: Chemical')
        THEN
            'Install RO filter'
        WHEN
            (type_of_water_source = 'well'
                AND well_pollution.results = 'Contaminated: Biological')
        THEN
            'Install UV and RO filter'
		WHEN type_of_water_source = 'river'
        THEN 'Drill well'
        WHEN type_of_water_source = 'shared_tap' AND time_in_queue >= 30 
        THEN CONCAT("Install ", FLOOR(time_in_queue/30), " taps nearby")
		WHEN type_of_water_source = 'tap_in_home_broken'
        THEN 'Diagnose local infrastructure'
		ELSE NULL
    END AS Improvement
FROM
	water_source
LEFT JOIN
	well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
	visits ON water_source.source_id = visits.source_id
INNER JOIN
	location ON location.location_id = visits.location_id
WHERE
	visits.visit_count = 1 -- This must always be true
		AND ( -- AND one of the following (OR) options must be true as well.
		results != 'Clean'
		OR type_of_water_source IN ('tap_in_home_broken','river')
		OR (type_of_water_source = 'shared_tap' AND time_in_queue >= 30)
);

/*Now that we have the data we want to provide to engineers, populate the Project_progress table with the results of our query.
HINT: Make sure the columns in the query line up with the columns in Project_progress. If you make any mistakes, just use DROP TABLE
project_progress, and run your query again.*/

select * from Project_progress;

DESCRIBE Project_progress;



INSERT INTO Project_progress (
  address,
  town,
  province,
  source_id,
 source_type,
  improvement
)
SELECT
	location.address as Address,
	location.town_name as Town,
	location.province_name as Province,
	water_source.source_id as Source_id,
	water_source.type_of_water_source as Source_type,
	
    CASE
        WHEN
            (type_of_water_source = 'well'
                AND well_pollution.results = 'Contaminated: Chemical')
        THEN
            'Install RO filter'
        WHEN
            (type_of_water_source = 'well'
                AND well_pollution.results = 'Contaminated: Biological')
        THEN
            'Install UV and RO filter'
		WHEN type_of_water_source = 'river'
        THEN 'Drill well'
        WHEN type_of_water_source = 'shared_tap' AND time_in_queue >= 30 
        THEN CONCAT("Install ", FLOOR(time_in_queue/30), " taps nearby")
		WHEN type_of_water_source = 'tap_in_home_broken'
        THEN 'Diagnose local infrastructure'
		ELSE NULL
    END AS Improvement
FROM
	water_source
LEFT JOIN
	well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
	visits ON water_source.source_id = visits.source_id
INNER JOIN
	location ON location.location_id = visits.location_id
WHERE
	visits.visit_count = 1
	AND (
		results != 'Clean'
		OR type_of_water_source IN ('tap_in_home_broken','river')
		OR (type_of_water_source = 'shared_tap' AND time_in_queue >= 30)
	);
