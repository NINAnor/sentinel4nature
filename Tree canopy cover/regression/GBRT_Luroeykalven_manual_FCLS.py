# GBRT for Luroeykalven case study site
# Training data: manually digitized training areas, including water pixels
# Predictors: results of FCLS spectral unmixing
# Authors: Stefan Blumentrath

import numpy as np
import matplotlib.pyplot as plt

from sklearn import ensemble
from sklearn import datasets
from sklearn.utils import shuffle
from sklearn.metrics import mean_squared_error
from sklearn.metrics import r2_score
from sklearn.ensemble.partial_dependence import plot_partial_dependence
from sklearn.model_selection import GridSearchCV

from grass.pygrass import raster as r
from grass.pygrass.utils import getenv
import grass.script as gs
from cStringIO import StringIO

from subprocess import PIPE

from io import BytesIO

from itertools import combinations

def setParamDict():
    params = {}
    for p in ['learning_rate', 'max_depth', 'loss', 'subsample',
              'min_samples_leaf', 'max_features', 'n_estimators']:
        if p in ['max_depth', 'min_samples_leaf', 'n_estimators']:
            params[p] = map(int, options[p].split(','))
        elif p in ['learning_rate', 'max_features', 'subsample']:
            params[p] = map(float, options[p].split(','))
        else:
            params[p] = options[p].split(',')
    return params

def writeMap(name, x,y,z):
    result = BytesIO()
    np.savetxt(result,
               np.column_stack((x,
                                y,
                                z)))
    result.seek(0)
    gs.write_command('r.in.xyz', stdin=result.getvalue(), input='-', output=name,
                     method='mean', separator=' ', overwrite=True)

# #############################################################################
# Define variables
# List of input maps has to start with Y

# Initaial settings for automatized model selection
options = {'cores': '20',
           'learning_rate': '0.009,0.007,0.005',
           'max_depth': '11,13,15',
           'min_samples_leaf': '1,2,3',
           'max_features': '0.9,0.8,0.7',
           'subsample': '0.5',
           'loss': 'huber',
           'n_estimators': '3000',
           'y': 'test_area_luroeykalven_water_grid_25833_10m@p_Sentinel4Nature_S2_Luroeykalven',
           'x': 'unmix_pysptools_bands_NDVI_VVVH_10000_10_NFINDR_FCLS_mask_1,unmix_pysptools_bands_NDVI_VVVH_10000_10_NFINDR_FCLS_mask_2,unmix_pysptools_bands_NDVI_VVVH_10000_10_NFINDR_FCLS_mask_3,unmix_pysptools_bands_NDVI_VVVH_10000_10_NFINDR_FCLS_mask_4,unmix_pysptools_bands_NDVI_VVVH_10000_10_NFINDR_FCLS_mask_5,unmix_pysptools_bands_NDVI_VVVH_10000_10_NFINDR_FCLS_mask_6,unmix_pysptools_bands_NDVI_VVVH_10000_10_NFINDR_FCLS_mask_7,unmix_pysptools_bands_NDVI_VVVH_10000_10_NFINDR_FCLS_mask_8,unmix_pysptools_bands_NDVI_VVVH_10000_10_NFINDR_FCLS_mask_9,unmix_pysptools_bands_NDVI_VVVH_10000_10_NFINDR_FCLS_mask_10',
           'deviance': '/data/R/GeoSpatialData/Orthoimagery/Fenoscandia_Sentinel_2/temp_Avd15GIS/Case_Luroeykalven/regression/Luroeykalven_water_FCLS_GBRT_deviance.pdf',
           'featureimportance': '/data/R/GeoSpatialData/Orthoimagery/Fenoscandia_Sentinel_2/temp_Avd15GIS/Case_Luroeykalven/regression/Luroeykalven_water_FCLS_GBRT_featureimportance.pdf',
           'partialdependence': '/data/R/GeoSpatialData/Orthoimagery/Fenoscandia_Sentinel_2/temp_Avd15GIS/Case_Luroeykalven/regression/Luroeykalven_water_FCLS_GBRT_partial_dependence.pdf',
           'crossval': '0.25',
           'output': 'ForestCover_Luroeykalven_water_FCLS',
           'spatial_term': None
           }

           
cores = int(options['cores'])
spatial_term = options['spatial_term']
output = options['output']
deviance = options['deviance']
featureimportance = options['featureimportance']
partialdependence = options['partialdependence']
crossval = float(options['crossval'])
params = setParamDict()

# #############################################################################
# Load data
maps = [options['y']] + options['x'].rstrip('\n').split(',')

data = np.genfromtxt(BytesIO(gs.read_command('r.stats',
                                             flags='1Ng',
                                             input=maps)), delimiter=" ")

y = 2
if spatial_term:
    x = [0,1] + range(3,len(data[0]))
else:
    x = range(3,len(data[0]))

