
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

##################################################
# Respondent info and health of household members
##################################################

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

##################################################
# Housing Characteristics
##################################################

##########
# Housing
##########

housing <- `41. HousingandSanitation.dta` 

# if there is a hh_ID duplicate, use the first entry
# question was only supposed to be answered once but some households submitted twice
housing$submissiondate <- as.Date(housing$submissiondate, "%b %d, %Y")
housing <- setDT(housing)[housing[, .I[which.min(submissiondate)], by=hh_ID]$V1]
housing <- housing %>% select(-submissiondate)
# TRUE, if there are no duplicates in hh_ID
# length(unique(housing$hh_ID)) == nrow(housing)

# recode factor levels for housing characteristics
housing$lighting_source_type = as.factor(
  ifelse(housing$lighting_source %in% c('1'),'electricity',
         ifelse(housing$lighting_source %in% c('3'),'solar',
                ifelse(housing$lighting_source %in% c('4'),'kerosine','other'))))
housing$housefloor_material = as.factor(
  ifelse(housing$housefloor_material %in% c('1'),
         'concrete',
         ifelse(housing$housefloor_material %in% c('2','3','5','99'),'other','mud'))
)
housing$houseroof_material = as.factor(
  ifelse(housing$houseroof_material %in% c('2'), 'tin','other'))
housing$housewall_material = as.factor(
  ifelse(housing$housewall_material %in% c('1'),
         'concrete',
         ifelse(housing$housewall_material %in% c('3','4','5','8'),'other','tin'))
)
housing <- housing %>% select(hh_ID,
                              house_rooms_sleeping, 
                              housefloor_material, 
                              houseroof_material,
                              house_elec,
                              housewall_material)
# factor electricity variable
housing$house_elec <- as.factor(housing$house_elec)

##########
# Plots
##########

# merge plot datasets together
plots <- Plots_plot_level_2.dta # fix year
temp <- plots_level_1.dta %>% select(hh_ID, submissiondate, plot_1_ID, today) 
plots <- merge(plots, temp, by=c("hh_ID","plot_1_ID"))

# find plot age
plots$today <- format(as.Date(plots$today, format="%b %d, %Y"),"%Y")
plots$yr_acq <- format(as.Date(plots$yr_acq, format="%b %d, %Y"),"%Y")  
plots$today <- as.numeric(plots$today)
plots$yr_acq <- as.numeric(plots$yr_acq)
plots$plot_age <- plots$today - plots$yr_acq 

# too many plot types (change to three types: homestead, cultivable, other)
# 1	Homestead
# 2	Cultivable/arable land
# 3	Pasture
# 4	Bush/forest
# 5	Waste/non-arable land
# 6	Land in riverbed
# 7	Other residential/commercial plot
# 8	Cultivable Pond
# 9	Derelict Pond
plots$plot_type_homestead <- ifelse(grepl("1",plots$plot_type), 1, 0)
temp <- c("2","8")
plots$plot_type_cultivable_land_pond <- ifelse(grepl(paste(temp, collapse = "|"),plots$plot_type), 1, 0)
temp <- c("3","4","5","6","7","9"," ")
plots$plot_type_other <- ifelse(grepl(paste(temp, collapse = "|"),plots$plot_type), 1, 0)
plots <- plots %>% 
  mutate(plot_type = case_when((plot_type_homestead==1) ~ "homestead",
                               (plot_type_cultivable_land_pond==1) ~ "cultivable",
                               (plot_type_other==1) ~ "other"))
plots <- plots %>% select(-plot_type_homestead,-plot_type_cultivable_land_pond,-plot_type_other)

# create variable has a cultivable plot 
plots <- plots %>% mutate(hasCultivablePlot = ifelse(plot_type == "cultivable",1,0))
temp <- plots %>% group_by(hh_ID) %>% tally(hasCultivablePlot)
plots <- merge(plots, temp, by = "hh_ID")
plots <- plots %>% mutate(totalCultivablePlot = n) %>% select(-n)

# operational status
# cur_opr	1	Fallow
# cur_opr	2	Own operated
# cur_opr	3	Rented/leased in/cash
# cur_opr	4	Rented/leased in/crop share
# cur_opr	5	Mortgaged in
# cur_opr	6	Rented/leased out/cash
# cur_opr	7	Rented/leased out/crop share
# cur_opr	8	Mortgage out
# cur_opr	9	Group leased in with other farmer
# cur_opr	10	Leased out to NGO
# cur_opr	11	Taken from joint owner
# cur_opr	12	Jointly with other owners

#  1   2   3   4   5   6   7   8   9  11  12 
# 56 354  17   8  21   6   5   9   4   2   1

# owns a plot
plots <- plots %>% mutate(hasOwnPlot = ifelse(cur_opr_status == 2,1,0))
temp <- plots %>% group_by(hh_ID) %>% tally(hasOwnPlot)
plots <- merge(plots, temp, by = "hh_ID")
plots <- plots %>% mutate(totalOwnPlot = n) %>% select(-n)

# select variables 
plots <- plots %>% select(hh_ID, 
                          totalCultivablePlot,
                          totalOwnPlot)

# remove duplicates
plots <- distinct(plots, hh_ID, .keep_all= TRUE)
# plots$hh_ID[duplicated(plots$hh_ID)]

##########
## Non-agricultural enterprise
##########

# Anyone in household owned/operated any business in 12 months?
nonagricultural_enterprise <- `57. NonAgriculturalEnterprise_level_1.dta` %>% select(hh_ID, submissiondate, business)

# if there is a hh_ID duplicate, use the first entry
nonagricultural_enterprise$submissiondate <- as.Date(nonagricultural_enterprise$submissiondate, "%b %d, %Y")
nonagricultural_enterprise <- setDT(nonagricultural_enterprise)[nonagricultural_enterprise[, .I[which.min(submissiondate)], by=hh_ID]$V1]
nonagricultural_enterprise <- nonagricultural_enterprise %>% select(-submissiondate)


# factor variables
nonagricultural_enterprise$business <- factor(nonagricultural_enterprise$business)

# check for duplicates 
# nonagricultural_enterprise$hh_ID[duplicated(nonagricultural_enterprise$hh_ID)]

##########
## Latrine and Water
##########

# select variables
latrine <- `87. latrineUse.dta` %>% select(hh_ID, submissiondate, use_lat, main_use, count_latrine, pct_open)

# main_use  - too many factor levels (change to flush or no flush)
temp <- c("1","2","3","4","5","6")
latrine$main_use_flush <- ifelse(grepl(paste(temp, collapse = "|"),latrine$main_use), 1, 0)
latrine <- latrine %>% select(-main_use)

# pct_open  - too many factor levels (change to defacate or doesn't defacate in public)
latrine$defecation_public <- ifelse(grepl("1",latrine$pct_open), 1, 0)
latrine <- latrine %>% select(-pct_open)

# remove outliers for latrine count
latrine <- latrine %>% filter(count_latrine >= 0 & count_latrine <= 10)

# if there is a hh_ID duplicate, use the first entry
latrine$submissiondate <- as.Date(latrine$submissiondate, "%b %d, %Y")
latrine <- setDT(latrine)[latrine[, .I[which.min(submissiondate)], by=hh_ID]$V1]
latrine <- latrine %>% select(-submissiondate)

# factor variables
latrine$use_lat <- factor(latrine$use_lat)
latrine$main_use_flush <- factor(latrine$main_use_flush)
latrine$defecation_public <- factor(latrine$defecation_public)



