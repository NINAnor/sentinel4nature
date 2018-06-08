#Import DEM_10m_fernoscandia

#Import "old" Landsatdata .jpg

g.region 
r.in.gdal input=/data/home/jacob/Avd15GIS/Prosjekter/Sentinel4Nature/Landsat/Landsatdata/Landsat_1-5_MMS/Hjerkinn/LM1_214_017_1972_286_AAA05/LM1_214_017_1972_286_AAA05.jpg output=LM1_214_017_1972_286_AAA05 --overwrite -k


# set region vector
g.region -p vector=hjerkinn_area1_graduated_grid_forest@Sentinel4Nature_Hjerkinn align=LC8_198_017_2013_193_LGN00_sr_band1@Sentinel4Nature_Hjerkinn

#vector to raster
v.to.rast --overwrite --verbose input=hjerkinn_area2_graduated_grid_forest@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_graduated_grid_forest use=attr attribute_column=area_trees
---------------------------------------------------------------------------------------------------------
### AREA 1

## NDVI
# hjerkinn_area1_ndvi_2013_193
g.region -p vector=hjerkinn_area1_graduated_grid_forest@Sentinel4Nature_Hjerkinn align=LC8_198_017_2013_193_LGN00_sr_band4@Sentinel4Nature_Hjerkinn
i.vi red=LC8_198_017_2013_193_LGN00_sr_band4@Sentinel4Nature_Hjerkinn output=hjerkinn_area1_ndvi_2013_193 viname=ndvi nir=LC8_198_017_2013_193_LGN00_sr_band5@Sentinel4Nature_Hjerkinn
r.colors map=hjerkinn_area1_ndvi_2013_193@Sentinel4Nature_Hjerkinn color=ndvi            

# hjerkinn_area1_ndvi_2014_258
i.vi red=LC8_200_016_2014_258_LGN00_sr_band4@Sentinel4Nature_Hjerkinn output=hjerkinn_area1_ndvi_2014_258 viname=ndvi nir=LC8_200_016_2014_258_LGN00_sr_band5@Sentinel4Nature_Hjerkinn
r.colors map=hjerkinn_area1_ndvi_2014_258@Sentinel4Nature_Hjerkinn color=ndvi            

# hjerkinn_area1_ndvi_2014_260
i.vi red=LC8_198_017_2014_260_LGN00_sr_band4@Sentinel4Nature_Hjerkinn output=hjerkinn_area1_ndvi_2014_260 viname=ndvi nir=LC8_198_017_2014_260_LGN00_sr_band5@Sentinel4Nature_Hjerkinn
r.colors map=hjerkinn_area1_ndvi_2014_260@Sentinel4Nature_Hjerkinn color=ndvi            

## TASSELED CAP VEG INDEX

#tasseled cap veg index 2013_193
g.region -p raster=hjerkinn_area1_graduated_grid_forest@Sentinel4Nature_Hjerkinn align=LC8_198_017_2013_193_LGN00_sr_band4@Sentinel4Nature_Hjerkinn
i.tasscap --overwrite --verbose input=LC8_198_017_2013_193_LGN00_sr_band2@Sentinel4Nature_Hjerkinn,LC8_198_017_2013_193_LGN00_sr_band3@Sentinel4Nature_Hjerkinn,LC8_198_017_2013_193_LGN00_sr_band4@Sentinel4Nature_Hjerkinn,LC8_198_017_2013_193_LGN00_sr_band5@Sentinel4Nature_Hjerkinn,LC8_198_017_2013_193_LGN00_sr_band6@Sentinel4Nature_Hjerkinn,LC8_198_017_2013_193_LGN00_sr_band7@Sentinel4Nature_Hjerkinn output=hjerkinn_area1_tas_cap_veg_index_2013_193 sensor=landsat8_oli

# tasseled cap veg index 2014_258
i.tasscap --overwrite --verbose input=LC8_200_016_2014_258_LGN00_sr_band2@Sentinel4Nature_Hjerkinn,LC8_200_016_2014_258_LGN00_sr_band3@Sentinel4Nature_Hjerkinn,LC8_200_016_2014_258_LGN00_sr_band4@Sentinel4Nature_Hjerkinn,LC8_200_016_2014_258_193_LGN00_sr_band5@Sentinel4Nature_Hjerkinn,LC8_LC8_200_016_2014_258_LGN00_sr_band6@Sentinel4Nature_Hjerkinn,LC8_LC8_200_016_2014_258_LGN00_sr_band7@Sentinel4Nature_Hjerkinn output=hjerkinn_area1_tas_cap_veg_index_2014_258 sensor=landsat8_oli

# tasseled cap veg index 2014_260
i.tasscap --overwrite --verbose input=LC8_198_017_2014_260_LGN00_sr_band2@Sentinel4Nature_Hjerkinn,LC8_198_017_2014_260_LGN00_sr_band3@Sentinel4Nature_Hjerkinn,LC8_198_017_2014_260_LGN00_sr_band4@Sentinel4Nature_Hjerkinn,LC8_198_017_2014_260_LGN00_sr_band5@Sentinel4Nature_Hjerkinn,LC8_198_017_2014_260_LGN00_sr_band6@Sentinel4Nature_Hjerkinn,LC8_198_017_2014_260_LGN00_sr_band7@Sentinel4Nature_Hjerkinn output=hjerkinn_area1_tas_cap_veg_index_2014_260 sensor=landsat8_oli

