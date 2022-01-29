WITH

---- Clear empty cells------

	null_cleaned AS
	(
		SELECT *
		FROM Divvy_tripdata_2021
		WHERE start_station_name IS NOT NULL
			AND end_station_name IS NOT NULL
			AND start_lat IS NOT NULL
			AND start_lng IS NOT NULL
			AND end_lat IS NOT NULL
			AND end_lng IS NOT NULL
	),


----Create duration in minutes-------

	final_table AS
	(
		SELECT *, ((JULIANDAY(ended_at) - JULIANDAY(started_at))*1440) AS duration
		FROM null_cleaned
	),
	
-----Total numbers of member/casual riders departing from station-----
	
casual_depart_station AS	
	(
		SELECT COUNT(member_casual) AS Casual, start_station_name
		FROM final_table
		WHERE member_casual = 'casual' 
		GROUP BY start_station_name
	),
member_depart_station AS
	(
		SELECT COUNT(member_casual) AS Member, start_station_name
		FROM final_table
		WHERE member_casual = 'member' 
		GROUP BY start_station_name
	),

----- Join members and casuals on departing station

depart_station AS
	(
		SELECT cds.start_station_name, cds.Casual, mds.Member
		FROM casual_depart_station cds
			JOIN member_depart_station mds
			ON cds.start_station_name = mds.start_station_name
	),
	
-----GROUP departing station name with distinct Latitude and Altitude-----
depart_latlng AS
	(
		SELECT DISTINCT start_station_name, round(AVG(start_lat),4) AS dep_lat, round(AVG(start_lng),4) AS dep_lng
		FROM final_table
		GROUP BY	start_station_name
	),
	
----Join location coordinate data with ridership count------

location_dataviz_depart AS	
	(
		SELECT dl.start_station_name, ds.Casual, ds.Member, dl.dep_lat, dl.dep_lng
		FROM depart_station ds
			JOIN depart_latlng dl
			ON ds.start_station_name = dl.start_station_name
	),
------------ Total numbers of member / casual riders arriving for respective stations ----------------
casual_arrive_station AS
	(
		SELECT COUNT(member_casual) AS Casual, end_station_name
		FROM final_table
		WHERE member_casual = 'casual' 
		GROUP BY end_station_name
	),

member_arrive_station AS
	(
		SELECT COUNT(member_casual) AS Member, end_station_name
		FROM final_table
		WHERE member_casual = 'member' 
		GROUP BY end_station_name
	),

--------- Join member and casual riders on arriving bike stations ------------------------------------
arrive_station AS
	(
		SELECT cas.end_station_name, cas.Casual, mas.Member
		FROM casual_arrive_station cas
		  JOIN member_arrive_station mas
		  ON cas.end_station_name = mas.end_station_name
	),

----------- Group arriving station name with distinct Latitude and Altitude -----------------------
arrive_latlng AS
	(
		SELECT DISTINCT end_station_name, ROUND(AVG(end_lat),4) AS arr_lat, Round(AVG(end_lng),4) AS arr_lng
		FROM final_table
		GROUP BY end_station_name
	),

---------- Join location  data with ridership count ------------------------
---------- Export to excel and import to tableau for visualisation-----------------------
location_dataviz_arrive AS
	(
		SELECT al.end_station_name, ast.Casual, ast.Member, al.arr_lat, al.arr_lng
		FROM arrive_station ast
		  JOIN arrive_latlng al
		  ON ast.end_station_name = al.end_station_name
	),

----Summary stats-----

summary AS
	(
		SELECT member_casual, rideable_type, date(started_at) AS Ymd,
			sum(duration) AS sum,
			avg(duration) AS Mean,
			max(duration) AS Max,
			min(duration) AS Min,
			count (duration) as Rides
		FROM final_table
		GROUP BY member_casual, rideable_type, Ymd
	)
SELECT *
FROM summary
	
