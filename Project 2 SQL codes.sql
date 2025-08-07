-- Joining pieces together
SELECT 
    l.province_name, 
    l.town_name,
    ws.type_of_water_source,
    l.location_type,
    ws.number_of_people_served,
    v.time_in_queue,
    wp.results
FROM
    location AS l
        JOIN
    visits AS v ON l.location_id = v.location_id
		JOIN
	water_source AS ws ON v.source_id = ws.source_id
		LEFT JOIN
	well_pollution AS wp ON v.source_id = wp.source_id
WHERE v.visit_count = 1;

CREATE VIEW combined_analysis_table AS
-- This view assembles data from different tables into one to simplify analysis
SELECT 
    l.province_name, 
    l.town_name,
    ws.type_of_water_source,
    l.location_type,
    ws.number_of_people_served,
    v.time_in_queue,
    wp.results
FROM
    location AS l
        JOIN
    visits AS v ON l.location_id = v.location_id
		JOIN
	water_source AS ws ON v.source_id = ws.source_id
		LEFT JOIN
	well_pollution AS wp ON v.source_id = wp.source_id
WHERE v.visit_count = 1;

-- The last analysis
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
	combined_analysis_table AS ct
JOIN
	province_totals AS pt ON ct.province_name = pt.province_name
GROUP BY
	ct.province_name
ORDER BY
	ct.province_name;
    
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
)