## SLOPE AND ASPECT
r.slope.aspect elevation=dem_10m_fenoscandia@Sentinel4Nature_Hjerkinn slope=hjerkinn_area1_slope aspect=hjerkinn_area1_aspect pcurvature=hjerkinn_area1_profc

# resamp stats from 0,5 to 0.3 resolution
r.resamp.stats --overwrite --verbose input=hjerkinn_area1_slope@Sentinel4Nature_Hjerkinn output=hjerkinn_area1_slope@Sentinel4Nature_Hjerkinn quantile=0.3
r.resamp.stats --overwrite --verbose input=hjerkinn_area1_aspect@Sentinel4Nature_Hjerkinn output=hjerkinn_area1_aspect@Sentinel4Nature_Hjerkinn quantile=0.3
r.resamp.stats --overwrite --verbose input=hjerkinn_area1_profc@Sentinel4Nature_Hjerkinn output=hjerkinn_area1_profc@Sentinel4Nature_Hjerkinn quantile=0.3

## NEIGHBORHOOD ANALYSIS
## DEM_avg11
r.neighbors -c input=dem_10m_fenoscandia@Sentinel4Nature_Hjerkinn output=hjerkinn_area1_avg11 size=11
r.resamp.stats --overwrite --verbose input=hjerkinn_area1_avg11@Sentinel4Nature_Hjerkinn output=hjerkinn_area1_avg11@Sentinel4Nature_Hjerkinn quantile=0.3

## NDVI 2013_193
g.region -p raster=hjerkinn_area1_graduated_grid_forest@Sentinel4Nature_Hjerkinn align=LC8_198_017_2013_193_LGN00_sr_band4@Sentinel4Nature_Hjerkinn
# ndvi avg
r.neighbors -c --overwrite --verbose input=hjerkinn_area1_ndvi_2013_193@Sentinel4Nature_Hjerkinn output=hjerkinn_area1_ndvi_2013_193_avg@Sentinel4Nature_Hjerkinn method=average
# ndvi min
r.neighbors -c --overwrite --verbose input=hjerkinn_area1_ndvi_2013_193@Sentinel4Nature_Hjerkinn output=hjerkinn_area1_ndvi_2013_193_min@Sentinel4Nature_Hjerkinn method=minimum
# ndvi max
r.neighbors -c --overwrite --verbose input=hjerkinn_area1_ndvi_2013_193@Sentinel4Nature_Hjerkinn output=hjerkinn_area1_ndvi_2013_193_max@Sentinel4Nature_Hjerkinn method=maximum
# ndvi stddev
r.neighbors -c --overwrite --verbose input=hjerkinn_area1_ndvi_2013_193@Sentinel4Nature_Hjerkinn output=hjerkinn_area1_ndvi_2013_193_stddev@Sentinel4Nature_Hjerkinn method=stddev

## NDVI 2014_258
g.region -p raster=hjerkinn_area1_graduated_grid_forest@Sentinel4Nature_Hjerkinn align=LC8_198_017_2013_193_LGN00_sr_band4@Sentinel4Nature_Hjerkinn
# ndvi avg
r.neighbors -c --overwrite --verbose input=hjerkinn_area1_ndvi_2014_258@Sentinel4Nature_Hjerkinn output=hjerkinn_area1_ndvi_2014_258_avg@Sentinel4Nature_Hjerkinn method=average
# ndvi min
r.neighbors -c --overwrite --verbose input=hjerkinn_area1_ndvi_2014_258@Sentinel4Nature_Hjerkinn output=hjerkinn_area1_ndvi_2014_258_min@Sentinel4Nature_Hjerkinn method=minimum
# ndvi max
r.neighbors -c --overwrite --verbose input=hjerkinn_area1_ndvi_2014_258@Sentinel4Nature_Hjerkinn output=hjerkinn_area1_ndvi_2014_258_max@Sentinel4Nature_Hjerkinn method=maximum
# ndvi stddev
r.neighbors -c --overwrite --verbose input=hjerkinn_area1_ndvi_2014_258@Sentinel4Nature_Hjerkinn output=hjerkinn_area1_ndvi_2014_258_stddev@Sentinel4Nature_Hjerkinn method=stddev

## NDVI 2014_260
g.region -p raster=hjerkinn_area1_graduated_grid_forest@Sentinel4Nature_Hjerkinn align=LC8_198_017_2013_193_LGN00_sr_band4@Sentinel4Nature_Hjerkinn
# ndvi avg
r.neighbors -c --overwrite --verbose input=hjerkinn_area1_ndvi_2014_260@Sentinel4Nature_Hjerkinn output=hjerkinn_area1_ndvi_2014_260_avg@Sentinel4Nature_Hjerkinn method=average
# ndvi min
r.neighbors -c --overwrite --verbose input=hjerkinn_area1_ndvi_2014_260@Sentinel4Nature_Hjerkinn output=hjerkinn_area1_ndvi_2014_260_min@Sentinel4Nature_Hjerkinn method=minimum
# ndvi max
r.neighbors -c --overwrite --verbose input=hjerkinn_area1_ndvi_2014_260@Sentinel4Nature_Hjerkinn output=hjerkinn_area1_ndvi_2014_260_max@Sentinel4Nature_Hjerkinn method=maximum
# ndvi stddev
r.neighbors -c --overwrite --verbose input=hjerkinn_area1_ndvi_2014_260@Sentinel4Nature_Hjerkinn output=hjerkinn_area1_ndvi_2014_260_stddev@Sentinel4Nature_Hjerkinn method=stddev

