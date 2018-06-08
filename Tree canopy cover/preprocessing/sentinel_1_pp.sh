#!/bin/bash

: '
NAME:    Preprocessing of Sentinel-1 imagery

AUTHOR(S): Stefan Blumentrath < stefan.blumentrath AT nina.no>

PURPOSE:   Parallel preprocessing of Sentinel-1 imagery.
           Download scenes, import to GRASS and aggregate them over time.
           Can be run for cases "Oslo Hjerkinn Luroeykalven Dovre".
'

: '
To Dos:
'

gdal_bin=""
snap_bin="/opt/esa-snap/bin/"

base_dir="/data/R/Avd15GIS/Prosjekter/Sentinel4Nature/Forest_cover/"
lbase_dir="/data/R/GeoSpatialData/Orthoimagery/Fenoscandia_Sentinel_1"

geojson_dir="${base_dir}Cases_GeoJSON/"

location="/data/grass/ETRS_33N/"
mapset_prefix="p_Sentinel4Nature_S1_"

dem_in="/data/R/GeoSpatialData/Elevation/Fenoscandia_DEM_10m/dem_10m_fenoscandia.tif"
#"${location}g_Elevation_Fenoscandia/cellhd/dem_10m_nosefi_float" # Issue with NULL-file compression

timeframes="201507 201508 201607 201608 201707 201708"

types="Beta Gamma Sigma"
aggregations="quart_1 median quart_3 variance dry_parameter"
polarisations="VV VH VH_VV"

