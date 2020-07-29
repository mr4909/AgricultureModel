
# by Mari Roberts

##################################################################
# load libraries, create custom functions, and import datasets 
##################################################################

# load necessary packages
requiredPackages = c('foreign', # read dta
                     'dplyr', # data manipulation
                     'haven',
                     'gridExtra', # data manipulation
                     'readr', # read files
                     'readxl',# read files
                     'dummies', # PCA
                     'lubridate', # data manipulation
                     'data.table', # data manipulation
                     'FactoMineR', # PCA
                     'factoextra', # PCA
                     'psych', # PCA
                     'nFactors', # PCA
                     'lattice', # plots
                     'glmnet', # lasso
                     'caret', # lasso
                     'ggplot2', # plots
                     'cluster', # clustering
                     'Rtsne', # clustering
                     'tidyverse') # missing values using map
# only downloads packages if needed
for(p in requiredPackages){
  if(!require(p,character.only = TRUE)) install.packages(p)
  library(p,character.only = TRUE)
}

# set wd
mydirectory <- "/Users/mari/AgricultureModel/Datasets"
setwd(mydirectory)

filenames <- list.files(path=mydirectory, pattern=".*dta")

# read in each dta file found in Dataset folder
filenames <- list.files(path=mydirectory, pattern=".*dta")
for (i in 1:length(filenames)){
  assign(filenames[i], read_dta(paste("", filenames[i], sep=''))
  )}

# custom functions
# remove outliers 
outliers <- function(x){
  quantiles <- quantile( x, c(.00, .95 ) )
  x[ x < quantiles[1] ] <- quantiles[1]
  x[ x > quantiles[2] ] <- quantiles[2]
  x
}