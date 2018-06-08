#!/bin/bash

: '
NAME:    Extracting LiDAR-based training data

AUTHOR(S): Stefan Blumentrath < stefan.blumentrath AT nina.no>

PURPOSE:   Extracting LiDAR-based training data for tree canopy cover using GRASS.
'

: '
To Dos:
'

r.in.lidar -o -v --overwrite --verbose output=Hjerkinn_LiDAR_surface file=hjerkinn.txt method=percentile base_raster=LiDAR_DTM pth=97 class_filter=1
r.in.lidar -o -v --overwrite --verbose output=Hjerkinn_LiDAR_ground file=hjerkinn.txt method=n type=CELL pth=1 class_filter=2


g.region -p raster=Hjerkinn_LiDAR_surface zoom=Hjerkinn_LiDAR_surface align=Hjerkinn_LiDAR_surface
r.mapcalc --o expression="Hjerkinn_cannopy_pre=if(isnull(Hjerkinn_LiDAR_surface),0,if(Hjerkinn_LiDAR_surface>2,1,0))"
r.mapcalc --o expression="Hjerkinn_ground_pre=if(isnull(Hjerkinn_LiDAR_surface),if(isnull(Hjerkinn_LiDAR_ground)||Hjerkinn_LiDAR_ground==0,0,1),if(Hjerkinn_LiDAR_surface<=2,1,0))"

g.region -p raster=Hjerkinn_cannopy_pre zoom=Hjerkinn_cannopy_pre align=dem_10m_nosefi_float@g_Elevation_Fenoscandia
r.resamp.stats --o -n -w input=Hjerkinn_cannopy_pre output=Hjerkinn_cannopy method=sum
r.resamp.stats --o -n -w -n input=Hjerkinn_ground_pre output=Hjerkinn_ground method=sum

r.mapcalc --o expression="Hjerkinn_LiDAR_cannopy_training=if((isnull(LiDAR_DTM[1,1])||\
isnull(LiDAR_DTM[1,0])||\
isnull(LiDAR_DTM[1,-1])||\
isnull(LiDAR_DTM[0,1])||\
isnull(LiDAR_DTM[0,-1])||\
isnull(LiDAR_DTM[-1,1])||\
isnull(LiDAR_DTM[-1,0])||\
isnull(LiDAR_DTM[-1,-1])),null(),round(int(float(Hjerkinn_cannopy)/float(Hjerkinn_cannopy+Hjerkinn_ground)*100.0)))"


g.region -p vector=Luroeykalven_valid_LiDAR align=Luroeykalven_LiDAR_surface
v.to.rast input=Luroeykalven_valid_LiDAR output=Luroeykalven_valid_LiDAR use=val

g.region -p raster=Luroeykalven_LiDAR_surface zoom=Luroeykalven_LiDAR_surface align=Luroeykalven_LiDAR_surface
r.mapcalc --o expression="Luroeykalven_cannopy_pre=if(Luroeykalven_valid_LiDAR,if(isnull(Luroeykalven_LiDAR_surface),0,if(Luroeykalven_LiDAR_surface>2,1,0)))"
r.mapcalc --o expression="Luroeykalven_ground_pre=if(Luroeykalven_valid_LiDAR,if(isnull(Luroeykalven_LiDAR_surface),if(isnull(Luroeykalven_LiDAR_ground)||Luroeykalven_LiDAR_ground==0,0,1),if(Luroeykalven_LiDAR_surface<=2,1,0)))"

g.region -p raster=Luroeykalven_cannopy_pre zoom=Luroeykalven_cannopy_pre align=dem_10m_nosefi_float@g_Elevation_Fenoscandia
r.resamp.stats --o -n -w input=Luroeykalven_cannopy_pre output=Luroeykalven_cannopy method=sum
r.resamp.stats --o -n -w -n input=Luroeykalven_ground_pre output=Luroeykalven_ground method=sum

r.mapcalc --o expression="Luroeykalven_LiDAR_cannopy_training=if((isnull(Luroeykalven_valid_LiDAR[1,1])||\
isnull(Luroeykalven_valid_LiDAR[1,0])||\
isnull(Luroeykalven_valid_LiDAR[1,-1])||\
isnull(Luroeykalven_valid_LiDAR[0,1])||\
isnull(Luroeykalven_valid_LiDAR[0,-1])||\
isnull(Luroeykalven_valid_LiDAR[-1,1])||\
isnull(Luroeykalven_valid_LiDAR[-1,0])||\
isnull(Luroeykalven_valid_LiDAR[-1,-1])),null(),round(int(float(Luroeykalven_cannopy)/float(Luroeykalven_cannopy+Luroeykalven_ground)*100.0)))"



g.region -p vector=Dovre_valid_LiDAR align=Dovre_LiDAR_surface
v.to.rast input=Dovre_valid_LiDAR output=Dovre_valid_LiDAR use=val

g.region -p raster=Dovre_LiDAR_surface zoom=Dovre_LiDAR_surface align=Dovre_LiDAR_surface
r.mapcalc --o expression="Dovre_cannopy_pre=if(Dovre_valid_LiDAR,if(isnull(Dovre_LiDAR_surface),0,if(Dovre_LiDAR_surface>2,1,0)))"
r.mapcalc --o expression="Dovre_ground_pre=if(Dovre_valid_LiDAR,if(isnull(Dovre_LiDAR_surface),if(isnull(Dovre_LiDAR_ground)||Dovre_LiDAR_ground==0,0,1),if(Dovre_LiDAR_surface<=2,1,0)))"

g.region -p raster=Dovre_cannopy_pre zoom=Dovre_cannopy_pre align=dem_10m_nosefi_float@g_Elevation_Fenoscandia
r.resamp.stats --o -n -w input=Dovre_cannopy_pre output=Dovre_cannopy method=sum
r.resamp.stats --o -n -w -n input=Dovre_ground_pre output=Dovre_ground method=sum

r.mapcalc --o expression="Dovre_LiDAR_cannopy_training=if((isnull(Dovre_valid_LiDAR[1,1])||\
isnull(Dovre_valid_LiDAR[1,0])||\
isnull(Dovre_valid_LiDAR[1,-1])||\
isnull(Dovre_valid_LiDAR[0,1])||\
isnull(Dovre_valid_LiDAR[0,-1])||\
isnull(Dovre_valid_LiDAR[-1,1])||\
isnull(Dovre_valid_LiDAR[-1,0])||\
isnull(Dovre_valid_LiDAR[-1,-1])),null(),round(int(float(Dovre_cannopy)/float(Dovre_cannopy+Dovre_ground)*100.0)))"

