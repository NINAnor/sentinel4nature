#!/bin/bash

: '
NAME:    Preprocessing of Sentinel-2 imagery

AUTHOR(S): Zofie Cimburova < zofie.cimburova AT nina.no>
           Stefan Blumentrath < stefan.blumentrath AT nina.no>

PURPOSE:   Preprocessing of Sentinel-2 imagery.
           Download scenes, import to GRASS, perform atmospheric and topographic corrections, 
           compute artificial bands, aggregate scenes over time.
'

: '
To Dos:     AOD shall be more precisely estimated
                e.g. using interpolation / averiging of AERONET measurements
                https://www.rtwilson.com/academic/WilsonMiltonNield_2015_VisAOT.pdf
                aot=$(curl -s -k "https://aeronet.gsfc.nasa.gov/cgi-bin/print_web_data_v3?site=Birkenes&year=2014&month=6&day=1&year2=2017&month2=9&day2=30&AOD15=1&AVG=20&if_no_html=1")
                aot_dates=$(curl -s -k "https://aeronet.gsfc.nasa.gov/cgi-bin/print_web_data_v3?site=Palgrunden&year=2017&month=6&day=1&year2=2017&month2=9&day2=30&AOD15=1&AVG=10&if_no_html=1" | grep Palgrunden, |cut -f2 -d",")
            	aot_values=$(curl -s -k "https://aeronet.gsfc.nasa.gov/cgi-bin/print_web_data_v3?site=Palgrunden&year=2017&month=6&day=1&year2=2017&month2=9&day2=30&AOD15=1&AVG=10&if_no_html=1" | grep Palgrunden, |cut -f15 -d",")
'


# ########################## #
# CREATE DIRECTORY STRUCTURE #
# ########################## #

base_dir="/data/R/Avd15GIS/Prosjekter/Sentinel4Nature/Forest_cover/" 
lbase_dir="/data/R/GeoSpatialData/Orthoimagery/Fenoscandia_Sentinel_2/"

geojson_dir="${base_dir}Cases_GeoJSON/"

location="/data/grass/ETRS_33N/"
mapset_prefix="p_Sentinel4Nature_S2_"


# create directories
cases="Oslo Hjerkinn Luroeykalven Dovre1 Dovre2"

