use bighawk;
set hive.exec.dynamic.partition.mode=nonstrict;
CREATE TABLE IF NOT EXISTS chicago_crimes_part_year (
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
PARTITIONED BY (part_year int)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
STORED AS TEXTFILE;

insert overwrite table chicago_crimes_part_year partition(part_year)
  select *, int(year) as part_year from chicago_crimes;
