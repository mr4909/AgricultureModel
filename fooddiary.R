########################################################################
########################################################################
# Food Data:
# - Noncrowdsourced  
# - Recall period = week  
# - Calculated calories per food item(s) reported  
# - Calculated average calories (per hh member) per week by household  
# - Cleaned foods reported as counts 
# - Standardized calories to calories per gram 
########################################################################
########################################################################

#########
# load necessary packages
#########
requiredPackages = c('dplyr', # data manipulation
                     'readr', # read files
                     'ggplot2', # plots
                     'tidyverse') # missing values using map
# only downloads packages if needed
for(p in requiredPackages){
  if(!require(p,character.only = TRUE)) install.packages(p)
  library(p,character.only = TRUE)
}


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

#########
# import dta
#########

# read food info (calories, food names)
food_info <- read_csv("food_info.csv")

# import food datasets (3)
# select noncrowdsourced data and recall period of a week

fooddiary_1 <- read_dta("33.FoodDiary_level_1.dta")
fooddiary_2 <- read_dta("34. FoodDiary_food_level_2.dta")
fooddiary_3 <- read_dta("35. Fooddiary_food_foodtype_level_3.dta")

#########
# cleaning
#########

fooddiary_1 <- fooddiary_1 %>% filter(crowdsource==0 & recall=="week") %>% 
  # select variables
  select(hh_ID, 
         food_1_ID,
         submissiondate, 
         recall, # month 516 season 272 week 4944
         week_number, #3:50 weeks
         food_list, # groups of foods consumed
         food_count) # number of foods selected

# import food types
fooddiary_2 <- fooddiary_2 %>% select(hh_ID, food_1_ID, food_2_ID, food_grp_namec, food_type) #will require grepl

# import food quantities, food names, and quantities
fooddiary_3 <- fooddiary_3 %>% select(hh_ID, food_2_ID, food_3_ID, food_ID = food_type_name, 
                                                                   food_type_quant,
                                                                   food_type_unit,
                                                                   quant_pur, #How much consumed was purchased?
                                                                   quant_own, #How much consumed was own production?
                                                                   quant_other) #How much consumed was from other sources?

# merge food datasets
fooddiary_1_2 <- merge(fooddiary_1,fooddiary_2, by=c("hh_ID","food_1_ID"))
fooddiary_all <- merge(fooddiary_1_2,fooddiary_3, by=c("hh_ID","food_2_ID"))

# remove unwanted variables
fooddiary_all <- fooddiary_all %>% select(-food_type) # duplicate variable

# 118 food_type_name are missing
# remove missing values for now.
fooddiary_all <- fooddiary_all[complete.cases(fooddiary_all),]

#########
# Calories
#########

# merge with food list names 
fooddiary_cleaned <- merge(food_info, fooddiary_all, by="food_ID")
# select variables
fooddiary_cleaned <- fooddiary_cleaned %>% select(hh_ID,
                                                  submissiondate,
                                                  recall,
                                                  week_number,
                                                  food_ID,
                                                  food_count,
                                                  food_name,
                                                  food_name_type,
                                                  food_type_quant,
                                                  food_type_unit,
                                                  quant_pur,
                                                  quant_own,
                                                  quant_other,
                                                  food_1_ID,
                                                  food_2_ID,
                                                  food_3_ID)

# calculate percent purchased, grown, other
fooddiary_cleaned <- fooddiary_cleaned %>% mutate(quant_pur_pct = quant_pur/food_type_quant,
                                                  quant_own_pct = quant_own/food_type_quant,
                                                  quant_other_pct = quant_other/food_type_quant)

# merge with food calories/info
fooddiary_cleaned <- merge(fooddiary_cleaned, food_info, by=c("food_ID","food_name_type","food_name"))

# reorder variables
fooddiary_cleaned <- fooddiary_cleaned %>% select(hh_ID,
                                                  submissiondate,
                                                  recall,
                                                  week_number,
                                                  food_ID,
                                                  food_count,
                                                  food_name,
                                                  food_name_type,
                                                  food_type_quant,
                                                  food_type_unit,
                                                  calories_grams,
                                                  quant_pur,
                                                  quant_own,
                                                  quant_other,
                                                  quant_pur_pct,
                                                  quant_own_pct,
                                                  quant_other_pct,
                                                  food_1_ID,
                                                  food_2_ID,
                                                  food_3_ID)