## PARAMSCALE
r.param.scale --overwrite --verbose input=dem_10m_fenoscandia@Sentinel4Nature_Hjerkinn output=hjerkinn_area1_paramscale

## TOPIDX
r.topidx --overwrite --verbose input=dem_10m_fenoscandia@Sentinel4Nature_Hjerkinn output=hjerkinn_area1_topidx

## WATERSHED
r.watershed --overwrite elevation=dem_10m_fenoscandia@Sentinel4Nature_Hjerkinn threshold=10 accumulation=hjerkinn_area1_watershed_accumulation tci=hjerkinn_area1_watershed_tci slope_steepness=hjerkinn_area1_watershed_slope_steepness


-------------------------------------------------------------------------------------------------------
### AREA 2

## IMPORT VECTOR
v.in.ogr input=/data/home/jacob/Avd15GIS/Prosjekter/Sentinel4Nature/Forest_cover/Hjerkinn/Area_2/hjerkinn_area2_graduated_grid_forest.dbf layer=hjerkinn_area2_graduated_grid_forest output=hjerkinn_area2_graduated_grid_forest geometry=None --overwrite -c -e
#

## SET REGION VECTOR
g.region -p vector=hjerkinn_area2_graduated_grid_forest@Sentinel4Nature_Hjerkinn align=LC8_198_017_2013_193_LGN00_sr_band4@Sentinel4Nature_Hjerkinn

## VECTOR TO RASTER
v.to.rast --overwrite --verbose input=hjerkinn_area2_graduated_grid_forest@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_graduated_grid_forest use=attr attribute_column=area_trees

## SET REGION RASTER
g.region -p raster=hjerkinn_area2_graduated_grid_forest@Sentinel4Nature_Hjerkinn align=LC8_198_017_2013_193_LGN00_sr_band4@Sentinel4Nature_Hjerkinn

## NDVI
# ndvi area_2_2013_193
g.region -p raster=hjerkinn_area2_graduated_grid_forest@Sentinel4Nature_Hjerkinn align=LC8_198_017_2013_193_LGN00_sr_band4@Sentinel4Nature_Hjerkinn
i.vi red=LC8_198_017_2013_193_LGN00_sr_band4@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_ndvi_2013_193 viname=ndvi nir=LC8_198_017_2013_193_LGN00_sr_band5@Sentinel4Nature_Hjerkinn
r.colors map=hjerkinn_area2_ndvi_2013_193@Sentinel4Nature_Hjerkinn color=ndvi            

# ndvi area_2_2014_258
i.vi red=LC8_200_016_2014_258_LGN00_sr_band4@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_ndvi_2014_258 viname=ndvi nir=LC8_200_016_2014_258_LGN00_sr_band5@Sentinel4Nature_Hjerkinn
r.colors map=hjerkinn_area2_ndvi_2014_258@Sentinel4Nature_Hjerkinn color=ndvi            

# ndvi area_2_2014_260
i.vi red=LC8_198_017_2014_260_LGN00_sr_band4@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_ndvi_2014_260 viname=ndvi nir=LC8_198_017_2014_260_LGN00_sr_band5@Sentinel4Nature_Hjerkinn
r.colors map=hjerkinn_area2_ndvi_2014_260@Sentinel4Nature_Hjerkinn color=ndvi    

## TASSELED CAP VEG INDEX

#tasseled cap veg index 2013_193
g.region -p raster=hjerkinn_area2_graduated_grid_forest@Sentinel4Nature_Hjerkinn align=LC8_198_017_2013_193_LGN00_sr_band4@Sentinel4Nature_Hjerkinn
i.tasscap --overwrite --verbose input=LC8_198_017_2013_193_LGN00_sr_band2@Sentinel4Nature_Hjerkinn,LC8_198_017_2013_193_LGN00_sr_band3@Sentinel4Nature_Hjerkinn,LC8_198_017_2013_193_LGN00_sr_band4@Sentinel4Nature_Hjerkinn,LC8_198_017_2013_193_LGN00_sr_band5@Sentinel4Nature_Hjerkinn,LC8_198_017_2013_193_LGN00_sr_band6@Sentinel4Nature_Hjerkinn,LC8_198_017_2013_193_LGN00_sr_band7@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_tas_cap_veg_index_2013_193 sensor=landsat8_oli

# tasseled cap veg index 2014_258
i.tasscap --overwrite --verbose input=LC8_200_016_2014_258_LGN00_sr_band2@Sentinel4Nature_Hjerkinn,LC8_200_016_2014_258_LGN00_sr_band3@Sentinel4Nature_Hjerkinn,LC8_200_016_2014_258_LGN00_sr_band4@Sentinel4Nature_Hjerkinn,LC8_200_016_2014_258_193_LGN00_sr_band5@Sentinel4Nature_Hjerkinn,LC8_LC8_200_016_2014_258_LGN00_sr_band6@Sentinel4Nature_Hjerkinn,LC8_LC8_200_016_2014_258_LGN00_sr_band7@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_tas_cap_veg_index_2014_258 sensor=landsat8_oli

