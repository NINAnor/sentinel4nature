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
import time
# Python2, use: from cStringIO import StringIO
from sys import platform
from collections import OrderedDict
from datetime import datetime

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

# loggerType has to be provided by the user; logger types in DB (could also be hardcoded in .py)
loggerType = 'Nina`s logger'

# eventID has to be provided by the user
eventID = 1

# Maybe god to require establishment of relations between event and location
# Parent event ID table is missing
# partition data table based on year (or project? or both)

# Field notes can either be provided by user to start with
# or user may be asked for field notes connected to a log-periode
fieldNotes = 'Logger damaged'
# Create tables if necessary
curs = conn.cursor()

##################
# eventDate = defined as intervall
# eventTaxonomicRange
##################
# Partition data table by year (or possibly by project / event)
# Create "temploggerData" table if necessary
curs.execute("""SET search_path TO sentinel4nature, public;

DROP TABLE IF EXISTS "temploggerTypes" CASCADE;
CREATE TABLE IF NOT EXISTS "temploggerTypes"
    ("loggerType" varchar(25) PRIMARY KEY
    , description varchar(255)
    );

-- Fill "temploggerTypes" lookup-table with test data
INSERT INTO "temploggerTypes" VALUES ('Nina`s logger','Logger type used by Nina Eide in several projects');

    DROP TABLE IF EXISTS "temploggerRelationshipResourceTypes" CASCADE;
CREATE TABLE IF NOT EXISTS "temploggerRelationshipResourceTypes"
    ("resourceType" varchar(25) PRIMARY KEY
    , description varchar(255)
    );

-- Fill "temploggerRelationshipResourceTypes" lookup-table with data
INSERT INTO "temploggerRelationshipResourceTypes" VALUES ('location','(Spatial) relation between locations (nesting)');
INSERT INTO "temploggerRelationshipResourceTypes" VALUES ('samplingEvent','Relation between sampling events (nesting)');
INSERT INTO "temploggerRelationshipResourceTypes" VALUES ('occurrence','Relation between occurences (nesting)');
INSERT INTO "temploggerRelationshipResourceTypes" VALUES ('measurement','Relation between locations (nesting)');

DROP TABLE IF EXISTS "temploggerRelationshipOfResourceTypes" CASCADE;
CREATE TABLE IF NOT EXISTS "temploggerRelationshipOfResourceTypes"
    ("relationshipOfResourceID" serial PRIMARY KEY
    , "relationshipOfResource" varchar(25)
    , "resourceType" varchar(25) REFERENCES "temploggerRelationshipResourceTypes" ("resourceType")
    , "spatialObjectType" varchar(10)[]
    , description varchar(255)
    , UNIQUE ("relationshipOfResource", "resourceType"));

-- Fill "temploggerRelationshipOfResourceTypes" lookup-table with data
INSERT INTO "temploggerRelationshipOfResourceTypes" ("relationshipOfResource","resourceType", "spatialObjectType", description) VALUES ('Contains', 'location', '{Polygon}', 'a contains b: geometry b lies in a, and the interiors intersect. Another definition: "a contains b iff no points of b lie in the exterior of a, and at least one point of the interior of b lies in the interior of a".');
INSERT INTO "temploggerRelationshipOfResourceTypes" ("relationshipOfResource","resourceType", "spatialObjectType", description) VALUES ('Covers', 'location', '{Line,Polygon}', 'a covers b: geometry b lies in a. Other definitions: "no points of b lie in the exterior of a", or "Every point of b is a point of (the interior or boundary of) a".');
INSERT INTO "temploggerRelationshipOfResourceTypes" ("relationshipOfResource","resourceType", "spatialObjectType", description) VALUES ('CoveredBy', 'location', '{Point,Line,Polygon}', 'a is covered by b (extends Within): every point of a is a point of b, and the interiors of the two geometries have at least one point in common.');
INSERT INTO "temploggerRelationshipOfResourceTypes" ("relationshipOfResource","resourceType", "spatialObjectType", description) VALUES ('Crosses', 'location', '{Line}', 'a crosses b: they have some but not all interior points in common, and the dimension of the intersection is less than that of at least one of them.');
INSERT INTO "temploggerRelationshipOfResourceTypes" ("relationshipOfResource","resourceType", "spatialObjectType", description) VALUES ('Disjoint', 'location', '{Point,Line,Polygon}', 'a and b are disjoint: they have no point in common. They form a set of disconnected geometries.');
INSERT INTO "temploggerRelationshipOfResourceTypes" ("relationshipOfResource","resourceType", "spatialObjectType", description) VALUES ('Equals', 'location', '{Point,Line,Polygon}', 'a and b are topologically equal. "Two geometries are topologically equal if their interiors intersect and no part of the interior or boundary of one geometry intersects the exterior of the other".');
INSERT INTO "temploggerRelationshipOfResourceTypes" ("relationshipOfResource","resourceType", "spatialObjectType", description) VALUES ('Intersects', 'location', '{Point,Line,Polygon}', 'a intersects b: geometries a and b have at least one point in common.');
INSERT INTO "temploggerRelationshipOfResourceTypes" ("relationshipOfResource","resourceType", "spatialObjectType", description) VALUES ('Overlaps', 'location', '{Polygon}', 'a overlaps b: they have some but not all points in common, they have the same dimension, and the intersection of the interiors of the two geometries has the same dimension as the geometries themselves.');
INSERT INTO "temploggerRelationshipOfResourceTypes" ("relationshipOfResource","resourceType", "spatialObjectType", description) VALUES ('Touches', 'location', '{Point,Line,Polygon}', 'a touches b: they have at least one boundary point in common, but no interior points.');
INSERT INTO "temploggerRelationshipOfResourceTypes" ("relationshipOfResource","resourceType", "spatialObjectType", description) VALUES ('Within', 'location', '{Point,Line,Polygon}', 'a is within (inside) b: a lies in the interior of b.');
INSERT INTO "temploggerRelationshipOfResourceTypes" ("relationshipOfResource","resourceType", "spatialObjectType", description) VALUES ('duplicate of', 'samplingEvent',NULL, 'a is duplicate event of b: envent a and b are identical, duplication should be removed / solved.');
INSERT INTO "temploggerRelationshipOfResourceTypes" ("relationshipOfResource","resourceType", "spatialObjectType", description) VALUES ('parentEvent', 'samplingEvent', NULL, 'a is parent event of b: envent b occured within the context of event a.');
INSERT INTO "temploggerRelationshipOfResourceTypes" ("relationshipOfResource","resourceType", "spatialObjectType", description) VALUES ('took place within', 'samplingEvent', NULL, 'event a happend in location(s) i (-j)');
INSERT INTO "temploggerRelationshipOfResourceTypes" ("relationshipOfResource","resourceType", "spatialObjectType", description) VALUES ('duplicate of', 'occurrence',NULL, 'a is duplicate occurrence of b: occurrences a and b are identical, duplication should be removed / solved.');
INSERT INTO "temploggerRelationshipOfResourceTypes" ("relationshipOfResource","resourceType", "spatialObjectType", description) VALUES ('parent of', 'occurrence',NULL,NULL);
INSERT INTO "temploggerRelationshipOfResourceTypes" ("relationshipOfResource","resourceType", "spatialObjectType", description) VALUES ('mother of', 'occurrence',NULL,NULL);
INSERT INTO "temploggerRelationshipOfResourceTypes" ("relationshipOfResource","resourceType", "spatialObjectType", description) VALUES ('father of', 'occurrence',NULL,NULL);
INSERT INTO "temploggerRelationshipOfResourceTypes" ("relationshipOfResource","resourceType", "spatialObjectType", description) VALUES ('endoparasite of', 'occurrence',NULL,NULL);
INSERT INTO "temploggerRelationshipOfResourceTypes" ("relationshipOfResource","resourceType", "spatialObjectType", description) VALUES ('host to', 'occurrence',NULL,NULL);
INSERT INTO "temploggerRelationshipOfResourceTypes" ("relationshipOfResource","resourceType", "spatialObjectType", description) VALUES ('sibling of', 'occurrence',NULL,NULL);
INSERT INTO "temploggerRelationshipOfResourceTypes" ("relationshipOfResource","resourceType", "spatialObjectType", description) VALUES ('valid synonym of', 'occurrence',NULL,NULL);


DROP TABLE IF EXISTS "temploggerLocation";
CREATE TABLE IF NOT EXISTS "temploggerLocation"
    ("locationID" serial PRIMARY KEY
    , "parentLocationID" integer -- updated by data base from relationship table
    , geom geometry(Point,25833) -- fetched from GIS
    , location varchar(50)
    , "locationRemarks" text
    , locality varchar(50) UNIQUE -- internal ID / name from/for field work
    , municipality integer -- fetched from GIS
    , county varchar(50) -- fetched from GIS
    , country varchar(50) -- fetched from GIS
    , "decimalLatitude" double precision -- fetched from GIS
    , "decimalLongitude" double precision -- fetched from GIS
    , "verbatimSRS" integer DEFAULT 4236
    , "coordinateUncertaintyInMeters" double precision -- fetched from GIS
    , "georeferenceRemarks" text
	);
COMMENT ON COLUMN "temploggerLocation"."locationID" IS
    'EPSG code, see http://tdwg.github.io/dwc/terms/index.htm#locationID';
COMMENT ON COLUMN "temploggerLocation"."verbatimSRS" IS
    'EPSG code, see http://rs.tdwg.org/dwc/terms/verbatimSRS';
CREATE INDEX "sentinel4nature_temploggerLocation_spidx"
    ON "temploggerLocation" USING gist(geom);
ALTER TABLE "temploggerLocation"
    CLUSTER ON "sentinel4nature_temploggerLocation_spidx";

DROP TABLE IF EXISTS "temploggersamplingEvent" CASCADE;
CREATE TABLE IF NOT EXISTS "temploggersamplingEvent"
    ("eventID" serial PRIMARY KEY
    , "parentEventID" integer -- updated by data base from relationship table
    -- , fieldNumber varchar(10)
    -- , eventDate timestamp with time zone
    , "eventDateStart" timestamp with time zone -- to be concatenated to DarwinCore eventDate time range
    , "eventDateEnd" timestamp with time zone -- to be concatenated to DarwinCore eventDate time range
    -- , eventTime 
    -- , startDayOfYear 
    -- , endDayOfYear 
    -- , year 
    -- , month 
    -- , day 
    -- , verbatimEventDate 
    -- , habitat 
    -- , samplingProtocol 
    , "sampleSizeValue" integer
    , "sampleSizeUnit" varchar(25)
    , samplingEffort double precision
    , samplingEffortUnit varchar(25)
    -- the following columns mainly describe the "samplingProtocol" so we do not have a specific field for that
	-- except for "samplingProtokollRemarks" they are not Darwin Core
    , "placementType" varchar(50) -- tilfeldig, tilfeldig langs transekt, systematisk langs stratifisert transect, systematisk i grid
    , "loggerGrouping" varchar(50) -- (For transekter for eksempel: hvordan grupperes/ordnes de enkle punktene)
    , "horizontalPlacementinMeter" numeric(4,2) -- på bakken, på et tre, i et hi, i en innsjoe… (Alternativt kanskje «Plassering» i høyde over bakken i meter (+/-)) 
    , project integer -- (f.eks. prosjektnummer)
    -- , "pointOfContact" -- (Prosjektleder?)
    , "samplingProtokollRemarks" text -- Kommentar (fri tekst for alt som er nyttig å vite om dataene)
    );

-- Create "tempLoggerPeriode" table if necessary
DROP TABLE IF EXISTS "tempLoggerPeriode" CASCADE;
CREATE TABLE IF NOT EXISTS "tempLoggerPeriode" 
    (locality varchar(50) -- REFERENCES "temploggerLocation" (locality)
    , "eventID" integer REFERENCES "temploggersamplingEvent" ("eventID")
    , "periodeID" integer --period: løpenummer (innenfor hver stasjon) for loggførings-perioden, dvs. mellom installasjon og data henting (i tilfellet noe ift. Plassering endrer seg hvis loggeren leses av eller batterier bytes…) Dette kan tas i noen tilfeller fra rå-dataene…)
    , "loggerType" varchar(25) REFERENCES "temploggerTypes" ("loggerType") -- Teknisk produkt (nyttig å vite fordi det er litt forskjellige rådata formatter for de forskjellige loggerne som brukes pluss at de kan innebære informasjon om kvalitet av dataene).
    , "serialNumber" varchar(50) -- (kan hentes fra rådataene)
    , temperature_c boolean
    , temperature_f boolean
    , humidity_perc boolean
    , dew_point_c boolean
    , dew_point_f boolean
    , date_first timestamp with time zone
    , date_last timestamp with time zone
    , "sampleCount" integer -- (kan hentes fra rådataene)
    , "sampleRate" double precision -- (kan hentes fra rådataene)
    , "sampleRateUnit" varchar(25) -- (kan hentes fra rådataene)
    , "rollOver" varchar(25) -- (kan hentes fra rå-dataene: disabled; enabled, no rollover occurred; enabled, rollover occurred, impossible)
	, "fieldNotes" varchar(255)
    , file_path varchar(255) UNIQUE
    , UNIQUE(locality, "eventID", "periodeID", date_first, date_last));
CREATE INDEX "sentinel4nature_tempLoggerPeriode_locality_idx"
    ON "tempLoggerPeriode" USING btree (locality ASC NULLS LAST);
ALTER TABLE "tempLoggerPeriode"
    CLUSTER ON "sentinel4nature_tempLoggerPeriode_locality_idx";
CREATE INDEX "sentinel4nature_tempLoggerPeriode_eventID_idx"
    ON "tempLoggerPeriode" USING btree ("eventID" ASC NULLS LAST);
ALTER TABLE "tempLoggerPeriode"
    CLUSTER ON "sentinel4nature_tempLoggerPeriode_eventID_idx";
CREATE INDEX "sentinel4nature_tempLoggerPeriode_periodeID_idx"
    ON "tempLoggerPeriode" USING btree ("periodeID" ASC NULLS LAST);
ALTER TABLE "tempLoggerPeriode"
    CLUSTER ON "sentinel4nature_tempLoggerPeriode_periodeID_idx";
CREATE INDEX "sentinel4nature_tempLoggerPeriode_date_first_idx"
    ON "tempLoggerPeriode" USING btree (date_first ASC NULLS LAST);
ALTER TABLE "tempLoggerPeriode"
    CLUSTER ON "sentinel4nature_tempLoggerPeriode_date_first_idx";
CREATE INDEX "sentinel4nature_tempLoggerPeriode_date_last_idx"
    ON "tempLoggerPeriode" USING btree (date_last ASC NULLS LAST);
ALTER TABLE "tempLoggerPeriode"
    CLUSTER ON "sentinel4nature_tempLoggerPeriode_date_last_idx";

DROP TABLE IF EXISTS "temploggerData";
CREATE TABLE IF NOT EXISTS "temploggerData" 
    (locality varchar(50) -- REFERENCES "temploggerLocation" (locality)
    , "eventID" integer -- REFERENCES "temploggersamplingEvent" ("eventID")
    , "periodeID" integer -- REFERENCES "tempLoggerPeriode" ("periodeID") 
    , date timestamp with time zone
    , temperature_c double precision
    , temperature_f double precision
    , humidity_perc double precision 
    , dew_point_c double precision
    , dew_point_f double precision
    -- FOREIGN KEY (locality, "eventID", "periodeID") REFERENCES "tempLoggerPeriode" (locality, "eventID", "periodeID")
    );
ALTER TABLE "temploggerData"
    ADD CONSTRAINT "sentinel4nature_temploggerData_pkey" PRIMARY KEY 
    (locality, "eventID", "periodeID", date);
CREATE INDEX "sentinel4nature_temploggerData_locality_idx"
    ON "temploggerData" USING btree (locality ASC NULLS LAST);
ALTER TABLE "temploggerData"
    CLUSTER ON "sentinel4nature_temploggerData_locality_idx";
CREATE INDEX "sentinel4nature_temploggerData_eventID_idx"
    ON "temploggerData" USING btree ("eventID" ASC NULLS LAST);
ALTER TABLE "temploggerData"
    CLUSTER ON "sentinel4nature_temploggerData_eventID_idx";
CREATE INDEX "sentinel4nature_temploggerData_periodeID_idx"
    ON "temploggerData" USING btree ("periodeID" ASC NULLS LAST);
ALTER TABLE "temploggerData"
    CLUSTER ON "sentinel4nature_temploggerData_periodeID_idx";
CREATE INDEX "sentinel4nature_temploggerData_date_idx"
    ON "temploggerData" USING btree (date ASC NULLS LAST);
ALTER TABLE "temploggerData"
    CLUSTER ON "sentinel4nature_temploggerData_date_idx";
CREATE INDEX "sentinel4nature_temploggerData_temperature_c_idx"
    ON "temploggerData" USING btree (temperature_c ASC NULLS LAST)
    WHERE temperature_c IS NOT NULL;
-- ALTER TABLE "temploggerData"
--     CLUSTER ON "sentinel4nature_temploggerData_temperature_c_idx";
CREATE INDEX "sentinel4nature_temploggerData_temperature_f_idx"
    ON "temploggerData" USING btree (temperature_f ASC NULLS LAST)
    WHERE temperature_f IS NOT NULL;
-- ALTER TABLE "temploggerData"
--     CLUSTER ON "sentinel4nature_temploggerData_temperature_f_idx";
CREATE INDEX "sentinel4nature_temploggerData_humidity_perc_idx"
    ON "temploggerData" USING btree (humidity_perc ASC NULLS LAST)
    WHERE humidity_perc IS NOT NULL;
-- ALTER TABLE "temploggerData"
--     CLUSTER ON "sentinel4nature_temploggerData_humidity_perc_idx";
CREATE INDEX "sentinel4nature_temploggerData_dew_point_c_idx"
    ON "temploggerData" USING btree (dew_point_c ASC NULLS LAST)
     WHERE dew_point_c IS NOT NULL;
-- ALTER TABLE "temploggerData"
--     CLUSTER ON "sentinel4nature_temploggerData_dew_point_c_idx";
CREATE INDEX "sentinel4nature_temploggerData_dew_point_f_idx"
    ON "temploggerData" USING btree (dew_point_f ASC NULLS LAST)
     WHERE dew_point_f IS NOT NULL;
-- ALTER TABLE "temploggerData"
--     CLUSTER ON "sentinel4nature_temploggerData_dew_point_f_idx";

DROP TABLE IF EXISTS "temploggerResourceRelationship" CASCADE;
CREATE TABLE IF NOT EXISTS "temploggerResourceRelationship"
    ("resourceRelationshipID" serial PRIMARY KEY
    , "resourceType" varchar(25) REFERENCES "temploggerRelationshipResourceTypes" ("resourceType")
    , "resourceID" integer NOT NULL -- child location or child event
    , "relatedResourceID" integer[] NOT NULL -- Maybe better as "varchar" thet can recieve IDs from all kinds of ressources
    , "relationshipOfResourceID" integer NOT NULL REFERENCES "temploggerRelationshipOfResourceTypes" ("relationshipOfResourceID")
    , "relationshipAccordingTo" integer
    , "relationshipEstablishedDate" timestamp with time zone DEFAULT clock_timestamp()
    , "relationshipRemarks" text
    , UNIQUE("resourceType", "resourceID"));

/*
for spatial relationships relations and related objects could be proposed
bulk update of spatial relations possible (select parent features and link 
all those that relate in the defined way (Intersect, Overlap, Covers, ...)
*/ 

-- Insert some test purpose data
-- sampling event 1
-- 
INSERT INTO "temploggersamplingEvent" (project) VALUES (1);

    """)