# fix dates and times
fooddiary_cleaned <- fooddiary_cleaned %>%
  mutate(datetime = as.POSIXct(strptime(submissiondate, format = "%b %d, %Y %I:%M:%S %p")),
         datetime_military = strftime(datetime, format = "%Y-%m-%d %H:%M"))
fooddiary_cleaned <- fooddiary_cleaned %>% mutate(date_new = as.Date(as.POSIXct(strptime(datetime_military, format = "%Y-%m-%d"))))

# create date for weeks
# check for different week number dates and replace with the max date
# new_min <- fooddiary_cleaned %>% group_by(week_number) %>% summarise(min(date_new))
# new_min <- new_min %>% mutate(week_date = `min(date_new)`) %>% select(-`min(date_new)`)

#########
# *Food Type Unit* - need to be standardized
#########
# 1	Kg          *1000
# 2	Grams
# 3	Liter       *1000
# 4	Milliliter  
# 5	Tablespoon  *15
# 6	Teaspoon    *4.2
# 7	Drops       *0.05
# 8	Count

# unit conversions
fooddiary_cleaned <- fooddiary_cleaned %>% 
  mutate(calories_total_grams = case_when((food_type_unit==1) ~ calories_grams*(food_type_quant*1000),
                                          (food_type_unit==2) ~ calories_grams*food_type_quant,
                                          (food_type_unit==3) ~ calories_grams*(food_type_quant*1000),
                                          (food_type_unit==4) ~ calories_grams*(food_type_quant), 
                                          (food_type_unit==5) ~ calories_grams*food_type_quant,
                                          (food_type_unit==6) ~ calories_grams*(food_type_quant*4.2),
                                          (food_type_unit==7) ~ calories_grams*(food_type_quant*0.05)))

# rearrange columns
fooddiary_cleaned <- fooddiary_cleaned %>% select(hh_ID,
                                                  submissiondate,
                                                  recall,
                                                  week_number,
                                                  food_ID,
                                                  food_count,
                                                  food_name,
                                                  food_name_type,
                                                  food_type_quant,
                                                  food_type_unit,
                                                  calories_grams,
                                                  calories_total_grams,
                                                  quant_pur,
                                                  quant_own,
                                                  quant_other,
                                                  quant_pur_pct,
                                                  quant_own_pct,
                                                  quant_other_pct,
                                                  #time_of_day,
                                                  food_1_ID,
                                                  food_2_ID,
                                                  food_3_ID)
# head(fooddiary_cleaned)
# summary(fooddiary_cleaned$calories_total_grams)

# Min.  1st Qu.   Median     Mean  3rd Qu.     Max.     NA's 
#    0     1200     3000    17994     6000 12000000     2491 

#########
## Fix Food Units Claimed As Counts
#########

# food unit type selected = 8
fooddiary_count <- fooddiary_cleaned %>% filter(food_type_unit == 8) %>% arrange(desc(food_name_type))

#########
# fix outliers
# If food type quant is more than 100 is meat 
# or fish then change to grams which was likely the intention
# convert to total calories reported in grams
# this needs more work
#########

