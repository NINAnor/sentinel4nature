#NAME:    Comparison of model results to current forest products
#
#AUTHOR(S): Zofie Cimburova < zofie.cimburova AT nina.no>
#
#PURPOSE:   Comparison of results of two best-performing GBRT models to current forest products in Sunndalen case study site.
#           Current forest products: NORUT (Johansen 2009), 
#                                    High-Resolution Global Maps of 21st-Century Forest Cover Change by Hansen et al. (2013) 
#                                    SAT-SKOG forest map from Nibio
#           These were compared with ground vegetation measurements by means of correlation coefficients. 
#           To ensure robustness of the comparison, three types of correlations – Pearson’s, Spearman’s and Kendall’s coefficients were observed.
#           The analysis is performed in R.

#
#To Dos:
#

measurements <- read.csv("validation_forest_cover_data.csv")

# remove useless columns
# COVER_A - trees higher than 2 m were recorded
# COVER_B - shrubs higher than 70 cm were recorded
measurements <- measurements[c("COVER_A","COVER_B","SATSKOG","NORUT","HANSEN","REGRESSION_test","REGRESSION_lidar")]

# replace negative values in REGRESSION with 0
measurements$REGRESSION_test[measurements$REGRESSION_test<0 & !is.na(measurements$REGRESSION_test<0) ]<-0
measurements$REGRESSION_lidar[measurements$REGRESSION_lidar<0 & !is.na(measurements$REGRESSION_lidar<0) ]<-0

# remove rows with NULL in REGRESSION
measurements <- measurements[!is.na(measurements$REGRESSION_test), ]
measurements <- measurements[!is.na(measurements$REGRESSION_lidar), ]

# ratio to percentage in REGRESSION
measurements$REGRESSION_test <- measurements$REGRESSION_test*100

# edit NORUT categories to values
# 1 1
# 2 1
# 3 0.5
# 4 1 
# 5 1
# 6 1
# 7 0.5
# 8 0.5

measurements$NORUT_val <- 1
measurements$NORUT_val[measurements$NORUT==1 | measurements$NORUT==4| measurements$NORUT==5]<- 100
measurements$NORUT_val[measurements$NORUT==6]<- 75
measurements$NORUT_val[measurements$NORUT==2 | measurements$NORUT==3| measurements$NORUT==8]<- 50
measurements$NORUT_val[measurements$NORUT==7]<- 25
measurements$NORUT_val[measurements$NORUT==0]<- 0

# STATISTICS - LAYER A
cor(measurements$COVER_A,measurements$HANSEN, method = "pearson")
cor(measurements$COVER_A,measurements$NORUT_val, method = "pearson")
cor(measurements$COVER_A,measurements$SATSKOG, method = "pearson")
cor(measurements$COVER_A,measurements$REGRESSION_test, method = "pearson")
cor(measurements$COVER_A,measurements$REGRESSION_lidar, method = "pearson")

cor(measurements$COVER_A,measurements$HANSEN, method = "spearman")
cor(measurements$COVER_A,measurements$NORUT_val, method = "spearman")
cor(measurements$COVER_A,measurements$SATSKOG, method = "spearman")
cor(measurements$COVER_A,measurements$REGRESSION_test, method = "spearman")
cor(measurements$COVER_A,measurements$REGRESSION_lidar, method = "spearman")

cor(measurements$COVER_A,measurements$HANSEN, method = "kendal")
cor(measurements$COVER_A,measurements$NORUT_val, method = "kendal")
cor(measurements$COVER_A,measurements$SATSKOG, method = "kendal")
cor(measurements$COVER_A,measurements$REGRESSION_test, method = "kendal")
cor(measurements$COVER_A,measurements$REGRESSION_lidar, method = "kendal")


# STATISTICS - LAYER A + B
cor(measurements$COVER_A+measurements$COVER_B,measurements$HANSEN, method = "pearson")
cor(measurements$COVER_A+measurements$COVER_B,measurements$NORUT_val, method = "pearson")
cor(measurements$COVER_A+measurements$COVER_B,measurements$SATSKOG, method = "pearson")
cor(measurements$COVER_A+measurements$COVER_B,measurements$REGRESSION_test, method = "pearson")
cor(measurements$COVER_A+measurements$COVER_B,measurements$REGRESSION_lidar, method = "pearson")

cor(measurements$COVER_A+measurements$COVER_B,measurements$HANSEN, method = "spearman")
cor(measurements$COVER_A+measurements$COVER_B,measurements$NORUT_val, method = "spearman")
cor(measurements$COVER_A+measurements$COVER_B,measurements$SATSKOG, method = "spearman")
cor(measurements$COVER_A+measurements$COVER_B,measurements$REGRESSION_test, method = "spearman")
cor(measurements$COVER_A+measurements$COVER_B,measurements$REGRESSION_lidar, method = "spearman")

cor(measurements$COVER_A+measurements$COVER_B,measurements$HANSEN, method = "kendal")
cor(measurements$COVER_A+measurements$COVER_B,measurements$NORUT_val, method = "kendal")
cor(measurements$COVER_A+measurements$COVER_B,measurements$SATSKOG, method = "kendal")
cor(measurements$COVER_A+measurements$COVER_B,measurements$REGRESSION_test, method = "kendal")
cor(measurements$COVER_A+measurements$COVER_B,measurements$REGRESSION_lidar, method = "kendal")
