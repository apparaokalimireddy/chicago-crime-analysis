-- Step 2: Create chicago_crimes table and load the downloaded data
-- From unix commandline hive -f chicago_crime_data_load.hql
CREATE DATABASE IF NOT EXISTS bighawk;
use bighawk;

-- create chicago_crimes table and load with data
CREATE TABLE IF NOT EXISTS chicago_crimes (
arrest boolean,
beat string,
block string,
case_number string,
community_area string,
crime_date timestamp,
description string,
district string,
domestic boolean,
fbi_code string,
id string,
iucr string,
latitude decimal(10,0),
location string,
location_address string,
location_city string,
location_description string,
location_state string,
location_zip string,
longitude decimal(10,0),
primary_type string,
updated_on string,
ward string,
x_coordinate string,
y_coordinate string,
year string
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
STORED AS TEXTFILE
tblproperties ("skip.header.line.count"="1");

load data local inpath "chicago_crimes.csv" OVERWRITE into table chicago_crimes;

-- Create chicago_socio_economics table load the data
CREATE TABLE IF NOT EXISTS chicago_socio_economics (
community_area string,
community string,
per_housing_crowded float,
per_households_below_poverty float,
per_aged_16plus_unemp float,
per_aged_25plus_no_hs_diploma float,
per_aged_under18_or_ove64 float,
percapita_income int,
hardship_index smallint
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
STORED AS TEXTFILE
tblproperties ("skip.header.line.count"="1");

load data local inpath "chicago_socio_economics.csv" OVERWRITE into table chicago_socio_economics;

-- Create chicago_crimes_by_area table and load data using Query
create table chicago_crimes_by_area
  ROW FORMAT delimited
  STORED AS TEXTFILE
  AS
  select year, community_area, primary_type, count(*) as crime_count from chicago_crimes_part_year
  where community_area != ""
  group by year, community_area, primary_type
  order by year, community_area, primary_type


  -- Create chicago_crimes_socio_economics table and load
  create table chicago_crimes_socio_economics
    ROW FORMAT delimited
    STORED AS TEXTFILE
    AS
    select year, primary_type, crime_count, s.* from
    (
      select year, community_area, primary_type, count(*) as crime_count from chicago_crimes_part_year
      where community_area != ""
      group by year, community_area, primary_type
      order by year, community_area, primary_type
    ) c join chicago_socio_economics s on (c.community_area=s.community_area)