# tasseled cap veg index 2014_260
i.tasscap --overwrite --verbose input=LC8_198_017_2014_260_LGN00_sr_band2@Sentinel4Nature_Hjerkinn,LC8_198_017_2014_260_LGN00_sr_band3@Sentinel4Nature_Hjerkinn,LC8_198_017_2014_260_LGN00_sr_band4@Sentinel4Nature_Hjerkinn,LC8_198_017_2014_260_LGN00_sr_band5@Sentinel4Nature_Hjerkinn,LC8_198_017_2014_260_LGN00_sr_band6@Sentinel4Nature_Hjerkinn,LC8_198_017_2014_260_LGN00_sr_band7@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_tas_cap_veg_index_2014_260 sensor=landsat8_oli

## SLOPE AND ASPECT
g.region -p raster=hjerkinn_area2_graduated_grid_forest@Sentinel4Nature_Hjerkinn align=LC8_198_017_2013_193_LGN00_sr_band4@Sentinel4Nature_Hjerkinn
r.slope.aspect --overwrite --verbose elevation=dem_10m_fenoscandia@Sentinel4Nature_Hjerkinn slope=hjerkinn_area2_slope aspect=hjerkinn_area2_aspect pcurvature=hjerkinn_area2_profc

# resamp stats from 0,5 to 0.3 resolution
r.resamp.stats --overwrite --verbose input=hjerkinn_area2_slope@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_slope@Sentinel4Nature_Hjerkinn quantile=0.3
r.resamp.stats --overwrite --verbose input=hjerkinn_area2_aspect@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_aspect@Sentinel4Nature_Hjerkinn quantile=0.3
r.resamp.stats --overwrite --verbose input=hjerkinn_area2_profc@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_profc@Sentinel4Nature_Hjerkinn quantile=0.3

## NEIGHBORHOOD ANALYSIS
## DEM avg11
r.neighbors -c input=dem_10m_fenoscandia@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_avg11 size=11
r.resamp.stats --overwrite --verbose input=hjerkinn_area2_avg11@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_avg11@Sentinel4Nature_Hjerkinn quantile=0.3

## NEIGHBORHOOD NDVI
## NDVI 2013_193
g.region -p raster=hjerkinn_area2_graduated_grid_forest@Sentinel4Nature_Hjerkinn align=LC8_198_017_2013_193_LGN00_sr_band4@Sentinel4Nature_Hjerkinn
# ndvi avg
r.neighbors -c --overwrite --verbose input=hjerkinn_area2_ndvi_2013_193@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_ndvi_2013_193_avg@Sentinel4Nature_Hjerkinn method=average
# ndvi min
r.neighbors -c --overwrite --verbose input=hjerkinn_area2_ndvi_2013_193@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_ndvi_2013_193_min@Sentinel4Nature_Hjerkinn method=minimum
# ndvi max
r.neighbors -c --overwrite --verbose input=hjerkinn_area2_ndvi_2013_193@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_ndvi_2013_193_max@Sentinel4Nature_Hjerkinn method=maximum
# ndvi stddev
r.neighbors -c --overwrite --verbose input=hjerkinn_area2_ndvi_2013_193@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_ndvi_2013_193_stddev@Sentinel4Nature_Hjerkinn method=stddev

## NDVI 2014_258
g.region -p raster=hjerkinn_area2_graduated_grid_forest@Sentinel4Nature_Hjerkinn align=LC8_198_017_2013_193_LGN00_sr_band4@Sentinel4Nature_Hjerkinn
# ndvi avg
r.neighbors -c --overwrite --verbose input=hjerkinn_area2_ndvi_2014_258@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_ndvi_2014_258_avg@Sentinel4Nature_Hjerkinn method=average
# ndvi min
r.neighbors -c --overwrite --verbose input=hjerkinn_area2_ndvi_2014_258@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_ndvi_2014_258_min@Sentinel4Nature_Hjerkinn method=minimum
# ndvi max
r.neighbors -c --overwrite --verbose input=hjerkinn_area2_ndvi_2014_258@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_ndvi_2014_258_max@Sentinel4Nature_Hjerkinn method=maximum
# ndvi stddev
r.neighbors -c --overwrite --verbose input=hjerkinn_area2_ndvi_2014_258@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_ndvi_2014_258_stddev@Sentinel4Nature_Hjerkinn method=stddev

## NDVI 2014_260
g.region -p raster=hjerkinn_area2_graduated_grid_forest@Sentinel4Nature_Hjerkinn align=LC8_198_017_2013_193_LGN00_sr_band4@Sentinel4Nature_Hjerkinn
# ndvi avg
r.neighbors -c --overwrite --verbose input=hjerkinn_area2_ndvi_2014_260@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_ndvi_2014_260_avg@Sentinel4Nature_Hjerkinn method=average
# ndvi min
r.neighbors -c --overwrite --verbose input=hjerkinn_area2_ndvi_2014_260@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_ndvi_2014_260_min@Sentinel4Nature_Hjerkinn method=minimum
# ndvi max
r.neighbors -c --overwrite --verbose input=hjerkinn_area2_ndvi_2014_260@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_ndvi_2014_260_max@Sentinel4Nature_Hjerkinn method=maximum
# ndvi stddev
r.neighbors -c --overwrite --verbose input=hjerkinn_area2_ndvi_2014_260@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_ndvi_2014_260_stddev@Sentinel4Nature_Hjerkinn method=stddev

## PARAMSCALE
r.param.scale --overwrite --verbose input=dem_10m_fenoscandia@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_paramscale