fooddiary_count$calories_total_grams = as.numeric(
  
  ifelse(fooddiary_count$food_name_type %in% c('fishlarge') & fooddiary_count$food_type_quant > 100, 
         fooddiary_count$calories_grams*fooddiary_count$food_type_quant,
         
         ifelse(fooddiary_count$food_name_type %in% c('fishsmall') & fooddiary_count$food_type_quant > 100, 
                fooddiary_count$calories_grams*fooddiary_count$food_type_quant,
                
                ifelse(fooddiary_count$food_name_type %in% c('meategg') & fooddiary_count$food_type_quant > 100, 
                       fooddiary_count$calories_grams*fooddiary_count$food_type_quant, 
                       
                       # grains (changed to kg)
                       case_when(fooddiary_count$food_name=="Parboiled rice (coarse)" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 fooddiary_count$food_name=="Fine rice" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 fooddiary_count$food_name=="Atta" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 fooddiary_count$food_name=="Non-parboiled rice (coarse)" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 fooddiary_count$food_name=="Semai/noodles" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 fooddiary_count$food_name=="Chira (flattened rice)" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 fooddiary_count$food_name=="Muri/Khoi (puffed rice)" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 # meats (mostly changed to kg)
                                 fooddiary_count$food_name=="Beef/buffalo" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 fooddiary_count$food_name=="Mutton" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 fooddiary_count$food_name=="Chicken" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 fooddiary_count$food_name=="Pigeon" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 fooddiary_count$food_name=="Fish egg" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant, # egg roe = 1g
                                 fooddiary_count$food_name=="Egg" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*50, # egg = 50g
                                 fooddiary_count$food_name=="Duck" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 fooddiary_count$food_name=="Stomach of beef/goat" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 fooddiary_count$food_name=="Dried meat" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 fooddiary_count$food_name=="Bids/bok/gughu" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 fooddiary_count$food_name=="Liver" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 # drinks/dairy (can = 340grams/12 fl oz)
                                 fooddiary_count$food_name=="Tea –prepared" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*340,
                                 fooddiary_count$food_name=="Coke/ Seven-up etc/Pepci/RC/Urocola etc" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*340,
                                 fooddiary_count$food_name=="Milk" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*340,
                                 fooddiary_count$food_name=="Milk in Tea" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*340,
                                 fooddiary_count$food_name=="Powdered Milk" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*35,# serving of powdered milk
                                 fooddiary_count$food_name=="Condensed Milk" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*340,
                                 fooddiary_count$food_name=="Butter" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*113, # serving of butter
                                 fooddiary_count$food_name=="Yogurt" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*340,
                                 fooddiary_count$food_name=="Cottage cheese or Paneer" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*340, 
                                 fooddiary_count$food_name=="Buttermilk" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*340, 
                                 fooddiary_count$food_name=="Solid Cheese Curds" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*340, 
                                 fooddiary_count$food_name=="Ice Cream" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*340,
                                 fooddiary_count$food_name=="Ice cream" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*340,
                                 # fish small (avg  serving size 170)
                                 # some gura mach in 500 for quantity.....fix later???????
                                 fooddiary_count$food_name=="Gura mach" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*170,
                                 fooddiary_count$food_name=="Panch mishali" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*170,
                                 fooddiary_count$food_name=="Palshe" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*170,
                                 fooddiary_count$food_name=="Tatkeni" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*170,
                                 fooddiary_count$food_name=="Puti" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*170,
                                 fooddiary_count$food_name=="Tengra" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*170,
                                 fooddiary_count$food_name=="Karfu fish" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*170,
                                 fooddiary_count$food_name=="Bata" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*170,
                                 fooddiary_count$food_name=="Kajari" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*170,
                                 fooddiary_count$food_name=="Small prawn" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*3,
                                 fooddiary_count$food_name=="Dried small shrimp/prawn" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*3,
                                 # pulses (avg serving size and average size (nuts))
                                 fooddiary_count$food_name=="Khesari" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*160,
                                 fooddiary_count$food_name=="Dried Lentil" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*160,
                                 fooddiary_count$food_name=="Shem bitchi" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*160,
                                 fooddiary_count$food_name=="Anchor daal" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*160,
                                 fooddiary_count$food_name=="Dried Chick pea" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*160,
                                 fooddiary_count$food_name=="Mung" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*160,
                                 fooddiary_count$food_name=="Black gram" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*160,
                                 fooddiary_count$food_name=="Dried Pea" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*160,
                                 fooddiary_count$food_name=="Groundnut" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 fooddiary_count$food_name=="Brazilnut" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 fooddiary_count$food_name=="Cashew Nut" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 fooddiary_count$food_name=="Almond/Badam" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 fooddiary_count$food_name=="Hazelnut" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 fooddiary_count$food_name=="Chestnut" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 # fix vegetables (avg serving size per item)
                                 fooddiary_count$food_name=="Patal" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Okra" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Eggplant" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*141,
                                 fooddiary_count$food_name=="Bitter gourd" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*125,
                                 fooddiary_count$food_name=="Radish" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*4.5,
                                 fooddiary_count$food_name=="Pumpkin" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*5000,
                                 fooddiary_count$food_name=="Green chili" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*45,
                                 fooddiary_count$food_name=="Potato" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*200,
                                 fooddiary_count$food_name=="Sweet potato" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*200,
                                 fooddiary_count$food_name=="Sheem" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100, # broad bean
                                 fooddiary_count$food_name=="Onion" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*150,
                                 fooddiary_count$food_name=="Tomato" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*40,
                                 fooddiary_count$food_name=="Sweet gourd" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*500,
                                 fooddiary_count$food_name=="Garlic" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*13,
                                 fooddiary_count$food_name=="Water gourd" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*145,
                                 fooddiary_count$food_name=="Drum stick" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100, # 26 cal / moringa
                                 fooddiary_count$food_name=="Carrot" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*70,
                                 fooddiary_count$food_name=="Green banana" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*30,
                                 fooddiary_count$food_name=="Cauliflower" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*550,
                                 fooddiary_count$food_name=="Danta (amaranth)" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*45, # 170 cal
                                 fooddiary_count$food_name=="Green Papaya"~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*680,
                                 fooddiary_count$food_name=="Ash gourd" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*8000,
                                 fooddiary_count$food_name=="Cucumber" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*25,
                                 fooddiary_count$food_name=="Kachu (arum)" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100, # 112 cal
                                 fooddiary_count$food_name=="Green mango" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*150,
                                 fooddiary_count$food_name=="Dhundal" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Kachur lati" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Green pea" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*18,
                                 fooddiary_count$food_name=="Green jackfruit" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*7937,
                                 fooddiary_count$food_name=="Mete alu" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*150,
                                 fooddiary_count$food_name=="Kakrol" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100, #spiny gourd
                                 fooddiary_count$food_name=="Soybean bori" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Beher gura" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100, # couldnt find
                                 fooddiary_count$food_name=="Shalgom" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*4.5, # turnip, couldnt find
                                 # fish large (avg large fish calorie count 1000)
                                 fooddiary_count$food_name=="Rui" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 fooddiary_count$food_name=="Telapia" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 fooddiary_count$food_name=="Swarputi" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 fooddiary_count$food_name=="Singi" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 fooddiary_count$food_name=="Grass Carp" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 fooddiary_count$food_name=="Taki" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 fooddiary_count$food_name=="Pangash" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 fooddiary_count$food_name=="Silver Carp" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 fooddiary_count$food_name=="Mrigel" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 fooddiary_count$food_name=="Kalibaus" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 fooddiary_count$food_name=="Hilsa" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 fooddiary_count$food_name=="Katla" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 fooddiary_count$food_name=="Jatka" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 fooddiary_count$food_name=="Aair" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 fooddiary_count$food_name=="Boal" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 fooddiary_count$food_name=="Dried fish" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 fooddiary_count$food_name=="Mirror Carp" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*1000,
                                 # spices (avg calorie count 5)
                                 fooddiary_count$food_name=="Dried chili" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*5,
                                 fooddiary_count$food_name=="Elachi" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*5,
                                 fooddiary_count$food_name=="Cinnamon" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*5,
                                 fooddiary_count$food_name=="Fresh Ginger" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*5,
                                 # other food (average serving size)
                                 fooddiary_count$food_name=="Pitha" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Ruti/Parota" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Singara" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Rice/Jao" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Piaju" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Cake" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Nimki" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Puri" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Alur chap" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Biscuit" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Bonroti/paoroti" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Khichuri" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Polao/Biryani/Tehari" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Chips" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Patties" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Chewing gum" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,                                               
                                 # vegetables (average serving size of 1 cup/128 grams)
                                 fooddiary_count$food_name=="Lal Shak (red amaranth)" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*128,
                                 fooddiary_count$food_name=="Bathua" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*128,
                                 fooddiary_count$food_name=="Pat Shak" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*128,
                                 fooddiary_count$food_name=="Dheki Shak" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*128,
                                 fooddiary_count$food_name=="Pui (Indian spinach)" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*128,
                                 fooddiary_count$food_name=="Dhania Shak" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*128,
                                 fooddiary_count$food_name=="Lau Shak" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*128,
                                 fooddiary_count$food_name=="Onion/garlic stalk" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*128,
                                 fooddiary_count$food_name=="Kalmi Shak" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*128,
                                 fooddiary_count$food_name=="Radish leaves" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*128,
                                 fooddiary_count$food_name=="Kachu Shak" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*128,
                                 fooddiary_count$food_name=="Kalo kachu Shak" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*128,
                                 fooddiary_count$food_name=="Cabbage" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*128,
                                 fooddiary_count$food_name=="Helencha" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*128,
                                 fooddiary_count$food_name=="Katanate" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*128,
                                 fooddiary_count$food_name=="Palang Shak (spinach)" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*128,
                                 fooddiary_count$food_name=="Pea leaves" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*128,
                                 fooddiary_count$food_name=="Drumstick leaves" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*128,
                                 fooddiary_count$food_name=="Mustard leaves" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*128,
                                 fooddiary_count$food_name=="Mixed leafy vegetables" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*128,
                                 fooddiary_count$food_name=="Dudhali Pata" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*128,
                                 fooddiary_count$food_name=="Khesari Shak" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*128,
                                 fooddiary_count$food_name=="Swett gourd leaves" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*128,
                                 fooddiary_count$food_name=="Black gram leaves" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*128,
                                 fooddiary_count$food_name=="Geema Shak" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*128,
                                 fooddiary_count$food_name=="Neem Shak" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*128,
                                 fooddiary_count$food_name=="Darkuni Shak" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*128,
                                 fooddiary_count$food_name=="Bokful" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*128,
                                 fooddiary_count$food_name=="Litchis" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*128,
                                 # oil (serving size 15m)  
                                 fooddiary_count$food_name=="Soybean" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*15,
                                 fooddiary_count$food_name=="Mustard" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*15,
                                 fooddiary_count$food_name=="Dalda/banspati" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*15,
                                 fooddiary_count$food_name=="Red Palm Oil" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*15,
                                 fooddiary_count$food_name=="Ghee" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*15,
                                 fooddiary_count$food_name=="Sesame oil" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*15, 
                                 fooddiary_count$food_name=="Yellow Palm Oil" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*15,
                                 # fruit(avg serving size) 
                                 fooddiary_count$food_name=="Apple" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Mango" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Guava" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Banana" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Lemon" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Karambola" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Grapes" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Dates" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Jujube/dried jujube" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Coconut" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Orange" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Bel" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Tamarind" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Olive" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Chalta" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Pomelo" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Jack Fruit" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Pomelo" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Amra" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Papaya" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Black berry" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Green Coconut" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Dalim" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Tarmuj (Water melon)" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Ata (bullock's heart)" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Bangi (Musk melon)" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Pine apple" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Sobeda" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100,
                                 fooddiary_count$food_name=="Jaamrul" ~ fooddiary_count$calories_grams*fooddiary_count$food_type_quant*100)))))