for c in $cases
do  
    # Create directories
    echo ""
    echo "#############################################################################"
    echo "Case ${c}: Creating directory structure..."
    echo ""
    
    case_dir="${base_dir}Case_$c"
    lcase_dir="${lbase_dir}/Processed/Case_$c"
    mapset="${location}${mapset_prefix}$c"

    for d in "$case_dir" "${lbase_dir}/Processed" "$lcase_dir" "${lbase_dir}/Original"
    do
        if [ ! -d "$d" ] ; then
            mkdir "$d"
        fi
    done

    # Create mapsets
    if [ ! -d "$mapset" ] ; then
        grass74 -text -c "$mapset" -e
    fi

    cd $lcase_dir

    echo ""
    echo "... Case ${c}: Directory structure created."
    echo "#############################################################################"
    echo ""

    #################################### #
    # DEFINE SPATIAL AND TEMPORAL EXTENT #
    # ################################## #

    echo ""
    echo "#############################################################################"
    echo "Case ${c}: Defining spatial extent..."
    echo ""
    
    ### Define spatial extent (analysis region)

    #Align computational region with terrain model
    #Replace extent polygon with aligned extent
    grass74 -text "$mapset" --exec v.import --o --q input=${geojson_dir}${c}_extent.geojson output=${c}_extent_gj epsg=4326 # Import extent in GeoJSON (in WGS84, 4326)
    grass74 -text "$mapset" --exec g.region --q vector=${c}_extent_gj align=dem_10m_nosefi@g_Elevation_Fenoscandia # Set computational region to extent and align to raster resolution
    grass74 -text "$mapset" --exec v.in.region --o --q output=${c}_extent type=area # Create polygon of new extent by filling alligned comp. region
    grass74 -text "$mapset" --exec g.remove --q -f type=vector name=${c}_extent_gj # Remove old non-aligned extent

    # Remove old (non-aligned) extent
    if [ -f "${lcase_dir}/${c}_extent.geojson" ] ; then
        rm "${lcase_dir}/${c}_extent.geojson"
    fi

    # Create new (aligned) extent (in WGS84, 4326)
    ogr2ogr -f GeoJSON -t_srs EPSG:4326 ${lcase_dir}/${c}_extent.geojson ${mapset}/vector/${c}_extent/head 1

    # Get extent of case study site
    eval `grass74 -text "$mapset" --exec g.region -bgu`
    pol="POLYGON ((${ll_w} ${ll_s}, ${ll_e} ${ll_s}, ${ll_e} ${ll_n}, ${ll_w} ${ll_n}, ${ll_w} ${ll_s}))"

    # Reproject DEM for terrain correction
    eval `grass74 -text "$mapset" --exec g.region -gu`

    # Fill nulls in DEM
    dem_filled="dem_10m_25833_0filled"
    grass74 -text "$mapset" --exec r.mapcalc --q --o expression="$dem_filled=if(isnull(dem_10m_nosefi@g_Elevation_Fenoscandia),0,dem_10m_nosefi@g_Elevation_Fenoscandia)"

    echo ""
    echo "... Case ${c}: Spatial extent defined."
    echo "#############################################################################"
    echo ""

    ### Temporal extent
    timeframes="2014 2015 2016 2017"
    
    for timeframe in $timeframes
        do
        echo ""
        echo "#############################################################################"
        echo "Case ${c}, timeframe ${timeframe}: Searching for scenes and downloading..."
        echo ""
        
        # ################################## #
        # DOWNLOAD SCENES WITH FULL COVERAGE #
        # ################################## #

        # Get candidate scenes and save footprints
        candidates=$(sentinelsat --footprints -u username -p password --url https://scihub.copernicus.eu/apihub/ -s "${timeframe}0601" -e "${timeframe}0930" -g "${lcase_dir}/${c}_extent.geojson" --sentinel 2  --producttype S2MSI1C  -c 10 2>&1 | tail -n +2 | head -n -2 | cut -f2 -d' ')
            
        # if no candidates for this time period exist, continue with the next time period or the next case
        if [ -z "$candidates" ] ; then
            echo "      No candidates found for case $c , time period $timeframe"
            files=""
            continue
        fi
            
        for k in $candidates
        do

            # Check case study site is fully within footprint 
            if [ -f tmp.geojson ] ; then
                rm tmp.geojson
            fi

            # Clip candidates list by Case study site
            ogr2ogr -q -f GeoJSON -clipsrc ${lcase_dir}/${c}_extent.geojson tmp.geojson search_footprints.geojson # seacrh footprint is output of sentinelsat

            # Get full area of case study site BBox
            full_area=$(ogrinfo -ro ${lcase_dir}/${c}_extent.geojson OGRGeoJSON -sql "SELECT SUM(OGR_GEOM_AREA) FROM \"1\"" | grep SUM_OGR_GEOM_AREA | grep '=' | cut -f2 -d'=' | tr -d ' ')

            # Get list of files that contain full case study site BBox
            files=$(ogrinfo -ro tmp.geojson OGRGeoJSON -dialect SQLite -sql "SELECT filename FROM \"search_footprints\" WHERE ST_Area(GEOMETRY) >= ${full_area}" | cut -s -f2 -d'=' | tr -d ' ')

            # Remove temporary GeoJSON
            rm tmp.geojson

        done # for candidate in candidates

        # if no fully covering scenes for this time period exist, continue with the next time period or the next case
        if [ -z "$files" ] ; then
            echo "No fully covering candidates found for case $c , time period $timeframe"
            continue
        fi

        for f in $files
        do
         
            file=$(echo $f | sed 's/.SAFE//')
            zip=$(echo $f | sed 's/.SAFE/.zip/')
            
            # Check if file was downloaded earlier, if not, download
            if [ ! -f "${lbase_dir}/Original/${zip}" ] ; then
                sentinelsat -d -u username -p password --url https://scihub.copernicus.eu/apihub/ -g "${geojson_dir}${c}_extent.geojson" --sentinel 2  --producttype S2MSI1C  -c 10 --name "$file" --path "${lbase_dir}/Original/"
            fi

            echo ""
            echo "... Case ${c}, timeframe ${timeframe}: Downloaded scene ${f}."
            echo "#############################################################################"
            echo ""

            # distinguish between S2A and S2B
            sentinel=$(echo $f | cut -f1 -d"_")

            
            # ############################# #
            # REPROJECT AND IMPORT TO GRASS #
            # ############################# #
            
            echo ""
            echo "#############################################################################"
            echo "Case ${c}, timeframe ${timeframe}, scene ${f}: Importing to grass..."
            echo ""
            
            # Get metadata file and read metadata
            metadata_file=$(unzip -Z1 ${lbase_dir}/Original/$zip | cut -f2 -d"/" | grep ".xml" | grep -v "INSPIRE") 
            scene_meta=$(gdalinfo "/vsizip/${lbase_dir}/Original/$zip/${file}.SAFE/${metadata_file}")


            # Go through subdatasets (10m, 20m, 60m, PREVIEW), reproject them and import to GRASS
            # Provided in both EPSG 32632 and 32633

            # subdatasets=$(echo "$scene_meta" | grep SUBDATASET | grep NAME | cut -f2 -d'=')

            if [ $(grass74 -text "$mapset" --exec g.list type=raster pattern=${file}* mapset=$(echo $mapset | rev | cut -f1 -d'/' | rev)| wc -l) -eq 0 ] ; then          

                for subdataset in $subdatasets
                do

                    # resolution of subdataset
                    resolution=$(echo $subdataset | rev | cut -f2 -d":" | rev | cut -f1 -d"m")


                    # projection of subdataset
                    projection=$(echo $subdataset | rev | cut -f1 -d":" | rev)

                    # do not reproject and import PREVIEW subdataset
                    if [ $resolution = "PREVIEW" ] ; then
                        continue
                    fi

                    if [ $resolution = "TCI" ] ; then # S2B
                        continue
                    fi

                    # do not reproject and import datasets in EPSG 32633
                    if [ $projection != "EPSG_32632" ] ; then
                        continue
                    fi

                    # reproject all files to 25833, and at the same time clip to computational region
                    virtual_raster="${lbase_dir}Converted/${file}_${resolution}.vrt"

                    eval `grass74 -text "$mapset" --exec g.region -pgu`
                    gdalwarp -s_srs <(gdalsrsinfo -o wkt $subdataset) -t_srs EPSG:25833 -te $w $s $e $n -tr $resolution $resolution -of VRT $subdataset $virtual_raster

                    # import to grass
                    grass74 -text "$mapset" --exec r.in.gdal --o --q -k input=$virtual_raster output="${file}"
                    

                    # rename layers (imported as .1, .2, .3, ..., rename to B02, B03, B04, ...)
                    if [ $resolution = "10" ] ; then
                        grass74 -text "$mapset" --exec g.rename --q  raster="${file}.1,${file}.B02"
                        grass74 -text "$mapset" --exec g.rename --q  raster="${file}.2,${file}.B03"
                        grass74 -text "$mapset" --exec g.rename --q  raster="${file}.3,${file}.B04"
                        grass74 -text "$mapset" --exec g.rename --q  raster="${file}.4,${file}.B08"
                    fi

                    if [ $resolution = "20" ] ; then
                        grass74 -text "$mapset" --exec g.rename --q  raster="${file}.1,${file}.B05"
                        grass74 -text "$mapset" --exec g.rename --q  raster="${file}.2,${file}.B06"
                        grass74 -text "$mapset" --exec g.rename --q  raster="${file}.3,${file}.B07"
                        grass74 -text "$mapset" --exec g.rename --q  raster="${file}.4,${file}.B08A"
                        grass74 -text "$mapset" --exec g.rename --q  raster="${file}.5,${file}.B11"
                        grass74 -text "$mapset" --exec g.rename --q  raster="${file}.6,${file}.B12"
                    fi

                    if [ $resolution = "60" ] ; then
                        grass74 -text "$mapset" --exec g.rename --q  raster="${file}.1,${file}.B01"
                        grass74 -text "$mapset" --exec g.rename --q  raster="${file}.2,${file}.B09"
                        grass74 -text "$mapset" --exec g.rename --q  raster="${file}.3,${file}.B10"
                    fi

                    echo ""
                    echo "... Case ${c}, timeframe ${timeframe}, file ${f} : Imported resolution ${resolution}."
                    echo "#############################################################################"
                    echo ""


                    # remove virtual raster
                    rm $virtual_raster

                done # for subdataset in $subdatasets

            else
                echo "File ${file} already imported." 
            fi

            # ############################################################ #
            # PERFORM ATMOSPHERIC AND TOPOGRAPHIC CORRECTIONS AND RESAMPLE #
            # ############################################################ #

            echo ""
            echo "#############################################################################"
            echo "Case ${c}, timeframe ${timeframe}, scene ${f}: performing atmospheric and topographic corrections..."
            echo ""
            
            ### Pre-compute for for corrections
            
            # # 1. Geometrical conditions: 25 = Sentinel2A
            case "$sentinel" in
               "S2A") gec_6s="25" # Sentinel2A
               ;;
               "S2B") gec_6s="26" # Sentinel2B
               ;;
            esac
                 
            # 2. Month, day, decimal_time, longitude of image center in WGS84, latitude of image center in WGS84
            date_6s=$(echo "$scene_meta"| grep "DATATAKE_1_DATATAKE_SENSING_START" | cut -f2 -d"=" | cut -f1 -d"T")
            hour_6s=$(echo "$scene_meta"| grep "DATATAKE_1_DATATAKE_SENSING_START" | cut -f2 -d"=" | cut -f2 -d"T" | cut -f1 -d":")
            minute_6s=$(echo "$scene_meta"| grep "DATATAKE_1_DATATAKE_SENSING_START" | cut -f2 -d"=" | cut -f2 -d"T" | cut -f2 -d":")
            second_6s=$(echo "$scene_meta"| grep "DATATAKE_1_DATATAKE_SENSING_START" | cut -f2 -d"=" | cut -f2 -d"T" | cut -f3 -d":" | cut -f1 -d".")

            mon_6s=$(echo $date_6s | cut -f2 -d"-" )          
            day_6s=$(echo $date_6s | cut -f3 -d"-" )
            tim_6s=$(echo "scale=4; $hour_6s + $minute_6s / 60 + $second_6s / 3600" | bc)

            eval $(grass74 -text "$mapset" --exec g.region -bgu)

            lon_6s=$ll_clon 
            lat_6s=$ll_clat
            
            # 3. Atmospheric model: 4 = subarctic summer  (same for all scenes)
            atm_6s=4

            # 4. Aerosol model
            case "$c" in
               "Oslo") aer_6s=3 # urban aerosol model 
               ;;
               "Hjerkinn") aer_6s=1 # continenal model
               ;;
               "Luroeykalven") aer_6s=2 # maritime model
               ;;
               "Dovre1") aer_6s=1 # continenal model
               ;;
               "Dovre2") aer_6s=1 # continenal model
               ;;
            esac

            # 5. Aerosol optical depth at 550nm