## TOPIDX
r.topidx --overwrite --verbose input=dem_10m_fenoscandia@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_topidx

## WATERSHED
r.watershed --overwrite elevation=dem_10m_fenoscandia@Sentinel4Nature_Hjerkinn threshold=10 accumulation=hjerkinn_area2_watershed_accumulation tci=hjerkinn_area2_watershed_tci slope_steepness=hjerkinn_area2_watershed_slope_steepness

---------------------------------------------------------------------------------------------------------
## patch aerial images
g.region -p raster=LC8_198_017_2013_193_LGN00_sr_band1@Sentinel4Nature_Hjerkinn align=LC8_198_017_2013_193_LGN00_sr_band4@Sentinel4Nature_Hjerkinn
r.patch --overwrite --verbose input=x2_1_504_187_03.1@Sentinel4Nature_Hjerkinn,x2_1_504_187_03.2@Sentinel4Nature_Hjerkinn,x2_1_504_187_03.3@Sentinel4Nature_Hjerkinn,x2_1_504_187_04.1@Sentinel4Nature_Hjerkinn,x2_1_504_187_04.2@Sentinel4Nature_Hjerkinn,x2_1_504_187_04.3@Sentinel4Nature_Hjerkinn,x2_1_504_187_05.1@Sentinel4Nature_Hjerkinn,x2_1_504_187_05.2@Sentinel4Nature_Hjerkinn,x2_1_504_187_05.3@Sentinel4Nature_Hjerkinn,x2_1_504_187_13.1@Sentinel4Nature_Hjerkinn,x2_1_504_187_13.2@Sentinel4Nature_Hjerkinn,x2_1_504_187_13.3@Sentinel4Nature_Hjerkinn,x2_1_504_187_15.1@Sentinel4Nature_Hjerkinn,x2_1_504_187_15.2@Sentinel4Nature_Hjerkinn,x2_1_504_187_15.3@Sentinel4Nature_Hjerkinn,x2_1_504_187_14.1@Sentinel4Nature_Hjerkinn,x2_1_504_187_14.2@Sentinel4Nature_Hjerkinn,x2_1_504_187_14.3@Sentinel4Nature_Hjerkinn,x2_1_504_187_23.1@Sentinel4Nature_Hjerkinn,x2_1_504_187_23.2@Sentinel4Nature_Hjerkinn,x2_1_504_187_23.3@Sentinel4Nature_Hjerkinn,x2_1_504_187_24.1@Sentinel4Nature_Hjerkinn,x2_1_504_187_24.2@Sentinel4Nature_Hjerkinn,x2_1_504_187_24.3@Sentinel4Nature_Hjerkinn,x2_1_504_187_25.1@Sentinel4Nature_Hjerkinn,x2_1_504_187_25.2@Sentinel4Nature_Hjerkinn,x2_1_504_187_25.3@Sentinel4Naturer.neighbors -c input=dem_10m_fenoscandia@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_avg11 size=11_Hjerkinn,x2_1_504_187_33.1@Sentinel4Nature_Hjerkinn,x2_1_504_187_33.2@Sentinel4Nature_Hjerkinn,x2_1_504_187_33.3@Sentinel4Nature_Hjerkinn,x2_1_504_187_34.1@Sentinel4Nature_Hjerkinn,x2_1_504_187_34.2@Sentinel4Nature_Hjerkinn,x2_1_504_187_34.3@Sentinel4Nature_Hjerkinn,x2_1_504_187_35.1@Sentinel4Nature_Hjerkinn,x2_1_504_187_35.2@Sentinel4Nature_Hjerkinn,x2_1_504_187_35.3@Sentinel4Nature_Hjerkinn,x2_1_504_187_43.1@Sentinel4Nature_Hjerkinn,x2_1_504_187_43.2@Sentinel4Nature_Hjerkinn,x2_1_504_187_43.3@Sentinel4Nature_Hjerkinn,x2_1_504_187_44.1@Sentinel4Nature_Hjerkinn,x2_1_504_187_44.2@Sentinel4Nature_Hjerkinn,x2_1_504_187_44.3@Sentinel4Nature_Hjerkinn,x2_1_504_187_45.1@Sentinel4Nature_Hjerkinn,x2_1_504_187_45.2@Sentinel4Nature_Hjerkinn,x2_1_504_187_45.3@Sentinel4Nature_Hjerkinn,x2_1_504_187_53.1@Sentinel4Nature_Hjerkinn,x2_1_504_187_53.2@Sentinel4Nature_Hjerkinn,x2_1_504_187_53.3@Sentinel4Nature_Hjerkinn,x2_1_504_187_54.1@Sentinel4Nature_Hjerkinn,x2_1_504_187_54.2@Sentinel4Nature_Hjerkinn,x2_1_504_187_54.3@Sentinel4Nature_Hjerkinn,x2_1_504_187_55.1@Sentinel4Nature_Hjerkinn,x2_1_504_187_55.2@Sentinel4Nature_Hjerkinn,x2_1_504_187_55.3@Sentinel4Nature_Hjerkinn, output=hjerkinn_aerial_images




----------------------------------------------------------------------------------------------------------
### EXPORT RESULTS IN CSV

