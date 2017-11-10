REATE DATABASE IF NOT EXISTS bighawk;
use bighawk;

-- create la_crimes table and load with data
CREATE TABLE IF NOT EXISTS la_crimes (
  dr_number string,
  date_reported string,
  date_occurred date,
  time_occurred string,
  area_id string,
  area_name string,
  reporting_district string,
  crime_code string,
  crime_code_desc string,
  mo_codes string,
  victim_age string,
  victim_sex string,
  victim_descent string,
  premise_code string,
  premise_desc string,
  weapon_used_code string,
  weapon_desc string,
  status_code string,
  status_desc string,
  crime_code1 string,
  crime_code2 string,
  crime_code3 string,
  crime_code4 string,
  address string,
  cross_street string,
  location string
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
STORED AS TEXTFILE
tblproperties ("skip.header.line.count"="1");

load data local inpath "la_crimes.csv" OVERWRITE into table la_crimes;

set hive.exec.dynamic.partition.mode=nonstrict;
CREATE TABLE IF NOT EXISTS la_crimes_part_year (
  dr_number string,
  date_reported string,
  date_occurred date,
  time_occurred string,
  area_id string,
  area_name string,
  reporting_district string,
  crime_code string,
  crime_code_desc string,
  mo_codes string,
  victim_age string,
  victim_sex string,
  victim_descent string,
  premise_code string,
  premise_desc string,
  weapon_used_code string,
  weapon_desc string,
  status_code string,
  status_desc string,
  crime_code1 string,
  crime_code2 string,
  crime_code3 string,
  crime_code4 string,
  address string,
  cross_street string,
  location string
)
PARTITIONED BY (part_year int)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
STORED AS TEXTFILE;

insert overwrite table la_crimes_part_year partition(part_year)
  select *, int(substr(date_occurred, (length(date_occurred)-2-1), (length(date_occurred) -1 ))) as part_year from la_crimes;
