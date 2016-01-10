#!/usr/bin/env python
#
#############################################################################
# AUTHOR(S):    Stefan Blumentrath
# PURPOSE:      Load temperature logger data to PostgreSQL/PostGIS
# COPYRIGHT:    (C) 2015 by the Stefan Blumentrath
#
#               This program is free software under the GNU General Public
#               License (>=v2). Read the file COPYING that comes with GRASS
#               for details.
#############################################################################
#

#import datetime
#import csv
#import subprocess
#import logging

import os
import cStringIO
# Python2, use: from cStringIO import StringIO
from sys import platform
from collections import OrderedDict

import psycopg2

def FtoC(float):
    return round((float - 32.0) * 5.0 / 9.0, 4)

def CtoF(float):
    return round(float / 5.0 * 9.0 + 32.0, 4)

#Conect to PostGIS using psycopg2 module
try:
    conn = psycopg2.connect("dbname='gisdata' user='stefan' host='ninsrv16' password='**********'")
    conn.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT)
except:
    #logging.info("Unable to connect to the database")
    print "Unable to connect to the database"

if platform == "win32":
    conn.set_client_encoding('LATIN4')

# logger_dir has to be provided by the user
logger_dir = "R:\\Prosjekter\\SIS KLIMA WP1 GNAGERE 2011-2015 NEE\\Temploggere 2014\\Temploggere"
logger_dir = "R:\\Prosjekter\\SIS KLIMA WP1 GNAGERE 2011-2015 NEE"

# parentEventID has to be provided by the user
parentEventID = 9999
# Parent event ID table is missing
# partition data table based on year (or project? or both)

# Create tables if necessary
curs = conn.cursor()

# Drop tables (for debug mode)
curs.execute("""DROP TABLE IF EXISTS sentinel4nature.templogger_data;""")
curs.execute("""DROP TABLE IF EXISTS sentinel4nature.samplingEvent;""")
curs.execute("""DROP TABLE IF EXISTS sentinel4nature."samplingEvent";""")

# Partition data table by year (or possibly by project / event)
# Create templogger_data table if necessary
curs.execute("""CREATE TABLE IF NOT EXISTS sentinel4nature.templogger_data 
    (locality varchar(50), "parentEventID" integer, "eventID" integer, 
    date timestamp with time zone, temperature_c double precision, 
    temperature_f double precision, humidity_perc double precision, 
    dew_point_c double precision, dew_point_f double precision);
    ALTER TABLE sentinel4nature."templogger_data"
        ADD CONSTRAINT "sentinel4nature_templogger_data_pkey" PRIMARY KEY 
        (locality, "parentEventID", "eventID", date);
    CREATE INDEX "sentinel4nature_templogger_data_locality_idx"
        ON sentinel4nature."templogger_data" USING btree (locality ASC NULLS LAST);
    ALTER TABLE sentinel4nature."templogger_data"
        CLUSTER ON "sentinel4nature_templogger_data_locality_idx";
    CREATE INDEX "sentinel4nature_templogger_data_parentEventID_idx"
        ON sentinel4nature."templogger_data" USING btree ("parentEventID" ASC NULLS LAST);
    ALTER TABLE sentinel4nature."templogger_data"
        CLUSTER ON "sentinel4nature_templogger_data_parentEventID_idx";
    CREATE INDEX "sentinel4nature_templogger_data_eventID_idx"
        ON sentinel4nature."templogger_data" USING btree ("eventID" ASC NULLS LAST);
    ALTER TABLE sentinel4nature."templogger_data"
        CLUSTER ON "sentinel4nature_templogger_data_eventID_idx";
    CREATE INDEX "sentinel4nature_templogger_data_date_idx"
        ON sentinel4nature."templogger_data" USING btree (date ASC NULLS LAST);
    ALTER TABLE sentinel4nature."templogger_data"
        CLUSTER ON "sentinel4nature_templogger_data_date_idx";
    CREATE INDEX "sentinel4nature_templogger_data_temperature_c_idx"
        ON sentinel4nature."templogger_data" USING btree (temperature_c ASC NULLS LAST)
        WHERE temperature_c IS NOT NULL;
    -- ALTER TABLE sentinel4nature."templogger_data"
    --     CLUSTER ON "sentinel4nature_templogger_data_temperature_c_idx";
    CREATE INDEX "sentinel4nature_templogger_data_temperature_f_idx"
        ON sentinel4nature."templogger_data" USING btree (temperature_f ASC NULLS LAST)
        WHERE temperature_f IS NOT NULL;
    -- ALTER TABLE sentinel4nature."templogger_data"
    --     CLUSTER ON "sentinel4nature_templogger_data_temperature_f_idx";
    CREATE INDEX "sentinel4nature_templogger_data_humidity_perc_idx"
        ON sentinel4nature."templogger_data" USING btree (humidity_perc ASC NULLS LAST)
        WHERE humidity_perc IS NOT NULL;
    -- ALTER TABLE sentinel4nature."templogger_data"
    --     CLUSTER ON "sentinel4nature_templogger_data_humidity_perc_idx";
    CREATE INDEX "sentinel4nature_templogger_data_dew_point_c_idx"
        ON sentinel4nature."templogger_data" USING btree (dew_point_c ASC NULLS LAST)
         WHERE dew_point_c IS NOT NULL;
    -- ALTER TABLE sentinel4nature."templogger_data"
    --     CLUSTER ON "sentinel4nature_templogger_data_dew_point_c_idx";
    CREATE INDEX "sentinel4nature_templogger_data_dew_point_f_idx"
        ON sentinel4nature."templogger_data" USING btree (dew_point_f ASC NULLS LAST)
         WHERE dew_point_f IS NOT NULL;
    -- ALTER TABLE sentinel4nature."templogger_data"
    --     CLUSTER ON "sentinel4nature_templogger_data_dew_point_f_idx";
    """)