# view data
# summary(fooddiary_count$calories_total_grams)

# merge fooddiary_count (unit = 8) and other dataset fooddiary_count to get complete df
fooddiary_nocounts <- fooddiary_cleaned %>% filter(food_type_unit != 8)
fooddiary_all <- rbind(fooddiary_nocounts, fooddiary_count)

########################################################################
########################################################################
# FINAL FOOD DIARY DATAFRAME
# Each food item with calorie info including foods with food type unit = “count”.
# removed outliers
########################################################################
########################################################################

# remove missing data 
fooddiary_all <- fooddiary_all[complete.cases(fooddiary_all),]

# remove outliers with custom outliers function (found at top of code)
fooddiary_all$calories_total_grams <- outliers(fooddiary_all$calories_total_grams)

# only use recall times of a week
fooddiary <- fooddiary_all %>% filter(recall=="week")

#########
# calculate proportions
#########

# meat
fooddiary <- fooddiary %>% mutate(isMeat = ifelse(food_name_type == "meategg",1,0))
    pct_meat <- fooddiary %>% group_by(hh_ID, week_number) %>% tally(isMeat)
    pct_meat <- pct_meat %>% mutate(numMeat = n) %>% select(-n)
    myfreqs <- fooddiary %>% group_by(hh_ID, week_number) %>% summarise(freq = n())
    pct_meat <- merge(myfreqs, pct_meat, by = c("hh_ID","week_number"))
    pct_meat <- pct_meat %>% mutate(pct_meat = numMeat/freq) %>% select(-numMeat, -freq)