<<<<<<< HEAD
=======
            # TODO - AOD shall be more precisely estimated
            #        e.g. using interpolation / averiging of AERONET measurements
            #		 https://www.rtwilson.com/academic/WilsonMiltonNield_2015_VisAOT.pdf
            #		 aot=$(curl -s -k "https://aeronet.gsfc.nasa.gov/cgi-bin/print_web_data_v3?site=Birkenes&year=2014&month=6&day=1&year2=2017&month2=9&day2=30&AOD15=1&AVG=20&if_no_html=1")
            #		 aot_dates=$(curl -s -k "https://aeronet.gsfc.nasa.gov/cgi-bin/print_web_data_v3?site=Palgrunden&year=2017&month=6&day=1&year2=2017&month2=9&day2=30&AOD15=1&AVG=10&if_no_html=1" | grep Palgrunden, |cut -f2 -d",")
            #		 aot_values=$(curl -s -k "https://aeronet.gsfc.nasa.gov/cgi-bin/print_web_data_v3?site=Palgrunden&year=2017&month=6&day=1&year2=2017&month2=9&day2=30&AOD15=1&AVG=10&if_no_html=1" | grep Palgrunden, |cut -f15 -d",") 

>>>>>>> 3cad8916bf2340cf38653a2e004d4431a3b7df60
            aod_6s=0.1 # estimated AOD, constant

            # 6. Mean target elevation above sea level in [-km]
            eval $(grass74 -text "$mapset" --exec r.univar -g $dem_filled)  
            elv_6s=$(echo "scale=4; -1 * ($mean / 1000 )" | bc)

            # 7. Sensor height in [-km]: same for all scenes
            sen_6s=-1000 # sensor height, constant
            
            # sun position
            solarelev_map="${file}.solarelev"
            azimuth_map="${file}.azimuth"
            grass74 -text "$mapset" --exec r.sunhours --q elevation="${solarelev_map}" azimuth="${azimuth_map}" year="${timeframe}" month="${mon_6s}" day="${day_6s}" hour="${hour_6s}" minute="${minute_6s}" second="${second_6s}"
            
            eval $(grass74 -text "$mapset" --exec r.univar --q -g map=$solarelev_map)
            zenith_avg=$(echo "scale=4; 90 - $mean" | bc)
            
            eval $(grass74 -text "$mapset" --exec r.univar --q -g map=$azimuth_map)
            azimuth_avg=$mean           
            
            grass74 -text "$mapset" --exec g.remove --q -f type=raster name="${solarelev_map}"
            grass74 -text "$mapset" --exec g.remove --q -f type=raster name="${azimuth_map}"
            
            # create illumination model
            illumination_map="${file}.illumination"
            grass74 -text "$mapset" --exec i.topo.corr --q --o -i base="$dem_filled" zenith=$zenith_avg azimuth=$azimuth_avg output="${illumination_map}"
            
            
            ### make atmospheric and topographic correction for each band separately
            bands="B01 B02 B03 B04 B05 B06 B07 B08 B08A B09 B10 B11 B12"
            for band in $bands
            do
                echo ""
                echo "#############################################################################"
                echo "  Case ${c}, timeframe ${timeframe}, scene ${f}: performing atmospheric and topographic corrections, band ${band}..."
                echo ""
                
                # delete Band 10 - cloud cover - not important
                if [ $band = "B10" ] ; then
                    grass74 -text "$mapset" --exec g.remove --q -f type=raster name="${file}.B10"
                    continue
                fi

                # create 6s file according to band and location and time              

                # 8. Sensor band 

                if [ $sentinel = "S2A" ] ; then
                case "$band" in
                   "B01") ban_6s=166 
                   ;;
                   "B02") ban_6s=167 
                   ;;
                   "B03") ban_6s=168 
                   ;;
                   "B04") ban_6s=169 
                   ;;
                   "B05") ban_6s=170 
                   ;;
                   "B06") ban_6s=171 
                   ;;
                   "B07") ban_6s=172 
                   ;;
                   "B08") ban_6s=173 
                   ;;
                   "B08A") ban_6s=174 
                   ;;
                   "B09") ban_6s=175 
                   ;;
                   "B11") ban_6s=177 
                   ;;
                   "B12") ban_6s=178
                   ;;
                esac
                else
                case "$band" in
                   "B01") ban_6s=179 
                   ;;
                   "B02") ban_6s=180 
                   ;;
                   "B03") ban_6s=181 
                   ;;
                   "B04") ban_6s=182 
                   ;;
                   "B05") ban_6s=183 
                   ;;
                   "B06") ban_6s=184 
                   ;;
                   "B07") ban_6s=185 
                   ;;
                   "B08") ban_6s=186 
                   ;;
                   "B08A") ban_6s=187 
                   ;;
                   "B09") ban_6s=188 
                   ;;
                   "B11") ban_6s=190 
                   ;;
                   "B12") ban_6s=191
                   ;;
                esac
                fi


                # export to text file
                sixs_file="$case_dir/6s_${file}_${band}.txt"
                echo -e "$gec_6s \n$mon_6s $day_6s $tim_6s $lon_6s $lat_6s \n$atm_6s \n$aer_6s \n0 \n$aod_6s \n$elv_6s \n$sen_6s \n$ban_6s" >$sixs_file

                # # perform atmospheric corrections
                band_atcorr="${file}.$band.atcorr"
                grass74 -text "$mapset" --exec i.atcorr --q input="${file}.${band}" range=0,10000 elevation="$dem_filled" parameters="$sixs_file" output="$band_atcorr" rescale=0,1 --overwrite
                grass74 -text "$mapset" --exec r.mapcalc --q --o expression="${band_atcorr} = double(${band_atcorr})"
                
                
                ### Topographic corrections                
                # apply illumination model               
                band_topocorr="${file}.${band}.topocorr"
                grass74 -text "$mapset" --exec i.topo.corr --q --o base="${illumination_map}" input="${band_atcorr}" output="topocorr" zenith=$zenith_avg method=minnaert
                grass74 -text "$mapset" --exec r.mapcalc --q --o expression="${band_topocorr} = if(topocorr.${band_atcorr}>1,1,topocorr.${band_atcorr})"
                
                grass74 -text "$mapset" --exec g.remove --q -f type=raster name="topocorr.${band_atcorr}"

                ### Resample 20m and 60m bands
                eval $(grass74 -text "$mapset" --exec r.info map=${file}.${band} -g)
                if [ $nsres != "10" ] ; then
                    # rename 20m or 60m map to ".20m" or ".60m"
                    grass74 -text "$mapset" --exec g.rename --o --q raster="${band_topocorr},${band_topocorr}.${nsres}"
                    
                    # resample
                    grass74 -text "$mapset" --exec r.resamp.filter --o --q input="${band_topocorr}.${nsres}" output="${band_topocorr}" filter="box,gauss" radius="${nsres},${nsres}"
                    
                    # remove 20m and 60m file
                    grass74 -text "$mapset" --exec g.remove --q -f type=raster name="${band_topocorr}.${nsres}"
                fi
                
            done # for band in bands
            
            grass74 -text "$mapset" --exec g.remove --q -f type=raster name="${illumination_map}"
            
                            
            echo ""
            echo "... Case ${c}, timeframe ${timeframe}, file ${f} : Atmospheric corrections done."
            echo "#############################################################################"
            echo ""          
            
            
            echo ""
            echo "#############################################################################"
            echo "Case ${c}, timeframe ${timeframe}, scene ${f}: computing NDVI, MNDWI..."
            echo ""
            
            
            # ############################################### #
            # COMPUTE NDVI AND MNDWI (from uncorrected bands) #
            # ############################################### #
            
            NDVI="$file.NDVI"
            grass74 -text "$mapset" --exec r.mapcalc --q --o expression="${NDVI} = double(${file}.B08.topocorr - ${file}.B04.topocorr)/double(${file}.B08.topocorr + ${file}.B04.topocorr)"
            
            MNDWI="$file.MNDWI"
            grass74 -text "$mapset" --exec r.mapcalc --q --o expression="${MNDWI} = double(${file}.B03 - ${file}.B11)/double(${file}.B03 + ${file}.B11)"
            
            echo ""
            echo "... Case ${c}, timeframe ${timeframe}, file ${f} : NDVI, MNDWI computed."
            echo "#############################################################################"
            echo ""
            

            echo "##############################################################"
            echo "End processing file ${f}."
        done # for f in files
    

        echo "##############################################################"
        echo "End processing timeframe ${timeframe}."
        
        
    done #for timeframe in timeframes

    # #################### #
    # COMPUTE MEDIAN BANDS #
    # #################### #
    bands="B01 B02 B03 B04 B05 B06 B07 B08 B08A B09 B11 B12 NDVI MNDWI"
    for band in $bands
    do
        echo ""
        echo "#############################################################################"
        echo "Case ${c}: computing median of Band ${band}..."
        echo ""
    
        if [ $band == "NDVI" -o $band == "MNDWI" ] ; then
            suffix="${band}"
        else
            suffix="${band}.topocorr"
        fi
        
        maps=$(grass74 -text "$mapset" --exec g.list type="raster" pattern="*${suffix}" mapset=$(echo $mapset | rev | cut -f1 -d'/' | rev))
        
        # choose scenes without clouds, without snow, not shifted - manually
        case "$c" in
           "Oslo") 
                maps=$(echo $maps | sed "s/S2A_OPER_PRD_MSIL1C_PDMC_20160817T201311_R008_V20160816T104022_20160816T104025.${suffix}//g")
           ;;
           "Hjerkinn")
                maps=$(echo $maps | sed "s/S2A_MSIL1C_20170926T105811_N0205_R094_T32VNQ_20170926T105809.${suffix}//g")
                maps=$(echo $maps | sed "s/S2A_MSIL1C_20170923T105021_N0205_R051_T32VNQ_20170923T105022.${suffix}//g")
                maps=$(echo $maps | sed "s/S2A_MSIL1C_20170903T105031_N0205_R051_T32VNQ_20170903T105026.${suffix}//g")
                maps=$(echo $maps | sed "s/S2A_MSIL1C_20170628T105651_N0205_R094_T32VNQ_20170628T105649.${suffix}//g")
                maps=$(echo $maps | sed "s/S2A_OPER_PRD_MSIL1C_PDMC_20160706T175909_R008_V20150822T104035_20150822T104035.${suffix}//g")
                maps=$(echo $maps | sed "s/S2A_OPER_PRD_MSIL1C_PDMC_20160705T144620_R051_V20150815T105041_20150815T105041.${suffix}//g")
           ;;
           "Luroeykalven")
                maps=$(echo $maps | sed "s/S2A_MSIL1C_20170916T105701_N0205_R094_T32VKN_20170916T105658.B01.topocorr//g") # problem with this particular band
                maps=$(echo $maps | sed "s/S2A_MSIL1C_20170601T110651_N0205_R137_T32VKN_20170601T111225.${suffix}//g")
                maps=$(echo $maps | sed "s/S2B_MSIL1C_20170723T105619_N0205_R094_T32VKN_20170723T105619.${suffix}//g")
                maps=$(echo $maps | sed "s/S2B_MSIL1C_20170822T105649_N0205_R094_T32VKN_20170822T105648.${suffix}//g")
                maps=$(echo $maps | sed "s/S2B_MSIL1C_20170825T110649_N0205_R137_T32VKN_20170825T111247.${suffix}//g")
                maps=$(echo $maps | sed "s/S2B_MSIL1C_20170924T110749_N0205_R137_T32VKN_20170924T111106.${suffix}//g")
           ;;
           "Dovre1")
                maps=$(echo $maps | sed "s/S2A_OPER_PRD_MSIL1C_PDMC_20160705T144620_R051_V20150815T105041_20150815T105041.${suffix}//g")
                maps=$(echo $maps | sed "s/S2A_OPER_PRD_MSIL1C_PDMC_20160706T175909_R008_V20150822T104035_20150822T104035.${suffix}//g")
                maps=$(echo $maps | sed "s/S2A_MSIL1C_20170628T105651_N0205_R094_T32VNQ_20170628T105649.${suffix}//g")
                maps=$(echo $maps | sed "s/S2B_MSIL1C_20170630T105029_N0205_R051_T32VNQ_20170630T105305.${suffix}//g")
           ;;
           "Dovre2")
                maps=$(echo $maps | sed "s/S2A_OPER_PRD_MSIL1C_PDMC_20160705T144620_R051_V20150815T105041_20150815T105041.${suffix}//g")
                maps=$(echo $maps | sed "s/S2A_MSIL1C_20170628T105651_N0205_R094_T32VMQ_20170628T105649.${suffix}//g")
                maps=$(echo $maps | sed "s/S2B_MSIL1C_20170630T105029_N0205_R051_T32VMQ_20170630T105305.${suffix}//g")
        esac   
        
        maps=$(echo $maps | sed "s/ /,/g")
               
        # compute median value of band over the whole timespan
        median="S2_${c}_total.${suffix}.median"
        grass74 -text "$mapset" --exec r.mapcalc --o --q expression="${median} = median(${maps})"
        
        # rescale median value to 1-10000 (not MNDWI)
        median_10000="S2_${c}_total.${suffix}.median_10000"
        if [ $band != "MNDWI" ] ; then
            grass74 -text "$mapset" --exec r.mapcalc --o --q expression="${median_10000} = int(${median}*10000)"
        fi       
       
        echo ""
        echo "... Case ${c}: Median of Band ${band} computed."
        echo "#############################################################################"
        echo ""
     
    done # for band in bands
    
    # ############# #
    # COMPUTE MASKS #
    # ############# #
    
    # compute slope
    slope="slope"
    grass74 -text "$mapset" --exec r.slope.aspect --o elevation="${dem_filled}" slope="${slope}"
    
    # compute mask
    mask="mask"
    case "$c" in
           "Oslo") 
            grass74 -text "$mapset" --exec r.mapcalc --q --o expression="${mask} = if(!isnull(S2_Oslo_total.NDVI.median),if(S2_Oslo_total.NDVI.median<-0.04 || S2_Oslo_total.MNDWI.median>0.4,1,0),1)"
           ;;
           "Hjerkinn")
            grass74 -text "$mapset" --exec r.mapcalc --q --o expression="${mask} = if(!isnull(S2_Hjerkinn_total.NDVI.median),if(S2_Hjerkinn_total.NDVI.median<0 || S2_Hjerkinn_total.MNDWI.median>0.02,1,0),1)"
           ;;
           "Luroeykalven")
            grass74 -text "$mapset" --exec r.mapcalc --q --o expression="${mask} = if(!isnull(S2_Luroeykalven_total.NDVI.median),if(S2_Luroeykalven_total.NDVI.median<0,0,1),1)"
           ;;
           "Dovre1")
            grass74 -text "$mapset" --exec r.mapcalc --q --o expression="${mask} = if(!isnull(S2_Dovre1_total.NDVI.median),if(${slope}<0.5 || S2_Dovre1_total.NDVI.median<0 || S2_Dovre1_total.MNDWI.median>0.02,1,0),1)"
           ;;
           "Dovre2")
            grass74 -text "$mapset" --exec r.mapcalc --q --o expression="${mask} = if(!isnull(S2_Dovre2_total.NDVI.median),if(${slope}<0.5 || S2_Dovre2_total.NDVI.median<0 || S2_Dovre2_total.MNDWI.median>0.02,1,0),1)"
    esac   
    grass74 -text "$mapset" --exec r.mask --overwrite raster="${mask}" maskcats=0
    
    echo "##############################################################"
    echo "End processing case ${c}."
done # for c in case
