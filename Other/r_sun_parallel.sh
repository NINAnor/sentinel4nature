#!/bin/bash

#Solinnstråling
days=$(echo "0 20 40 60 80 100 120 140 160 180 200 220 240 260 280 300 320 340 360")
for d in $days
do
echo $d >> /home/stefan/tmp/horizon.steps
done

g.region -p raster=dem_10m_nosefi_float

r.to.vect --overwrite --verbose input=dem_10m_nosefi_land@PERMANENT output=dem_10m_nosefi_land type=area
v.mkgrid --overwrite --verbose map=grid_pre grid=38,28 position=coor coordinates=-77335,6132475 box=50000,50000
#v.mkgrid --overwrite --verbose map=grid_25_pre grid=76,56 position=coor coordinates=-77335,6132475 box=25000,25000
v.select --overwrite --verbose ainput=grid_pre atype=area binput=dem_10m_nosefi_land btype=area output=grid operator=overlap
# v.in.region --overwrite --verbose output=region
v.category --overwrite --verbose input=grid layer=2 type=boundary output=grid_bounds option=add
v.to.db -p --verbose map=grid_bounds layer=2 option=sides | cut -f2,3 -d'|' | tr '|' ' ' | awk '{if($1==-1) print $2; else if($2==-1) print $1}' | sort -n | uniq > ./boundary_tiles.txt

NUM_CORES=37

for t in $(v.db.select -c grid column=cat)
do
T_STR=$(echo $t | awk '{printf("%.04d", $1)}')
v.extract --q --o -t input=grid cats=$t output=t$T_STR

if [ $(grep -c ^$t$ ./boundary_tiles.txt) -gt 0 ] ; then
g.region -p vector=t${T_STR} align=dem_10m_nosefi_float zoom=dem_10m_nosefi_float
else
g.region -p vector=t${T_STR} align=dem_10m_nosefi_float
fi

echo "0 20 40 60 80 100 120 140 160 180 200 220 240 260 280 300 320 340 360" | tr ' ' '\n' | xargs -P $NUM_CORES -n 1 -I{} \
r.horizon --v --o elevation=dem_10m_nosefi_float@PERMANENT direction={} maxdistance=15000 bufferzone=15000 output=dem_10m_nosefi_float_horizon_tile_${T_STR}
done

#0 20 40 60 80 100 120 140 160 180 200 220 240 260 280 300 320 340 360
for d in $(seq $BEGIN $STEP $END)
do
str=$(echo $d | awk '{printf"%.03d", $1}')
maps=$(g.list type=raster pattern=GlobalRadiation_*_$str mapset=terrain_SolarRadiation | wc -l)
if [ $maps != 49 ] ; then
echo $str " = " $maps
fi
#cats=$(g.list type=raster pattern=dem_10m_nosefi_float_horizon_tile_*_day_${str} | cut -f7 -d'_' | sed -e 's/^0//g;s/^0//g;s/^0//g' | tr '\n' ',' | sed 's/,$/\n/')
#v.db.select -c map=grid columns=cat where="cat NOT IN (${cats})"
done

##Alternativt
#r.horizon --verbose elevin=DEM_10m@PERMANENT horizonstep=20 bufferzone=1000 maxdistance=5000 horizon=DEM_10m_horizon dist=1.5
#288 289 290 291 292 293 294 311 312 313 314 315 316 317 339 340 341 342 343 344 345 367 368 369 370 371 372 373 395 396 397 398 399 400 401 423 424 425 426 427 428 429 451 452 453 454 455 456 457
BEGIN=5
END=365
STEP=5
 # AND cat NOT IN (288, 289, 290, 291, 292, 293, 294, 311, 312, 313, 314, 315, 316, 317, 339, 340, 341, 342, 343, 344, 345, 367, 368, 369, 370, 371, 372, 373, 395, 396, 397, 398, 399, 400, 401, 423, 424, 425, 426, 427, 428, 429, 451, 452, 453, 454, 455, 456, 457)")
for t in $(v.db.select -c map=grid_no@ninsbl columns=cat where="cat > 972")
do