# Create a mas for NoData in either x or y
mask_y = np.isnan(data[:,y])
for i in range(3,len(data[0])):
    if i == 3:
        mask_x = np.isnan(data[:,i])
    else:
        mask_x = np.logical_or((np.isnan(data[:,i])), mask_x)

all_y_idx = np.where(np.logical_or(mask_x, mask_y)==False)
all_x_idx = np.where(mask_x==False)
# Random shuffle data points with training data, excluding all NoData
all_y = shuffle(data[all_y_idx])

# Training and test set
offset = int(all_y.shape[0] * (1 - crossval))
X_train, y_train, coor_train = all_y[:offset,x], all_y[:offset,y], all_y[:offset,[0,1]]
X_test, y_test, coor_test= all_y[offset:,x], all_y[offset:,y], all_y[offset:,[0,1]]

# Set for predicitions
predict, coor_predict = data[all_x_idx][:,x], data[all_x_idx][:,[0,1]]

# Run model selection process if requested
model_selection = False
for k in params.keys():
    if len(params[k]) > 1:
        model_selection = True
if model_selection:
    gs.message('Running model selection ...')
    clf = ensemble.GradientBoostingRegressor()
    # this may take some minutes
    gs_cv = GridSearchCV(clf, params, n_jobs=cores).fit(X_train, y_train)

    # best hyperparameter setting
    best_params = gs_cv.best_params_
    print('Best hyper-parameter set is:')
    print(best_params)
else:
    best_params = {}
    for k in params.keys():
        best_params[k] = params[k][0]

# #############################################################################
# Fit regression model
gs.message('Fitting regression model ...')
clf = ensemble.GradientBoostingRegressor(**best_params)
clf.fit(X_train, y_train)

mse = mean_squared_error(y_test, clf.predict(X_test))
r2 = r2_score(y_test, clf.predict(X_test))

print("MSE: %.4f" % mse)
print("R2: %.4f" % r2)

# #############################################################################
# Generate requested plots
    # Plot training deviance
    # compute test set deviance
if deviance:
    test_score = np.zeros((best_params['n_estimators'],), dtype=np.float64)

    for i, y_pred in enumerate(clf.staged_predict(X_test)):
        test_score[i] = clf.loss_(y_test, y_pred)

    plt.figure(figsize=(12, 6))
    plt.rcParams.update({'figure.autolayout': True})
    plt.title('Deviance')
    plt.plot(np.arange(best_params['n_estimators']) + 1, clf.train_score_, 'b-',
             label='Training Set Deviance')
    plt.plot(np.arange(best_params['n_estimators']) + 1, test_score, 'r-',
             label='Test Set Deviance')
    plt.legend(loc='upper right')
    plt.xlabel('Boosting Iterations')
    plt.ylabel('Deviance')
    plt.savefig(deviance)

# #############################################################################
# Plot feature importance
if featureimportance:
    if spatial_term:
        cols = ['x', 'y'] + maps[1:]
    else:
        cols = maps[1:]
    plt.figure(figsize=(12, 12))
    plt.rcParams.update({'figure.autolayout': True})
    feature_importance = clf.feature_importances_
    # make importances relative to max importance
    feature_importance = 100.0 * (feature_importance / feature_importance.max())
    sorted_idx = np.argsort(feature_importance)
    pos = np.arange(sorted_idx.shape[0]) + .5
    #plt.subplot(1, 2, 2)
    plt.barh(pos, feature_importance[sorted_idx], align='center')
    plt.yticks(pos, np.array(cols)[sorted_idx])
    plt.xlabel('Relative Importance')
    plt.title('Variable Importance')
    plt.savefig(featureimportance)

if partialdependence:
    if spatial_term:
        cols = ['x', 'y'] + maps[1:]
    else:
        cols = maps[1:]
    fig, axs = plot_partial_dependence(clf, X_train, cols, n_jobs=cores, n_cols=2,
                                       feature_names=cols, figsize=(len(cols), len(cols)*2))
    fig.savefig(partialdependence)

    sorted_idx = np.argsort(clf.feature_importances_)
    twoway = list(combinations(list(reversed(sorted_idx[-6:])), 2))
    fig, axs = plot_partial_dependence(clf, X_train, twoway, n_jobs=cores, n_cols=2,
                                       feature_names=cols, figsize=(len(twoway), int(len(twoway)*3)))
    fig.savefig(partialdependence.rstrip('.pdf') + '_twoway.pdf')

# #############################################################################
# Predict data outside trainifrom subprocess import PIPEng areas
writeMap(output, coor_predict[:,0], coor_predict[:,1], clf.predict(predict))

# Write train error map
writeMap(output + '_train_error', coor_train[:,0], coor_train[:,1], clf.predict(X_train) - y_train)

# Write test error map
writeMap(output + '_test_error', coor_test[:,0], coor_test[:,1], clf.predict(X_test) - y_test)
