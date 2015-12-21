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

import os
import datetime
import csv
import psycopg2
#import sys
#import subprocess
#import logging



#Conect to PostGIS using psycopg2 module
try:
    conn = psycopg2.connect("dbname='gisdata' user='stefan' host='ninsrv16' password='*************'")
except:
    logging.info("Unable to connect to the database")

conn.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT)


logger_dir = 'C:\data\Prosjekter\Sentinel4Nature\'
samplingEvent = ''

curs = conn.cursor()
curs.execute("SELECT DISTINCT ON (name) name from sentinel4nature.templogger_location;")
curs.fetchall()

'''
Load data for a Sampling event (project / periode)

- samplingEvent provided manually (has to exist in the DB)
- Location extracted from file(s) (or provided manually) (Locations have to exist in the DB)
- Mission metadata extracted from file(s) (or (maybe partly) provided manually) Mission record is generated automatically

Log successfully loaded files, files with import errors, and unser name
 - check if "name" exists in "location" table (not necessary if taken from dropdown list)
 - check if "samplingEvent" exists (not necessary if taken from dropdown list)
 - check number of columns
 - check if units exist in code
 - check if measurement types (temperature, lux...) exist in code
 - check if metadata match (data types, expected content)

"Overwrite" existing data checkbox (unique-constraint on location, sampling event, mission


'''

# Find all temperature logger files in provided folder
for dirpath, dirnames, filenames in os.walk(logger_dir):
  for f in  filenames:
        if f.endswith('SWD') or f.endswith('swd'):
            print os.path.join(dirpath,f)

# Read temperature logger data
with open('C:\data\Prosjekter\Sentinel4Nature\Temperatur_Logger\Nina_Eide\SD201107.SWD') as f:
    d = f.read().split('\n')

# Extract metadata
locality = d[0].split('\t')[0]
temperature_unit = d[1].split('\t')[1] # '*F'
humidity_unit = d[1].split('\t')[2] # '%'

first_date = d[3].split('\t')[0]
last_date = d[(len(d)-1].split('\t')[0]

# Example for a dictionary as a switch (for unit conversions)
op = '*'
part1 = 2
part3 = 4

d = {
    '+': lambda x,y: x+y,
    '-': lambda x,y: x-y,
    '*': lambda x,y: x*y,
    '/': lambda x,y: x/y
    }

try:
    print(d[op](part1, part3))
except KeyError:
    default()


# Load data to PostgreSQL using the COPY command
for line in d[3:len(d)-1]:
    temp = float(line.split('\t')[1].replace(',','.'))
    print '\t'.join(locality) + ',' + str(float(line.split('\t')[1].replace(',','.')))

curs = conn.cursor()
curs.execute("DROP TABLE sentinel4nature.templogger_data;")
curs.execute("CREATE TABLE sentinel4nature.templogger_data (locality varchar(50), date datetime with timezone, temperature_c double precision, temperature_f double precision, humidity_perc double precision);")

# anything can be used as a file if it has .read() and .readline() methods
data = StringIO.StringIO()
data.write('\n'.join(['Tom\tJenkins\t37',
                  'Madonna\t\N\t45',
                  'Federico\tDi Gregorio\t\N']))
data.seek(0)

curs.copy_from(data, 'test_copy')