# Create "samplingEvent" table if necessary
curs.execute("""CREATE TABLE IF NOT EXISTS sentinel4nature."samplingEvent" 
    (locality varchar(50), "parentEventID" integer, "eventID" integer, 
    temperature_c boolean, temperature_f boolean, humidity_perc boolean, 
    dew_point_c boolean, dew_point_f boolean, date_first timestamp with time zone, date_last 
    timestamp with time zone, file_path varchar(255));
    ALTER TABLE sentinel4nature."samplingEvent"
        ADD CONSTRAINT "sentinel4nature_samplingEvent_pkey" PRIMARY KEY 
        (locality, "parentEventID", "eventID", date_first, date_last);
    CREATE INDEX "sentinel4nature_samplingEvent_locality_idx"
        ON sentinel4nature."samplingEvent" USING btree (locality ASC NULLS LAST);
    ALTER TABLE sentinel4nature."samplingEvent"
        CLUSTER ON "sentinel4nature_samplingEvent_locality_idx";
    CREATE INDEX "sentinel4nature_samplingEvent_parentEventID_idx"
        ON sentinel4nature."samplingEvent" USING btree ("parentEventID" ASC NULLS LAST);
    ALTER TABLE sentinel4nature."samplingEvent"
        CLUSTER ON "sentinel4nature_samplingEvent_parentEventID_idx";
    CREATE INDEX "sentinel4nature_samplingEvent_eventID_idx"
        ON sentinel4nature."samplingEvent" USING btree ("eventID" ASC NULLS LAST);
    ALTER TABLE sentinel4nature."samplingEvent"
        CLUSTER ON "sentinel4nature_samplingEvent_eventID_idx";
    CREATE INDEX "sentinel4nature_samplingEvent_date_first_idx"
        ON sentinel4nature."samplingEvent" USING btree (date_first ASC NULLS LAST);
    ALTER TABLE sentinel4nature."samplingEvent"
        CLUSTER ON "sentinel4nature_samplingEvent_date_first_idx";
    CREATE INDEX "sentinel4nature_samplingEvent_date_last_idx"
        ON sentinel4nature."samplingEvent" USING btree (date_last ASC NULLS LAST);
    ALTER TABLE sentinel4nature."samplingEvent"
        CLUSTER ON "sentinel4nature_samplingEvent_date_last_idx";
    """)

# Load data for a Sampling event (project / periode)

# - locality (from location table) extracted from file(s) (or provided manually) (locations have to exist in the DB)
# - samplingEvent / parentEvent provided manually (has to exist in the DB)
# - loggerPeriod metadata extracted from file(s) (or (maybe partly) provided manually), samplingEvent record is generated automatically

# Log successfully loaded files, files with import errors, and unser name
 # - check if "locality" exists in "location" table (not necessary if taken from dropdown list)
    # if locality not in localities:
        # ??? (copy to other table (including file name/path)