if [ ! $# -eq 1 ] ; then
    echo "Error you have to provide the name of one of the case study areas (Oslo Hjerkinn Luroeykalven Dovre) as commandline argument"
    exit 1
fi

# Read case from command line argument
c=$1

now=$(date)
echo "Start processing case ${c}, $now"

case_dir="${base_dir}Case_$c"
lcase_dir="${lbase_dir}/Processed/Case_$c"
mapset="${location}${mapset_prefix}$c"

for d in "$case_dir" "${lbase_dir}/Processed" "$lcase_dir" "${lbase_dir}/Original"
do
    if [ ! -d "$d" ] ; then
        mkdir "$d"
    fi
done

if [ ! -d "$mapset" ] ; then
    grass -text -c "$mapset" -e
fi

cd $lcase_dir

### Define analysis region
# Import GeoJSON if necessary
eval `grass -text "$mapset" --exec g.findfile element=vector file="${c}_extent"`
mapset="${location}${mapset_prefix}$c"

if [ ! "$file" ] ; then
    echo "Vector map ${c}_extent not present, importing"
    grass -text "$mapset" --exec v.import --o --q input=${geojson_dir}${c}_extent.geojson output=${c}_extent_gj epsg=4326
    grass -text "$mapset" --exec g.region vector=${c}_extent_gj align=dem_10m_nosefi@g_Elevation_Fenoscandia
    grass -text "$mapset" --exec v.in.region --o --q output=${c}_extent type=area
    grass -text "$mapset" --exec g.remove --q -f type=vector name=${c}_extent_gj
else
    echo "Vector map ${c}_extent already present, skipping import"
fi


if [ -f "${lcase_dir}/${c}_extent.geojson" ] ; then
    rm "${lcase_dir}/${c}_extent.geojson"
fi

${gdal_bin}ogr2ogr -f GeoJSON -t_srs EPSG:4326 ${lcase_dir}/${c}_extent.geojson ${mapset}/vector/${c}_extent/head 1

# Get extent of case study site
eval `grass -text "$mapset" --exec g.region -bgu`

pol="POLYGON ((${ll_w} ${ll_s}, ${ll_e} ${ll_s}, ${ll_e} ${ll_n}, ${ll_w} ${ll_n}, ${ll_w} ${ll_s}))"

# Reproject DEM for terrain correction
dem="${lcase_dir}/dem_10m_wgs84.tif"

# Check temporary disabled for reproduction
#if [ ! -f "$dem" ] ; then
    ${gdal_bin}gdalwarp -overwrite -multi -wo NUM_CORES=10 -t_srs EPSG:4326 -r bilinear -dstnodata 0 -te $ll_w $ll_s $ll_e $ll_n -co "COMPRESS=LZW" -co "TFW=YES" $dem_in $dem
#fi

### Download Sentinel-1 scenes with full coverage for requested timeframes

for timeframe in $timeframes
do

    # Get candidate scenes and save footprints
    candidates=$(sentinelsat --footprints -u username -p password --url https://scihub.copernicus.eu/apihub/ -g "${lcase_dir}/${c}_extent.geojson" --sentinel 1  --producttype GRD  --name "*IW*${timeframe}*" 2>&1 | tail -n +2 | head -n -2 | cut -f2 -d' ')
    echo $candidates

    # make sure to have at least one scene
    # while ! $candidates
    # do
    # done

    for k in $candidates
    do

        # Check case study site is fully within footprint 
        if [ -f tmp.geojson ] ; then
            rm tmp.geojson
        fi

        # Clip candidates list by Case study site
        ${gdal_bin}ogr2ogr -q -f GeoJSON -clipsrc ${lcase_dir}/${c}_extent.geojson tmp.geojson search_footprints.geojson

        # Get full area of case study site BBox
        full_area=$(ogrinfo -ro ${lcase_dir}/${c}_extent.geojson -sql "SELECT SUM(OGR_GEOM_AREA) FROM \"1\"" | grep SUM_OGR_GEOM_AREA | grep '=' | cut -f2 -d'=' | tr -d ' ')

        # Get list of files that contain full case study site BBox
        files=$(ogrinfo -ro tmp.geojson -dialect SQLite -sql "SELECT filename FROM search_footprints WHERE ST_Area(GEOMETRY) >= ${full_area}" | cut -s -f2 -d'=' | tr -d ' ')

        # Remove temporary GeoJSON
        rm tmp.geojson

    done

    for f in $files
    do

        file=$(echo $f | sed 's/.SAFE//')
        zip=$(echo $f | sed 's/.SAFE/.zip/')
        #unzip -o "${lbase_dir}/Original/$zip" -d "${lbase_dir}/Original/"

        # Check if file was downloaded earlier, if not download
        if [ ! -f "${lbase_dir}/Original/${zip}" ] ; then
            # Download file
            sentinelsat -d -u username -p password --url https://scihub.copernicus.eu/apihub/ -g "${geojson_dir}${c}_extent.geojson" --sentinel 1  --producttype GRD  --name "$file" --path "${lbase_dir}/Original/"
        fi
        
        scene_meta=$(${gdal_bin}gdalinfo "/vsizip/${lbase_dir}/Original/${file}.zip/${f}/manifest.safe")
        xy=$(echo "$scene_meta" | grep "Size is" | tr -d ',' | cut -f3- -d' ' | tr ' ' ',')
        a_start=$(echo "$scene_meta" | grep "ACQUISITION_START_TIME" | cut -f2 -d'=' | cut -f1 -d'.' | tr '-' ' ' | tr 'T' ' ' | tr ':' ' ' | awk '{print strftime("%e %b %Y %H:%M:%S", mktime($0))}' | sed 's/^ //')
        a_end=$(echo "$scene_meta" | grep "ACQUISITION_STOP_TIME" | cut -f2 -d'=' | cut -f1 -d'.' | tr '-' ' ' | tr 'T' ' ' | tr ':' ' ' | awk '{print strftime("%e %b %Y %H:%M:%S", mktime($0))}' | sed 's/^ //')

        input="${lbase_dir}/Original/$zip"
        output="${lcase_dir}/${file}_pp.dim"

        # Pre-Process S1 data
        LD_LIBRARY_PATH=. ${snap_bin}/gpt "${lbase_dir}/Scripts/graph_subs.xml" -Pinput="$input" -Poutput="$output" -Pdem="$dem" -Pext="0,0,${xy}" -Ppol="$pol"
        #LD_LIBRARY_PATH=. /opt/snap5/bin/gpt "${lbase_dir}/Processed/graph.xml" -Pinput="$input" -Poutput="$output" -Pdem="$dem"

        # List bands
        bands=$(ls "${lcase_dir}/${file}_pp.data/" | grep ".img")

        # Import results to GRASS mapset
        for b in $bands
        do
            band=$(echo $b | sed 's/.img//')
            # Link gpt output
            grass -text "$mapset" --exec r.external --o --q -o input="${lcase_dir}/${file}_pp.data/$b" output=${file}.${band}_dn
            # Set computational region
            grass -text "$mapset" --exec g.region raster=${file}.${band}_dn align=dem_10m_nosefi_float@g_Elevation_Fenoscandia
            if [ $(echo $b | grep "VH\|VV" | wc -l) -eq 1 ] ; then
                # Resacle imagery Digital Numbers to db
                grass -text "$mapset" --exec r.mapcalc --o expression="${file}.${band}=10*log(${file}.${band}_dn, 10)"
                # Add timestamp
                grass -text "$mapset" --exec r.timestamp --o --q map=${file}.$band date="${a_start}/${a_end}"
            else
                # Make linked band permanent
                grass -text "$mapset" --exec r.mapcalc --o expression="${file}.${band}=${file}.${band}_dn"
                # Add timestamp
                grass -text "$mapset" --exec r.timestamp --o --q map=${file}.$band date="${a_start}/${a_end}"
            fi
            # Remove linked map
            grass -text "$mapset" --exec g.remove --q -f name=${file}.${band}_dn type=raster
        # End loop over bands
        done

        for t in $types
        do
            # Set computational region
            grass -text "$mapset" --exec g.region raster=${file}.${band} align=dem_10m_nosefi_float@g_Elevation_Fenoscandia
            # Compute difference bands
            grass -text "$mapset" --exec r.mapcalc --o expression="${file}.${t}0_VH_VV=${file}.${t}0_VH-${file}.${t}0_VV"
            # Add timestamp
            grass -text "$mapset" --exec r.timestamp --o --q map=${file}.${t}0_VH_VV date="${a_start}/${a_end}"
        done

    done

# End loop over timeframes
done

# Aggregate time series by year
for y in 2015 2016 2017
do 

    for t in $types
    do

        for p in $polarisations
        do

            # List maps
            if [ $c == "Oslo" ] ; then
                # Exclude according to manual check
                maps=$(grass -text "$mapset" --exec g.list type=raster pattern="S1*_IW_GRDH_1SDV_${y}*_*.${t}0_${p}" exclude="*T054*" separator=',')
            else
                maps=$(grass -text "$mapset" --exec g.list type=raster pattern="S1*_IW_GRDH_1SDV_${y}*_*.${t}0_${p}" separator=',')
            fi

            if [ "$maps" ] ; then
                grass -text "$mapset" --exec r.series --o input="$maps" method="quart1,median,quart3,variance" output="S1_IW_GRDH_${y}.${t}0_${p}_quart_1,S1_IW_GRDH_${y}.${t}0_${p}_median,S1_IW_GRDH_${y}.${t}0_${p}_quart_3,S1_IW_GRDH_${y}.${t}0_${p}_variance"
                ### The best results for both polarizations are achieved by the so-called dry parameter computed as the average of all values below first quartile of each pixel.
                sum_val="("
                sum_n="("
                
                for m in  $(echo $maps | tr ',' ' ')
                do
                    sum_val="${sum_val}if(isnull(${m})||${m}>S1_IW_GRDH_${y}.${t}0_${p}_quart_1,0,${m})+"
                    sum_n="${sum_n}if(isnull(${m})||${m}>S1_IW_GRDH_${y}.${t}0_${p}_quart_1,0,1)+"
                done
                sum_val=$(echo "$sum_val" | sed 's/+$/)/')
                sum_n=$(echo "$sum_n" | sed 's/+$/)/')
                
                # Generate expression
                grass -text "$mapset" --exec r.mapcalc --o expression="S1_IW_GRDH_${y}.${t}0_${p}_dry_parameter=${sum_val}/${sum_n}"
                
                for aggr in $aggregations
                do
                    grass -text "$mapset" --exec r.texture --o --q input="S1_IW_GRDH_${y}.${t}0_${p}_${aggr}" output="S1_IW_GRDH_${y}.${t}0_${p}_${aggr}" method=contrast
                done

            fi
        # End band loop
        done

    #End type loop
    done

# End year loop
done

for t in $types
do

    for p in $polarisations
    do

        # List maps
        if [ $c == "Oslo" ] ; then
            # Exclude according to manual check
            maps=$(grass -text "$mapset" --exec g.list type=raster pattern="S1*_IW_GRDH_*_*.${t}0_${p}" exclude="*T054*" separator=',')
        else
            maps=$(grass -text "$mapset" --exec g.list type=raster pattern="S1*_IW_GRDH_*_*.${t}0_${p}" separator=',')
        fi

        if [ "$maps" ] ; then
            grass -text "$mapset" --exec r.series --o input="$maps" method="quart1,median,quart3,variance" output="S1_IW_GRDH_total.${t}0_${p}_quart_1,S1_IW_GRDH_total.${t}0_${p}_median,S1_IW_GRDH_total.${t}0_${p}_quart_3,S1_IW_GRDH_total.${t}0_${p}_variance"
            ### The best results for both polarizations are achieved by the so-called dry parameter computed as the average of all values below first quartile of each pixel.
            sum_val="("
            sum_n="("
            
            for m in  $(echo $maps | tr ',' ' ')
            do
                sum_val="${sum_val}if(isnull(${m})||${m}>S1_IW_GRDH_total.${t}0_${p}_quart_1,0,${m})+"
                sum_n="${sum_n}if(isnull(${m})||${m}>S1_IW_GRDH_total.${t}0_${p}_quart_1,0,1)+"
            done
            sum_val=$(echo "$sum_val" | sed 's/+$/)/')
            sum_n=$(echo "$sum_n" | sed 's/+$/)/')
            
            # Generate expression
            grass -text "$mapset" --exec r.mapcalc --o expression="S1_IW_GRDH_total.${t}0_${p}_dry_parameter=${sum_val}/${sum_n}"
            
            for aggr in $aggregations
            do
                grass -text "$mapset" --exec r.texture --o --q input="S1_IW_GRDH_total.${t}0_${p}_${aggr}" output="S1_IW_GRDH_total.${t}0_${p}_${aggr}" method=contrast
            done
        fi

    done

done

now=$(date)
echo "End processing case ${c}, $now"

