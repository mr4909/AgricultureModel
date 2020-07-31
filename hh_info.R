
############################################################
# Wellbeing and Food in Bangladesh
# by Mari Roberts
############################################################

#########
# load necessary packages
#########
requiredPackages = c('foreign', # read dta
                     'dplyr', # data manipulation
                     'haven', # read files
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
                     'lme4', # linear mixed effects model
                     'tidyverse') # missing values using map
# only downloads packages if needed
for(p in requiredPackages){
  if(!require(p,character.only = TRUE)) install.packages(p)
  library(p,character.only = TRUE)
}

#########
# import
#########

# set wd
mydirectory <- "/Users/mari/AgricultureModel/Datasets"
setwd(mydirectory)

filenames <- list.files(path=mydirectory, pattern=".*dta")

# read in each dta file found in Dataset folder
filenames <- list.files(path=mydirectory, pattern=".*dta")
for (i in 1:length(filenames)){
  assign(filenames[i], read_dta(paste("", filenames[i], sep=''))
  )}

#########
# custom functions
#########

# remove outliers 
outliers <- function(x){
  quantiles <- quantile( x, c(.00, .95 ) )
  x[ x < quantiles[1] ] <- quantiles[1]
  x[ x > quantiles[2] ] <- quantiles[2]
  x
}

########################################################################
########################################################################
# Questions Asked Once
########################################################################
########################################################################

#########
# hh members
#########

# find number of household members for calculations later
hh_count <- HouseholdComposition_level_1.dta %>% select(hh_ID, member_1_ID, hh_members) %>% 
  distinct(hh_ID, .keep_all = TRUE)

# import health measures asked once & rename variables
hh <- HouseholdComposition_members_level_2.dta %>% mutate(canStandOwn = hhm_health1,
                                                          canWalk5Km = hhm_health2,
                                                          canCarry20L = hhm_health3)
# merge with hh with hh_count
hh <- merge(hh_count, hh, by=c("hh_ID","member_1_ID"))

# combine 0 and 77 ("no" and "don't know")
hh_all <- hh %>% mutate(canCarry20L = ifelse(canCarry20L==77 | canCarry20L==0, 0, 1),
                        canWalk5Km = ifelse(canWalk5Km==77 | canWalk5Km==0, 0, 1),
                        canStandOwn = ifelse(canStandOwn==77 | canStandOwn==0, 0, 1),
                        sex = ifelse(hhm_sex == 1,0,1))

# recode sex, 0 = male, 1 = female 
# select variables
hh_all <- hh_all %>% select(hh_ID,
                           member_1_ID,
                           member_2_ID,
                           hh_members,
                           currentposition,
                           hhm_relation,
                           sex,
                           age = hhm_age,
                           maritalStatus = marital_status,
                           literacy,
                           education,
                           attendingCollege = hhm_attending,
                           occupationType = hhm_occu_type,
                           #hhm_occupation,
                           canCarry20L,
                           canWalk5Km,
                           canStandOwn)

# factor variables
hh_all$sex = factor(hh_all$sex)
hh_all$maritalStatus = factor(hh_all$maritalStatus)
hh_all$literacy = factor(hh_all$literacy)
hh_all$education = factor(hh_all$education)
hh_all$attendingCollege = factor(hh_all$attendingCollege)
hh_all$occupationType = factor(hh_all$occupationType)

# does hh have children?
hh_all <- hh_all %>% mutate(isChild = ifelse(age>=18, 0, 1))
hh_children <- hh_all %>% group_by(hh_ID) %>% tally(isChild)
hh_children <- hh_children %>% mutate(numChildren = n) %>% select(hh_ID, numChildren)

# merge number of children dataset with hh_all
hh_all <- merge(hh_children, hh_all, by = "hh_ID")
# factor variables
hh_all$isChild <- factor(hh_all$isChild)

#########
# health
#########

# count health measures per household
hh_subset <- hh_all %>% select(hh_ID, member_1_ID, canCarry20L, canWalk5Km, canStandOwn)
carry <- hh_subset %>% group_by(hh_ID) %>% tally(canCarry20L)
walk <- hh_subset %>% group_by(hh_ID) %>% tally(canWalk5Km)
stand <- hh_subset %>% group_by(hh_ID) %>% tally(canStandOwn)

# determine percentage of health measure per household
hh_health <- merge(hh_all, carry, by = "hh_ID") 
hh_health <- merge(hh_health, walk, by = "hh_ID") 
hh_health <- merge(hh_health, stand, by = "hh_ID") 
hh_health <- hh_health %>% mutate(totalCanCarry20L = n.x,
                                  totalCanWalk5Km = n.y,
                                  totalCanStandOwn = n)
hh_health <- hh_health %>% mutate(pctCanCarry20L = totalCanCarry20L/hh_members,
                                  pctCanWalk5Km = totalCanWalk5Km/hh_members,
                                  pctCanStandOwn = totalCanStandOwn/hh_members) %>% select(-n.x,-n.y,-n)

# remove outliers - percentages above 100, 
# remove errors - differences in number of members reported
hh_health <- hh_health %>% filter(pctCanCarry20L <= 1 &
                                    pctCanWalk5Km <= 1 &
                                    pctCanStandOwn <= 1)

# factor variables
hh_health$canCarry20L = factor(hh_health$canCarry20L)
hh_health$canWalk5Km = factor(hh_health$canWalk5Km)
hh_health$canStandOwn = factor(hh_health$canStandOwn)

########################################################################
########################################################################
# Respondent info and health of household members
########################################################################
########################################################################

# data about respondents
hh_respondent <- hh_health %>% filter(hhm_relation == 1)

# remove variables
hh_respondent <- hh_respondent %>% select(-member_1_ID,
                                          -member_2_ID,
                                          -currentposition,
                                          -hhm_relation,
                                          -totalCanCarry20L,
                                          -totalCanStandOwn,
                                          -totalCanWalk5Km,
                                          -isChild)

########################################################################
########################################################################
# Wealth
########################################################################
########################################################################