echo "Study_Site,X,Y,tass_cap_2013_193_brightness,tass_2013_193_cap_greeness,tass_cap_2013_193_wetness,tass_cap_2013_193_haze,tass_cap_2014_260_brightness,tass_2014_260_cap_greeness,tass_cap_2014_260_wetness,tass_cap_2014_260_haze,ndvi_2013_193,ndvi_2013_193_avg,ndvi_2013_193_min,ndvi_2013_193_max,ndvi_2013_193_stddev,ndvi_2014_258,ndvi_2014_258_avg,ndvi_2014_258_min,ndvi_2014_258_max,ndvi_2014_258_stddev,ndvi_2014_260,ndvi_2014_260_avg,ndvi_2014_260_min,ndvi_2014_260_max,ndvi_2014_260_stddev,DEM_topidx,DEM_watershed_accumulation,DEM_watershed_slope_steepness,DEM_watershed_tci,DEM_paramscale,DEM_neighbors_avg11,DEM_slope,DEM_aspect,DEM_profc,graduated_grid_forest,Landsat8_198_017_2014_260_band1,Landsat8_198_017_2014_260_band2,Landsat8_198_017_2014_260_band3,Landsat8_198_017_2014_260_band4,Landsat8_198_017_2014_260_band5,Landsat8_198_017_2014_260_band6,Landsat8_198_017_2014_260_band7,Landsat8_200_016_2014_258_band1,Landsat8_200_016_2014_258_band2,Landsat8_200_016_2014_258_band3,Landsat8_200_016_2014_258_band4,Landsat8_200_016_2014_258_band5,Landsat8_200_016_2014_258_band6,Landsat8_200_016_2014_258_band7,Landsat8_198_017_2013_193_band1,Landsat8_198_017_2013_193_band2,Landsat8_198_017_2013_193_band3,Landsat8_198_017_2013_193_band4,Landsat8_198_017_2013_193_band5,Landsat8_198_017_2013_193_band6,Landsat8_198_017_2013_193_band7,hjerkinn_aerial_images" > "/data/home/jacob/Avd15GIS/Prosjekter/Sentinel4Nature/Forest_cover/GRASS/hjerkinn_forest_cover_landsat.csv" 
#AREA1
g.region -p raster=hjerkinn_area1_graduated_grid_forest@Sentinel4Nature_Hjerkinn align=LC8_198_017_2013_193_LGN00_sr_band4@Sentinel4Nature_Hjerkinn
r.stats -1 -g -n input="hjerkinn_area1_tas_cap_veg_index_2013_193.1@Sentinel4Nature_Hjerkinn,hjerkinn_area1_tas_cap_veg_index_2013_193.2@Sentinel4Nature_Hjerkinn,hjerkinn_area1_tas_cap_veg_index_2013_193.3@Sentinel4Nature_Hjerkinn,hjerkinn_area1_tas_cap_veg_index_2013_193.4@Sentinel4Nature_Hjerkinn,hjerkinn_area1_tas_cap_veg_index_2014_260.1@Sentinel4Nature_Hjerkinn,hjerkinn_area1_tas_cap_veg_index_2014_260.2@Sentinel4Nature_Hjerkinn,hjerkinn_area1_tas_cap_veg_index_2014_260.3@Sentinel4Nature_Hjerkinn,hjerkinn_area1_tas_cap_veg_index_2014_260.4@Sentinel4Nature_Hjerkinn,hjerkinn_area1_ndvi_2013_193@Sentinel4Nature_Hjerkinn,hjerkinn_area1_ndvi_2013_193_avg@Sentinel4Nature_Hjerkinn,hjerkinn_area1_ndvi_2013_193_min@Sentinel4Nature_Hjerkinn,hjerkinn_area1_ndvi_2013_193_max@Sentinel4Nature_Hjerkinn,hjerkinn_area1_ndvi_2013_193_stddev@Sentinel4Nature_Hjerkinn,hjerkinn_area1_ndvi_2014_258@Sentinel4Nature_Hjerkinn,hjerkinn_area1_ndvi_2014_258_avg@Sentinel4Nature_Hjerkinn,hjerkinn_area1_ndvi_2014_258_min@Sentinel4Nature_Hjerkinn,hjerkinn_area1_ndvi_2014_258_max@Sentinel4Nature_Hjerkinn,hjerkinn_area1_ndvi_2014_258_stddev@Sentinel4Nature_Hjerkinn,hjerkinn_area1_ndvi_2014_260@Sentinel4Nature_Hjerkinn,hjerkinn_area1_ndvi_2014_260_avg@Sentinel4Nature_Hjerkinn,hjerkinn_area1_ndvi_2014_260_min@Sentinel4Nature_Hjerkinn,hjerkinn_area1_ndvi_2014_260_max@Sentinel4Nature_Hjerkinn,hjerkinn_area1_ndvi_2014_260_stddev@Sentinel4Nature_Hjerkinn,hjerkinn_area1_topidx@Sentinel4Nature_Hjerkinn,hjerkinn_area1_watershed_accumulation@Sentinel4Nature_Hjerkinn,hjerkinn_area1_watershed_slope_steepness@Sentinel4Nature_Hjerkinn,hjerkinn_area1_watershed_tci@Sentinel4Nature_Hjerkinn,hjerkinn_area1_paramscale@Sentinel4Nature_Hjerkinn,hjerkinn_area1_avg11@Sentinel4Nature_Hjerkinn,hjerkinn_area1_slope@Sentinel4Nature_Hjerkinn,hjerkinn_area1_aspect@Sentinel4Nature_Hjerkinn,hjerkinn_area1_profc@Sentinel4Nature_Hjerkinn,hjerkinn_area1_graduated_grid_forest@Sentinel4Nature_Hjerkinn,LC8_198_017_2014_260_LGN00_sr_band1@Sentinel4Nature_Hjerkinn,LC8_198_017_2014_260_LGN00_sr_band2@Sentinel4Nature_Hjerkinn,LC8_198_017_2014_260_LGN00_sr_band3@Sentinel4Nature_Hjerkinn,LC8_198_017_2014_260_LGN00_sr_band4@Sentinel4Nature_Hjerkinn,LC8_198_017_2014_260_LGN00_sr_band5@Sentinel4Nature_Hjerkinn,LC8_198_017_2014_260_LGN00_sr_band6@Sentinel4Nature_Hjerkinn,LC8_198_017_2014_260_LGN00_sr_band7@Sentinel4Nature_Hjerkinn,LC8_200_016_2014_258_LGN00_sr_band1@Sentinel4Nature_Hjerkinn,LC8_200_016_2014_258_LGN00_sr_band2@Sentinel4Nature_Hjerkinn,LC8_200_016_2014_258_LGN00_sr_band3@Sentinel4Nature_Hjerkinn,LC8_200_016_2014_258_LGN00_sr_band4@Sentinel4Nature_Hjerkinn,LC8_200_016_2014_258_LGN00_sr_band5@Sentinel4Nature_Hjerkinn,LC8_200_016_2014_258_LGN00_sr_band6@Sentinel4Nature_Hjerkinn,LC8_200_016_2014_258_LGN00_sr_band7@Sentinel4Nature_Hjerkinn,LC8_198_017_2014_260_LGN00_sr_band1@Sentinel4Nature_Hjerkinn,LC8_198_017_2014_260_LGN00_sr_band2@Sentinel4Nature_Hjerkinn,LC8_198_017_2014_260_LGN00_sr_band3@Sentinel4Nature_Hjerkinn,LC8_198_017_2014_260_LGN00_sr_band4@Sentinel4Nature_Hjerkinn,LC8_198_017_2014_260_LGN00_sr_band5@Sentinel4Nature_Hjerkinn,LC8_198_017_2014_260_LGN00_sr_band6@Sentinel4Nature_Hjerkinn,LC8_198_017_2014_260_LGN00_sr_band7@Sentinel4Nature_Hjerkinn,hjerkinn_aerial_images@Sentinel4Nature_Hjerkinn"  separator=comma null_value="NA" | awk -v FS=',' -v OFS=',' '{print "Hjerkinn; Area1", $0}' >> "/data/home/jacob/Avd15GIS/Prosjekter/Sentinel4Nature/Forest_cover/GRASS/hjerkinn_forest_cover_landsat.csv"
#AREA2
g.region -p raster=hjerkinn_area2_graduated_grid_forest@Sentinel4Nature_Hjerkinn align=LC8_198_017_2013_193_LGN00_sr_band4@Sentinel4Nature_Hjerkinn
r.stats -1 -g -N input="hjerkinn_area2_tas_cap_veg_index_2013_193.1@Sentinel4Nature_Hjerkinn,hjerkinn_area2_tas_cap_veg_index_2013_193.2@Sentinel4Nature_Hjerkinn,hjerkinn_area2_tas_cap_veg_index_2013_193.3@Sentinel4Nature_Hjerkinn,hjerkinn_area2_tas_cap_veg_index_2013_193.4@Sentinel4Nature_Hjerkinn,hjerkinn_area2_tas_cap_veg_index_2014_260.1@Sentinel4Nature_Hjerkinn,hjerkinn_area2_tas_cap_veg_index_2014_260.2@Sentinel4Nature_Hjerkinn,hjerkinn_area2_tas_cap_veg_index_2014_260.3@Sentinel4Nature_Hjerkinn,hjerkinn_area2_tas_cap_veg_index_2014_260.4@Sentinel4Nature_Hjerkinn,hjerkinn_area2_ndvi_2013_193@Sentinel4Nature_Hjerkinn,hjerkinn_area2_ndvi_2013_193_avg@Sentinel4Nature_Hjerkinn,hjerkinn_area2_ndvi_2013_193_min@Sentinel4Nature_Hjerkinn,hjerkinn_area2_ndvi_2013_193_max@Sentinel4Nature_Hjerkinn,hjerkinn_area2_ndvi_2013_193_stddev@Sentinel4Nature_Hjerkinn,hjerkinn_area2_ndvi_2014_258@Sentinel4Nature_Hjerkinn,hjerkinn_area2_ndvi_2014_258_avg@Sentinel4Nature_Hjerkinn,hjerkinn_area2_ndvi_2014_258_min@Sentinel4Nature_Hjerkinn,hjerkinn_area2_ndvi_2014_258_max@Sentinel4Nature_Hjerkinn,hjerkinn_area2_ndvi_2014_258_stddev@Sentinel4Nature_Hjerkinn,hjerkinn_area2_ndvi_2014_260@Sentinel4Nature_Hjerkinn,hjerkinn_area2_ndvi_2014_260_avg@Sentinel4Nature_Hjerkinn,hjerkinn_area2_ndvi_2014_260_min@Sentinel4Nature_Hjerkinn,hjerkinn_area2_ndvi_2014_260_max@Sentinel4Nature_Hjerkinn,hjerkinn_area2_ndvi_2014_260_stddev@Sentinel4Nature_Hjerkinn,hjerkinn_area2_topidx@Sentinel4Nature_Hjerkinn,hjerkinn_area2_watershed_accumulation@Sentinel4Nature_Hjerkinn,hjerkinn_area2_watershed_slope_steepness@Sentinel4Nature_Hjerkinn,hjerkinn_area2_watershed_tci@Sentinel4Nature_Hjerkinn,hjerkinn_area2_paramscale@Sentinel4Nature_Hjerkinn,hjerkinn_area2_avg11@Sentinel4Nature_Hjerkinn,hjerkinn_area2_slope@Sentinel4Nature_Hjerkinn,hjerkinn_area2_aspect@Sentinel4Nature_Hjerkinn,hjerkinn_area2_profc@Sentinel4Nature_Hjerkinn,hjerkinn_area2_graduated_grid_forest@Sentinel4Nature_Hjerkinn,LC8_198_017_2014_260_LGN00_sr_band1@Sentinel4Nature_Hjerkinn,LC8_198_017_2014_260_LGN00_sr_band2@Sentinel4Nature_Hjerkinn,LC8_198_017_2014_260_LGN00_sr_band3@Sentinel4Nature_Hjerkinn,LC8_198_017_2014_260_LGN00_sr_band4@Sentinel4Nature_Hjerkinn,LC8_198_017_2014_260_LGN00_sr_band5@Sentinel4Nature_Hjerkinn,LC8_198_017_2014_260_LGN00_sr_band6@Sentinel4Nature_Hjerkinn,LC8_198_017_2014_260_LGN00_sr_band7@Sentinel4Nature_Hjerkinn,LC8_200_016_2014_258_LGN00_sr_band1@Sentinel4Nature_Hjerkinn,LC8_200_016_2014_258_LGN00_sr_band2@Sentinel4Nature_Hjerkinn,LC8_200_016_2014_258_LGN00_sr_band3@Sentinel4Nature_Hjerkinn,LC8_200_016_2014_258_LGN00_sr_band4@Sentinel4Nature_Hjerkinn,LC8_200_016_2014_258_LGN00_sr_band5@Sentinel4Nature_Hjerkinn,LC8_200_016_2014_258_LGN00_sr_band6@Sentinel4Nature_Hjerkinn,LC8_200_016_2014_258_LGN00_sr_band7@Sentinel4Nature_Hjerkinn,LC8_198_017_2013_193_LGN00_sr_band1@Sentinel4Nature_Hjerkinn,LC8_198_017_2013_193_LGN00_sr_band2@Sentinel4Nature_Hjerkinn,LC8_198_017_2013_193_LGN00_sr_band3@Sentinel4Nature_Hjerkinn,LC8_198_017_2013_193_LGN00_sr_band4@Sentinel4Nature_Hjerkinn,LC8_198_017_2013_193_LGN00_sr_band5@Sentinel4Nature_Hjerkinn,LC8_198_017_2013_193_LGN00_sr_band6@Sentinel4Nature_Hjerkinn,LC8_198_017_2013_193_LGN00_sr_band7@Sentinel4Nature_Hjerkinn,hjerkinn_aerial_images@Sentinel4Nature_Hjerkinn"  separator=comma null_value="NA" | awk -v FS=',' -v OFS=',' '{print "Hjerkinn; Area2", $0}' >> "/data/home/jacob/Avd15GIS/Prosjekter/Sentinel4Nature/Forest_cover/GRASS/hjerkinn_forest_cover_landsat.csv"