# Load data for a Sampling event (project / periode)

# - locality (from location table) extracted from file(s) (or provided manually) (locations have to exist in the DB)
# - tempLoggerPeriode / parentEvent provided manually (has to exist in the DB)
# - loggerPeriod metadata extracted from file(s) (or (maybe partly) provided manually), tempLoggerPeriode record is generated automatically

# Log successfully loaded files, files with import errors, and unser name
 # - check if "locality" exists in "location" table (not necessary if taken from dropdown list)
    # if locality not in localities:
        # ??? (copy to other table (including file name/path)
# - check if "tempLoggerPeriode" exists (not necessary if taken from dropdown list)
# - check if measurement types (temperature, lux...) and units exist in code (OrderedDict)
# - check if metadata match (data types, expected content)

 # Nesting of events?
# "Overwrite" existing data checkbox (unique-constraint on location, parentEvent, tempLoggerPeriode, timestamp
# Unique constraint on file_path (each file should be loaded only once

# Propose a temperature logger data folder

# parentEvent (Project, placement types, ...)
# tempLoggerPeriode (Mission)

###############################################################################
# To do`s:
# Aggregate automatically (to aggregate tables)
#   by day, month, year
#   using max(), min(), avg(), stddev(), variance(), percentile_disc(fraction) (5, 50, 95)
#   UPSERT tables
#   WHERE date_first <= date AND date_last >= date AND locality = locality AND eventID = eventID
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
        # - a list with the event metadata ("logPeriode")
        # - a list containing the table with the logger data ("table")
        # - a list with the columns to be written to ("columns")
        #######################################################################
        if ( filename.endswith('SWD') or filename.endswith('swd') ) and not filename.startswith('INDEX'):
            units = []
            logPeriode = []
            # Read temperature logger data
            with open(os.path.join(dirpath,filename)) as f:
                d = f.read().split('\n')
            # Extract metadata from logger file
            # Extract locality from logger file
            locality = d[0].split('\t')[0]
            # Here it might be necessary to check wheter the locality exits
            
            # '''-- Get list of possible candidates for the location
            # SELECT * FROM
            # (SELECT locality, "periodeID", file_path FROM sentinel4nature."tempLoggerPeriode") AS a,
            # (SELECT DISTINCT ON ("loggerName","placementID") * FROM sentinel4nature.temperaturelogger_location) As b
            # WHERE 
            # locality NOT IN (SELECT DISTINCT ON ("loggerName") "loggerName" FROM sentinel4nature.temperaturelogger_location) AND
            # locality NOT IN (SELECT DISTINCT ON ("placementID") "placementID" FROM sentinel4nature.temperaturelogger_location) AND
            # (b."loggerName" LIKE '%' || a.locality || '%' OR b."placementID" LIKE '%' || a.locality || '%')
            # -- locality from logger either matches "loggerName" or "placementID"
            # -- b."loggerName" = a.locality OR b."placementID" = a.locality'''
            
            # Add locality to entry in tempLoggerPeriode-table
            logPeriode.append(locality)
            # Add eventID to entry in tempLoggerPeriode-table
            logPeriode.append(eventID)
            
            # Get latest periodeID for current combination of locality and eventID
            periodeID_SQL = """SELECT max("periodeID") FROM 
                sentinel4nature."tempLoggerPeriode" WHERE locality = '{0}' 
                AND "eventID" = {1};""".format(locality, eventID)
            curs.execute(periodeID_SQL)
            # Set periodeID for current (new) temperature logger file
            periodeID = curs.fetchall()[0][0]
            if periodeID is None:
                periodeID = 1
            else:
                periodeID = int(periodeID) + 1
            
            # Add periodeID to entry in tempLoggerPeriode-table
            logPeriode.append(periodeID)
            
            # Add periodeID to entry in tempLoggerPeriode-table
            logPeriode.append(loggerType)
 
            # Some logger types write serial number to the data file
            serialNumber = 'Unkown'
            
            # Add loggerType to entry in tempLoggerPeriode-table
            logPeriode.append(serialNumber)
            
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
                # Add measurements to entry in tempLoggerPeriode-table
                if c in units:
                    logPeriode.append(True)
                else:
                    logPeriode.append(False)
            
            # Extract date of first measurement from logger file
            date_first = d[3].split('\t')[0]
            
            # Add date of first measurement to entry in tempLoggerPeriode-table
            logPeriode.append(date_first)
            
            r = 1
            while '\t' not in d[(len(d) - r)]:
                r = r + 1
            
            # Extract date of last measurement from logger file
            date_last = d[(len(d)-r)].split('\t')[0]
            
            # Add date of last measurement to entry in tempLoggerPeriode-table
            logPeriode.append(date_last)
            
            # Extract sampleCount (the number of measurements in a file)
            sampleCount = len(d) - r - 2
            
            # Add sampleCount to entry in tempLoggerPeriode-table
            logPeriode.append(sampleCount)
            
            # Create a list of columns that will receive data
            columns = 'locality,"eventID","periodeID",date,{0}'.format(value_columns).split(',')
            
            # Inject locality,"eventID","periodeID" into logger data
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
                    eventID,periodeID,values,conversion))
            
            ###################################################################
            # The following code is no longer logger type specific
            ###################################################################
            # Ask for Field notes (e.g. location flooded, logger damaged, fallover...)
			# while providing available logger periode meta information
			
            # Set rollOver (available in the metadta of some logger types)
            # 2011-07-15 00:00
            d1 = datetime.strptime(date_first, "%Y-%m-%d %H:%M")
            d2 = datetime.strptime(date_last, "%Y-%m-%d %H:%M")
            logDuration = d2 - d1
            if logDuration == 0:
                logDuration = None
            else:
                sampleRate = round((float(sampleCount) / ((logDuration.days * 86400.0 + logDuration.seconds) / 3600.0)), 2)
            # Add field notes 
            logPeriode.append(sampleRate)
            # Set sampleRateUnit (available in the metadta of some logger types)
            # Can be calculated for others
            sampleRateUnit = 'logs per hour'
            # Add sampleRateUnit 
            logPeriode.append(sampleRateUnit)
            # Set rollOver (available in the metadta of some logger types)
            rollOver = None
            # Add rollOver information 
            logPeriode.append(rollOver)
            #Set fieldNotes (should be user input)
            #fieldNotes = 'NULL'
            # Add field notes 
            logPeriode.append(fieldNotes)
            # Write path to tempLoggerPeriode entry
            logPeriode.append(os.path.join(dirpath,filename))
            
            """Generate SQL INSERT statement
            locality, "eventID", "periodeID", "loggerType", "serialNumber"
            temperature_c, temperature_f, humidity_perc, dew_point_c,
            dew_point_f, date_first, date_last, "sampleCount", "sampleRate", "sampleRateUnit", "rollOver", "fieldNotes", file_path
            """
            event_SQL = """INSERT INTO sentinel4nature."tempLoggerPeriode" 
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s);""" # Note: no quotes
            
            # Load temperature logger metadata to PostgreSQL
            curs.execute(event_SQL, tuple(logPeriode)) # Note: no % operator
            
            # Create a StingIO object to be used in the COPY statement
            data = cStringIO.StringIO()
            data.write(unicode('\n'.join(table)))
            data.seek(0)
            
            # Load temperature measurements to PostgreSQL
            curs.copy_from(data, 'sentinel4nature."temploggerData"',
                columns = tuple(columns), sep = ',', null='')
            
            # Close StringIO object to free memory
            data.close()


# Vacuum tables when all data got added
curs.execute("""VACUUM FULL ANALYZE sentinel4nature."temploggerData";""")
curs.execute("""VACUUM FULL ANALYZE sentinel4nature."tempLoggerPeriode";""")


# Code snippets for possible later usage
# '''
            # # Example for a dictionary as a switch (for unit conversions or loggerType based functions)
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
            # curs.execute("DROP TABLE sentinel4nature."temploggerData";")
            # curs.execute("CREATE TABLE IF NOT EXISTS sentinel4nature."temploggerData" (locality varchar(50), periodeID integer, date datetime with timezone, temperature_c double precision, temperature_f double precision, humidity_perc double precision, dew_point_c double precision);")


            # curs.copy_from(data, 'sentinel4nature."temploggerData"')
# '''