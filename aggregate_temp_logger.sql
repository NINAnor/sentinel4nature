-- Aggregate statistics on temperature logger data

SELECT locality, date_trunc('year', date) AS year, count(date) AS snow_days FROM (SELECT 
locality
, "eventID"
, "periodeID"
, date_trunc('day', date) AS date
, count(temperature_c) AS temperature_c_count
, max(temperature_c) AS temperature_c_max
, avg(temperature_c) AS temperature_c_avg
, min(temperature_c) AS temperature_c_min
, stddev_samp(temperature_c) AS temperature_c_stddev
, var_samp(temperature_c) AS temperature_c_var
, count(temperature_f) AS temperature_f_count
, max(temperature_f) AS temperature_f_max
, avg(temperature_f) AS temperature_f_avg
, min(temperature_f) AS temperature_f_min
, stddev_samp(temperature_f) AS temperature_f_stddev
, var_samp(temperature_f) AS temperature_f_var
, count(humidity_perc) AS humidity_perc_count
, max(humidity_perc) AS humidity_perc_max
, avg(humidity_perc) AS humidity_perc_avg
, min(humidity_perc) AS humidity_perc_min
, stddev_samp(humidity_perc) AS humidity_perc_stddev
, var_samp(humidity_perc) AS humidity_perc_var
, count(dew_point_c) AS dew_point_c_count
, max(dew_point_c) AS dew_point_c_max
, avg(dew_point_c) AS dew_point_c_avg
, min(dew_point_c) AS dew_point_c_min
, stddev_samp(dew_point_c) AS dew_point_c_stddev
, var_samp(dew_point_c) AS dew_point_c_var
, count(dew_point_f) AS dew_point_f_count
, max(dew_point_f) AS dew_point_f_max
, avg(dew_point_f) AS dew_point_f_avg
, min(dew_point_f) AS dew_point_f_min
, stddev_samp(dew_point_f) AS dew_point_f_stddev
, var_samp(dew_point_f) AS dew_point_f_var
  FROM sentinel4nature."temploggerData"
-- WHERE locality = 'B1 0cm'
GROUP BY 
locality
, "eventID"
, "periodeID"
, date_trunc('day', date)
ORDER BY locality
, "eventID"
, "periodeID"
, date_trunc('day', date)
) AS a where temperature_c_var < 1 AND temperature_c_max < 1
GROUP BY locality, date_trunc('year', date)
ORDER BY locality, date_trunc('year', date);