# fish    
fooddiary <- fooddiary %>% mutate(isFish = ifelse(food_name_type == "fishlarge"|food_name_type == "fishsmall",1,0))
    pct_fish <- fooddiary %>% group_by(hh_ID, week_number) %>% tally(isFish)
    pct_fish <- pct_fish %>% mutate(numFish = n) %>% select(-n)
    myfreqs <- fooddiary %>% group_by(hh_ID, week_number) %>% summarise(freq = n())
    pct_fish <- merge(myfreqs, pct_fish, by = c("hh_ID","week_number"))
    pct_fish <- pct_fish %>% mutate(pct_fish = numFish/freq) %>% select(-numFish, -freq)

# protein
fooddiary <- fooddiary %>% mutate(isProtein = ifelse(food_name_type == "fishlarge"|
                                                       food_name_type == "fishsmall"|
                                                       food_name_type == "meategg",1,0))
    pct_protein <- fooddiary %>% group_by(hh_ID, week_number) %>% tally(isProtein)
    pct_protein <- pct_protein %>% mutate(numProtein = n) %>% select(-n)
    myfreqs <- fooddiary %>% group_by(hh_ID, week_number) %>% summarise(freq = n())
    pct_protein <- merge(myfreqs, pct_protein, by = c("hh_ID","week_number"))
    pct_protein <- pct_protein %>% mutate(pct_protein = numProtein/freq) %>% select(-numProtein, -freq)
    