# - check if "samplingEvent" exists (not necessary if taken from dropdown list)
# - check if measurement types (temperature, lux...) and units exist in code (OrderedDict)
# - check if metadata match (data types, expected content)

 # Nesting of events?
# "Overwrite" existing data checkbox (unique-constraint on location, parentEvent, samplingEvent, timestamp
# Unique constraint on file_path (each file should be loaded only once

# Propose a temperature logger data folder

# parentEvent (Project, placement types, ...)
# samplingEvent (Mission)

###############################################################################
# To do`s:
# Aggregate automatically (to aggregate tables)
#   by day, month, year
#   using max(), min(), avg(), stddev(), variance(), percentile_disc(fraction) (5, 50, 95)
#   UPSERT tables
#   WHERE date_first <= date AND date_last >= date AND locality = locality AND parentEventID = parentEventID
###############################################################################

# Define measurements and respective columns
measure_cols = OrderedDict([('Temperature (*F)','temperature_f'),
    ('Temperature (*C)','temperature_c'),
    ('RH (%)','humidity_perc'),
    ('Dew Point (*C)','dew_point_c'),
    ('Dew Point (*F)','dew_point_f')])

# Load temperature logger data
# Find all temperature logger files within provided folder and subfolders
for dirpath, dirnames, filenames in os.walk(logger_dir):
    for filename in  filenames:
        #######################################################################
        # The following code represents the function specific for the type of 
        # temperature logger used by Nina Eide.
        # A more general function should return:
        # - a list with the event metadata ("event_data")
        # - a list containing the table with the logger data ("table")
        # - a list with the columns to be written to ("columns")
        #######################################################################
        if ( filename.endswith('SWD') or filename.endswith('swd') ) \
        and not filename.startswith('INDEX'):
            units = []
            event_data = []
            # Read temperature logger data
            with open(os.path.join(dirpath,filename)) as f:
                d = f.read().split('\n')
            # Extract metadata from logger file
            # Extract locality from logger file
            locality = d[0].split('\t')[0]
            # Here it might be necessary to check wheter the locality exits
            
            # '''-- Get list of possible candidates for the location
            # SELECT * FROM
            # (SELECT locality, "eventID", file_path FROM sentinel4nature.samplingevent) AS a,
            # (SELECT DISTINCT ON ("loggerName","placementID") * FROM sentinel4nature.temperaturelogger_location) As b
            # WHERE 
            # locality NOT IN (SELECT DISTINCT ON ("loggerName") "loggerName" FROM sentinel4nature.temperaturelogger_location) AND
            # locality NOT IN (SELECT DISTINCT ON ("placementID") "placementID" FROM sentinel4nature.temperaturelogger_location) AND
            # (b."loggerName" LIKE '%' || a.locality || '%' OR b."placementID" LIKE '%' || a.locality || '%')
            # -- locality from logger either matches "loggerName" or "placementID"
            # -- b."loggerName" = a.locality OR b."placementID" = a.locality'''
            
            # Add locality to entry in samplingEvent-table
            event_data.append(locality)
            # Add parentEventID to entry in samplingEvent-table
            event_data.append(parentEventID)
            
            # Get latest eventID for current combination of locality and parentEventID
            eventID_SQL = """SELECT max("eventID") FROM 
                sentinel4nature."samplingEvent" WHERE locality = '{0}' 
                AND "parentEventID" = {1};""".format(locality, parentEventID)
            curs.execute(eventID_SQL)
            # Set eventID for current (new) temperature logger file
            eventID = curs.fetchall()[0][0]
            if eventID is None:
                eventID = 1
            else:
                eventID = int(eventID) + 1
            
            # Add eventID to entry in samplingEvent-table
            event_data.append(eventID)
            
            # Extract measurement units from logger file
            units = d[0].split('\t')[1:]
            
            # The following might be useful if units cannot be identified as above
            # '''if not d[1].split('\t')[1]:
                # print os.path.join(dirpath,filename)
                # temperature_unit = d[1].split('\t')[0] # '*F'
            # else:
                # temperature_unit = d[1].split('\t')[1] # '*F'
            # units.append(temperature_unit)
            # if len(d[1].split('\t')) > 2:
                # humidity_unit = d[1].split('\t')[2] # '%'
                # units.append(humidity_unit)
            # if len(d[1].split('\t')) > 3:
                # dew_unit = d[1].split('\t')[3] # '%'
                # units.append(dew_unit) '''
            
            # Convert Farenheit to Celsius or Celsius to Farenheit
            F = False
            C = False
            if 'Temperature (*F)' in units and not 'Temperature (*C)' in units:
                # Flag that ofiginal temperature unit is F
                F = True
                # Add temperature in C at last position
                P = units.index('Temperature (*F)') + 1
                # F -> C : (T(°F) - 32) × 5/9
                units.append('Temperature (*C)')
            elif 'Temperature (*C)' in units and not 'Temperature (*F)' in units:
                # Flag that ofiginal temperature unit is C
                C = True
                # Add temperature in F at last position
                P = units.index('Temperature (*C)') + 1
                # C -> F : (T(°C) / 5 * 9 + 32)
                units.append('Temperature (*F)')
            
            # map measured values and columns
            value_columns = ','.join(units)
            for c in measure_cols:
                value_columns = value_columns.replace(c, measure_cols[c])
                # Add measurements to entry in samplingEvent-table
                if c in units:
                    event_data.append(True)
                else:
                    event_data.append(False)
            
            # Extract date of first measurement from logger file
            date_first = d[3].split('\t')[0]
            
            # Add date of first measurement to entry in samplingEvent-table
            event_data.append(date_first)
            r = 1
            while '\t' not in d[(len(d)-r)]:
                r = r + 1
            
            # Extract date of last measurement from logger file
            date_last = d[(len(d)-r)].split('\t')[0]
            
            # Add date of last measurement to entry in samplingEvent-table
            event_data.append(date_last)
            
            # Create a list of columns that will receive data
            columns = 'locality,"parentEventID","eventID",date,{0}'.format(value_columns).split(',')
            
            # Inject locality,"parentEventID","eventID" into logger data
            table = []
            for line in d[3:len(d)-1]:
                values = line.replace(',','.').replace('\t',',')
                # Check if original temperature unit is F
                if F:
                    conversion = FtoC(float(values.split(',')[P]))
                # Check if original temperature unit is C
                elif C:
                    conversion = CtoF(float(values.split(',')[P]))
                
                table.append('{0},{1},{2},{3},{4}'.format(locality,
                    parentEventID,eventID,values,conversion))
            
            ###################################################################
            # The following code is no longer logger type specific
            ###################################################################
            
            # Write path to samplingEvent entry
            event_data.append(os.path.join(dirpath,filename))
            
            # Generate SQL INSERT statement
            # ''' locality, "parentEventID", "eventID", 
            # temperature_f', 'temperature_c', 'dew_point_c', 'humidity_perc',
            # date_first, date_last, file_path'''
            event_SQL = """INSERT INTO sentinel4nature."samplingEvent" VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s);""" # Note: no quotes
            
            # Load temperature logger metadata to PostgreSQL
            curs.execute(event_SQL, tuple(event_data)) # Note: no % operator
            
            # Create a StingIO object to be used in the COPY statement
            data = cStringIO.StringIO()
            data.write(unicode('\n'.join(table)))
            data.seek(0)
            
            # Load temperature measurements to PostgreSQL
            curs.copy_from(data, 'sentinel4nature.templogger_data',
                columns = tuple(columns), sep = ',', null='')
            
            # Close StringIO object to free memory
            data.close()

# Vacuum tables when all data got added
curs.execute("""VACUUM FULL ANALYZE sentinel4nature.templogger_data;""")
curs.execute("""VACUUM FULL ANALYZE sentinel4nature."samplingEvent";""")


# Code snippets for possible later usage
# '''
            # # Example for a dictionary as a switch (for unit conversions)
            # op = '*'
            # part1 = 2
            # part3 = 4

            # d = {
                # '+': lambda x,y: x+y,
                # '-': lambda x,y: x-y,
                # '*': lambda x,y: x*y,
                # '/': lambda x,y: x/y
            # }

            # try:
                # print(d[op](part1, part3))
            # except KeyError:
                # default()


            # # Load data to PostgreSQL using the COPY command

            # curs = conn.cursor()
            # curs.execute("DROP TABLE sentinel4nature.templogger_data;")
            # curs.execute("CREATE TABLE IF NOT EXISTS sentinel4nature.templogger_data (locality varchar(50), eventID integer, date datetime with timezone, temperature_c double precision, temperature_f double precision, humidity_perc double precision, dew_point_c double precision);")


            # curs.copy_from(data, 'sentinel4nature.templogger_data')
# '''