-- Aggregate statistics on temperature logger data

DROP TABLE IF EXISTS sentinel4nature."temploggerData_days";
CREATE TABLE sentinel4nature."temploggerData_days" AS
SELECT 
locality
, date_trunc('day', date)::date AS date
, count(temperature_c) AS temperature_c_days_count
, max(temperature_c) AS temperature_c_days_max
, avg(temperature_c) AS temperature_c_days_avg
, min(temperature_c) AS temperature_c_days_min
, stddev_samp(temperature_c) AS temperature_c_days_stddev
, var_samp(temperature_c) AS temperature_c_days_var
, count(temperature_f) AS temperature_f_days_count
, max(temperature_f) AS temperature_f_days_max
, avg(temperature_f) AS temperature_f_days_avg
, min(temperature_f) AS temperature_f_days_min
, stddev_samp(temperature_f) AS temperature_f_days_stddev
, var_samp(temperature_f) AS temperature_f_days_var
, count(humidity_perc) AS humidity_perc_days_count
, max(humidity_perc) AS humidity_perc_days_max
, avg(humidity_perc) AS humidity_perc_days_avg
, min(humidity_perc) AS humidity_perc_days_min
, stddev_samp(humidity_perc) AS humidity_perc_days_stddev
, var_samp(humidity_perc) AS humidity_perc_days_var
, count(dew_point_c) AS dew_point_c_days_count
, max(dew_point_c) AS dew_point_c_days_max
, avg(dew_point_c) AS dew_point_c_days_avg
, min(dew_point_c) AS dew_point_c_days_min
, stddev_samp(dew_point_c) AS dew_point_c_days_stddev
, var_samp(dew_point_c) AS dew_point_c_days_var
, count(dew_point_f) AS dew_point_f_days_count
, max(dew_point_f) AS dew_point_f_days_max
, avg(dew_point_f) AS dew_point_f_days_avg
, min(dew_point_f) AS dew_point_f_days_min
, stddev_samp(dew_point_f) AS dew_point_f_days_stddev
, var_samp(dew_point_f) AS dew_point_f_days_var
  FROM sentinel4nature."temploggerData"
-- WHERE locality = 'B1 0cm'
GROUP BY 
locality
, date_trunc('day', date)::date
ORDER BY locality
, date_trunc('day', date)::date;

DROP TABLE IF EXISTS sentinel4nature."temploggerData_months";
CREATE TABLE sentinel4nature."temploggerData_months" AS
SELECT 
locality
, date_trunc('month', date)::date AS date
, array_length(array_agg(DISTINCT date_trunc('day', date)), 1) AS number_of_days
, count(temperature_c) AS temperature_c_months_count
, max(temperature_c) AS temperature_c_months_max
, avg(temperature_c) AS temperature_c_months_avg
, min(temperature_c) AS temperature_c_months_min
, stddev_samp(temperature_c) AS temperature_c_months_stddev
, var_samp(temperature_c) AS temperature_c_months_var
, count(temperature_f) AS temperature_f_months_count
, max(temperature_f) AS temperature_f_months_max
, avg(temperature_f) AS temperature_f_months_avg
, min(temperature_f) AS temperature_f_months_min
, stddev_samp(temperature_f) AS temperature_f_months_stddev
, var_samp(temperature_f) AS temperature_f_months_var
, count(humidity_perc) AS humidity_perc_months_count
, max(humidity_perc) AS humidity_perc_months_max
, avg(humidity_perc) AS humidity_perc_months_avg
, min(humidity_perc) AS humidity_perc_months_min
, stddev_samp(humidity_perc) AS humidity_perc_months_stddev
, var_samp(humidity_perc) AS humidity_perc_months_var
, count(dew_point_c) AS dew_point_c_months_count
, max(dew_point_c) AS dew_point_c_months_max
, avg(dew_point_c) AS dew_point_c_months_avg
, min(dew_point_c) AS dew_point_c_months_min
, stddev_samp(dew_point_c) AS dew_point_c_months_stddev
, var_samp(dew_point_c) AS dew_point_c_months_var
, count(dew_point_f) AS dew_point_f_months_count
, max(dew_point_f) AS dew_point_f_months_max
, avg(dew_point_f) AS dew_point_f_months_avg
, min(dew_point_f) AS dew_point_f_months_min
, stddev_samp(dew_point_f) AS dew_point_f_months_stddev
, var_samp(dew_point_f) AS dew_point_f_months_var
  FROM sentinel4nature."temploggerData"
-- WHERE locality = 'B1 0cm'
GROUP BY 
locality
, date_trunc('month', date)::date
ORDER BY locality
, date_trunc('month', date)::date;

DROP TABLE IF EXISTS sentinel4nature."temploggerData_years";
CREATE TABLE sentinel4nature."temploggerData_years" AS
SELECT 
locality
, date_trunc('year', date)::date AS date
, array_length(array_agg(DISTINCT date_trunc('day', date)), 1)
, count(temperature_c) AS temperature_c_years_count
, max(temperature_c) AS temperature_c_years_max
, avg(temperature_c) AS temperature_c_years_avg
, min(temperature_c) AS temperature_c_years_min
, stddev_samp(temperature_c) AS temperature_c_years_stddev
, var_samp(temperature_c) AS temperature_c_years_var
, count(temperature_f) AS temperature_f_years_count
, max(temperature_f) AS temperature_f_years_max
, avg(temperature_f) AS temperature_f_years_avg
, min(temperature_f) AS temperature_f_years_min
, stddev_samp(temperature_f) AS temperature_f_years_stddev
, var_samp(temperature_f) AS temperature_f_years_var
, count(humidity_perc) AS humidity_perc_years_count
, max(humidity_perc) AS humidity_perc_years_max
, avg(humidity_perc) AS humidity_perc_years_avg
, min(humidity_perc) AS humidity_perc_years_min
, stddev_samp(humidity_perc) AS humidity_perc_years_stddev
, var_samp(humidity_perc) AS humidity_perc_years_var
, count(dew_point_c) AS dew_point_c_years_count
, max(dew_point_c) AS dew_point_c_years_max
, avg(dew_point_c) AS dew_point_c_years_avg
, min(dew_point_c) AS dew_point_c_years_min
, stddev_samp(dew_point_c) AS dew_point_c_years_stddev
, var_samp(dew_point_c) AS dew_point_c_years_var
, count(dew_point_f) AS dew_point_f_years_count
, max(dew_point_f) AS dew_point_f_years_max
, avg(dew_point_f) AS dew_point_f_years_avg
, min(dew_point_f) AS dew_point_f_years_min
, stddev_samp(dew_point_f) AS dew_point_f_years_stddev
, var_samp(dew_point_f) AS dew_point_f_years_var
  FROM sentinel4nature."temploggerData"
-- WHERE locality = 'B1 0cm'
GROUP BY 
locality
, date_trunc('year', date)::date
ORDER BY locality
, date_trunc('year', date)::date;

-- SELECT locality, date_trunc('year', date) AS year, count(date) AS snow_days 
-- FROM sentinel4nature."temploggerData_days" where temperature_c_var < 1 AND temperature_c_max < 1
-- GROUP BY locality, date_trunc('year', date)
-- ORDER BY locality, date_trunc('year', date);