# merge pct findings with fooddiary
fooddiary <- merge(fooddiary, pct_protein, by = c("hh_ID","week_number"))
fooddiary <- merge(fooddiary, pct_fish, by = c("hh_ID","week_number"))
fooddiary <- merge(fooddiary, pct_meat, by = c("hh_ID","week_number"))

#########
## find avg calories per person in each household by food item
#########

fooddiary <- merge(fooddiary, hh_count, by = "hh_ID")
fooddiary <- fooddiary %>% mutate(calories_per_hh_member = calories_total_grams/hh_members)

#########
# find average calories by household
#########

freqs <- fooddiary %>% group_by(hh_ID, week_number) %>% summarise(freq = n())
calories <- fooddiary %>% group_by(hh_ID, week_number) %>% tally(calories_total_grams)
calories <- calories %>% mutate(calories_total = n) %>% select(-n)
hh_calories <- merge(calories, freqs, by = c("hh_ID","week_number"))
hh_calories <- merge(hh_calories, hh_count, by = c("hh_ID"))
hh_calories <- hh_calories %>% mutate(avg_weekly_calories_pp = calories_total/hh_members) 

# remove outliers with custom outliers function 
hh_calories$avg_calories_member <- outliers(hh_calories$avg_calories_member)

#########
# merge calories pp with pct meat, pct fish, pct protein
#########

# weekly data
fooddiary_week <- merge(hh_calories, pct_fish, by =c("hh_ID","week_number"))
fooddiary_week <- merge(fooddiary_week, pct_meat, by =c("hh_ID","week_number"))
fooddiary_week <- merge(fooddiary_week, pct_protein, by =c("hh_ID","week_number"))
fooddiary_week <- merge(fooddiary_week, freqs, by =c("hh_ID","week_number"))
fooddiary_week <- fooddiary_week %>% mutate(num_submissions = freq) %>% select(-freq)

##################
##################
# final dataset with hh information
##################
##################

# averages for the year / no weekly data
# 203 households
temp <- fooddiary_week %>% select(hh_ID, pct_meat, pct_fish, pct_protein, avg_weekly_calories_pp, num_submissions)
temp <- temp %>% group_by(hh_ID) %>% summarise_each(funs(mean, sd, var))

# merge food summary data with hh info 
# 176 households
final_data <- merge(temp, hh_respondent, by = "hh_ID")
final_data$hh_ID <- factor(final_data$hh_ID)

# merge with housing
# 128 households
final_data1 <- merge(final_data, housing, by = "hh_ID")

# merge with nonagricultural_enterprise
# 105 households
final_data2 <- merge(final_data, nonagricultural_enterprise, by = "hh_ID")

# merge with latrine
# 132 households
final_data3 <- merge(final_data, latrine, by = "hh_ID")

# merge with plots
# 132 households
final_data4 <- merge(final_data, plots, by = "hh_ID")

# merge with all
# 73 observations
final_data_all <- merge(final_data, housing, by = "hh_ID")
final_data_all <- merge(final_data_all, nonagricultural_enterprise, by = "hh_ID")
final_data_all <- merge(final_data_all, latrine, by = "hh_ID")
final_data_all <- merge(final_data_all, plots, by = "hh_ID")

# write csvs
write.csv(fooddiary_week, "fooddiary_week.csv")
write.csv(final_data, "final_data.csv")
write.csv(final_data1, "final_data1.csv")
write.csv(final_data2, "final_data2.csv")
write.csv(final_data3, "final_data3.csv")
write.csv(final_data4, "final_data4.csv")
write.csv(final_data_all, "final_data_all.csv")
write.csv(plots, "plots.csv")
write.csv(nonagricultural_enterprise, "nonagricultural_enterprise.csv")
write.csv(latrine, "latrine.csv")
write.csv(housing, "housing.csv")

