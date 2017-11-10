CREATE DATABASE IF NOT EXISTS bighawk;
use bighawk;

-- create houston_crimes table and load with data
CREATE TABLE IF NOT EXISTS houston_crimes (
crime_date timestamp,
hour int,
offense_type string,
beat string,
premise string,
block_range string,
street_name string,
type string,
suffix string,
offenses string,
x string
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
STORED AS TEXTFILE
tblproperties ("skip.header.line.count"="1");

load data local inpath "houston_crimes.csv" OVERWRITE into table houston_crimes;

set hive.exec.dynamic.partition.mode=nonstrict;
CREATE TABLE IF NOT EXISTS houston_crimes_part_year (
  crime_date string,
  hour string,
  offense_type string,
  beat string,
  premise string,
  block_range string,
  street_name string,
  type string,
  suffix string,
  offenses string,
  x string
)
PARTITIONED BY (part_year int)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
STORED AS TEXTFILE;

insert overwrite table houston_crimes_part_year partition(part_year)
  select *, year(date(crime_date)) as part_year from houston_crimes_part_year;
