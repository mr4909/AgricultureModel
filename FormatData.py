import pandas as pd

# agExtServices = pd.read_stata('./Datasets/01.AgriculturalExtensionServices.dta')
# agProdLvl1 = pd.read_stata('./Datasets/02.AgriculturalProduction_level_1.dta')
# agProdLvl2 = pd.read_stata('./Datasets/03.AgriculturalProduction_plot_repeat_begin_level_2.dta')
# agProdLvl3 = pd.read_stata('./Datasets/04.AgriculturalProduction_crop_level_3.dta')
# agProdLvl4 = pd.read_stata('./Datasets/05.AgriculturalProduction_group_crop_i_croptype_level_4.dta')
# agSubsidyCard = pd.read_stata('./Datasets/06.AgriculturalSubsidyCard.dta')

# cropsLvl1 = pd.read_stata('./Datasets/12.Crops_level_1.dta')
# cropsLvl2 = pd.read_stata('./Datasets/13.Crops_plot_repeat_begin_level_2.dta')
# cropsLvl3 = pd.read_stata('./Datasets/14.Crops_crop_level_3.dta')
# cropsLvl4 = pd.read_stata('./Datasets/15.Crops_group_crop_i_croptype_level_4.dta')

hhCompLvl1 = pd.read_stata('./Datasets/HouseholdComposition_level_1.dta')
hhCompLvl2 = pd.read_stata('./Datasets/HouseholdComposition_members_level_2.dta')

fDiaryLvl1 = pd.read_stata('./Datasets/33.FoodDiary_level_1.dta').sort_values(by=['hh_ID']).reset_index(drop=True)
fDiaryLvl2 = pd.read_stata('./Datasets/34.FoodDiary_food_level_2.dta')
fDiaryLvl3 = pd.read_stata('./Datasets/35.Fooddiary_food_foodtype_level_3.dta')
# Reading in the data from stata format into a pandas data frame

fDiaryLvl1.drop(['submissiondate', 'start_time', 'end_time', 'today', 'start_date', 'expiration_date',
                'max_submissions', 'task_value', 'task_length'], axis=1, inplace=True)
fDiaryLvl2.drop(['food_label'], axis=1, inplace=True)
fDiaryLvl3.drop(['food_type_label', 'food_unit_label'], axis=1, inplace=True)
# Removing irrelevant information to this project

fDiary1Link2 = fDiaryLvl1.merge(fDiaryLvl2)
fDiary2Link3 = fDiary1Link2.merge(fDiaryLvl3).sort_values(by=['hh_ID']).reset_index(drop=True)
# Linking the food diary levels using the unique ID numbers

# fDiary2Link3.drop(fDiary2Link3.ix([:,''])
# Deleting a range of columns

foodsList = pd.Series(fDiary2Link3.food_type_name.unique())
# The list of different foods which will be used to calculate calories

groupedIDAndWeek = fDiary2Link3.groupby(['hh_ID', 'week_number'], as_index=False).sum()

householdIDLvl1 = pd.Series(fDiaryLvl1.hh_ID.unique())
householdIDLinked = pd.Series(fDiaryLvl1.hh_ID.unique()).sort_values()
weekNumbers = pd.Series(fDiaryLvl1.week_number.unique()).sort_values()
unitsUsed = pd.Series(fDiaryLvl3.food_type_unit.unique())

responseTest = pd.DataFrame(columns=weekNumbers, index=householdIDLinked)
responseTest = responseTest.fillna(0)
# If there is a hh_ID, find its week number and count that, otherwise there was no response
# Set it so the lvl1 gives a 1, the linked gives a 2, and both of them gives a 3
# Does not work as intended because there are multiple responses per week
for y in fDiaryLvl1.index:
    responseTest.at[fDiaryLvl1.loc[y, 'hh_ID'], fDiaryLvl1.loc[y, 'week_number']] += 1

for x in fDiary2Link3.index:
    responseTest.at[fDiary2Link3.loc[x, 'hh_ID'], fDiary2Link3.loc[x, 'week_number']] += 2