## SEGMENTATION AREA 2

# slope aspect with 1m DEM
g.region -p raster=dem_hjerkinn_1m@Sentinel4Nature_Hjerkinn align=LC8_198_017_2013_193_LGN00_sr_band4@Sentinel4Nature_Hjerkinn
r.slope.aspect --overwrite --verbose elevation=dem_hjerkinn_1m@Sentinel4Nature_Hjerkinn slope=hjerkinn_area2_slope_1m aspect=hjerkinn_area2_aspect_1m pcurvature=hjerkinn_area2_profc_1m

# topidx with 1m DEM
r.topidx --overwrite --verbose input=dem_hjerkinn_1m@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_topidx_1m

# dem avg11 with 1m DEM
r.neighbors -c --overwrite --verbose input=dem_hjerkinn_1m@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_avg11_1m size=11

# r.rescale.eq
r.rescale.eq --overwrite --verbose input=hjerkinn_area2_avg11_1m@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_avg11_1m_rescaled to=1,65535
r.rescale.eq --overwrite --verbose input=hjerkinn_area2_slope_1m@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_slope_1m_rescaled to=1,65535
r.rescale.eq --overwrite --verbose input=hjerkinn_area2_aspect_1m@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_aspect_1m_rescaled to=1,65535
r.rescale.eq --overwrite --verbose input=hjerkinn_area2_topidx_1m@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_topidx_1m_rescaled to=1,65535
# create image group

# i.segment
i.segment --overwrite --verbose group=hjerkinn_area2_isegment@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_isegment_0_01 threshold=0.01
r.resamp.stats --overwrite --verbose input=hjerkinn_area2_isegment_0_01@Sentinel4Nature_Hjerkinn output=hjerkinn_area2_isegment_0_01@Sentinel4Nature_Hjerkinn quantile=0.01