T_STR=$(echo $t | awk '{printf("%.04d", $1)}')

if [ $(grep -c ^$t$ ./boundary_tiles.txt) -gt 0 ] ; then
g.region -p vector=t${T_STR} align=dem_10m_nosefi_float zoom=dem_10m_nosefi_float
else
g.region -p vector=t${T_STR} align=dem_10m_nosefi_float
fi

r.stats -gn1 dem_10m_nosefi_land | cs2cs -E -f "%.6f" +proj=utm +no_defs +zone=33 +a=6378137 +rf=298.257222101 +towgs84=0.000,0.000,0.000 +to_meter=1 +to +proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs | tr '\t' ' ' | r.in.xyz --o --v z=4 input=- output=dem_10m_nosefi_longitude_tile_$T_STR separator=space
r.stats -gn1 dem_10m_nosefi_land | cs2cs -E -f "%.6f" +proj=utm +no_defs +zone=33 +a=6378137 +rf=298.257222101 +towgs84=0.000,0.000,0.000 +to_meter=1 +to +proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs | tr '\t' ' ' | r.in.xyz --o --v z=5 input=- output=dem_10m_nosefi_latitude_tile_$T_STR separator=space

seq $BEGIN $STEP $END  | awk '{printf("%s %.03d\n", $1,$1)}' | awk -v T=$T_STR '{print("r.sun --o --v elevation=dem_10m_nosefi_float slope=dem_10m_nosefi_float_slope aspect=dem_10m_nosefi_float_aspect long=dem_10m_nosefi_longitude_tile_" T " lat=dem_10m_nosefi_latitude_tile_" T " horizon_basename=dem_10m_nosefi_float_horizon_tile_" T " horizon_step=20 day=" $1 " step=0.5 glob_rad=GlobalRadiation_tile_" T "_day_" $2 " insol_time=InsolationTime_tile_" T "_day_" $2 "\0")}' | xargs -P $NUM_CORES -0 -I{} bash -c "{}"
seq $BEGIN $STEP $END  | awk '{printf("%s %.03d\n", $1,$1)}' | awk -v T=$T_STR '{print("g.rename raster=GlobalRadiation_tile_" T "_day_" $2 ",GlobalRadiation_tile_" T "_day_" $2 "_tmp && r.mapcalc --o expression=\"GlobalRadiation_tile_" T "_day_" $2 "=round(GlobalRadiation_tile_" T "_day_" $2 "_tmp)\" && g.remove -f type=raster name=GlobalRadiation_tile_" T "_day_" $2 "_tmp\0")}' | xargs -P $NUM_CORES -0 -I{} bash -c "{}"
seq $BEGIN $STEP $END  | awk '{printf("%s %.03d\n", $1,$1)}' | awk -v T=$T_STR '{print("g.rename raster=InsolationTime_tile_" T "_day_" $2 ",InsolationTime_tile_" T "_day_" $2 "_tmp && r.mapcalc --o expression=\"InsolationTime_tile_" T "_day_" $2 "=round(InsolationTime_tile_" T "_day_" $2 "_tmp)\" && g.remove -f type=raster name=InsolationTime_tile_" T "_day_" $2 "_tmp\0")}' | xargs -P $NUM_CORES -0 -I{} bash -c "{}"
 
done
 
for DAY in `seq $BEGIN $STEP $END`
do
DAY_STR=`echo $DAY | awk '{printf("%.03d", $1)}'`
#echo $DAY >> /home/stefan/tmp/day.steps
r.sun  --overwrite --verbose elevation=dem_10m_nosefi_float long=dem_10m_nosefi_longitude_tile_$t lat=dem_10m_nosefi_latitude_tile_$t \
horizon_basename=dem_10m_nosefi_float_horizon_tile_${T_STR} horizon_step=20 \
day=$DAY step=1 glob_rad=GlobalRadiation_tile_${T_STR}_$DAY_STR \
insol_time=InsolationTime_tile_${T_STR}_$DAY_STR
done
done 
