import pandas as pd

hhCompLvl1 = pd.read_stata('./Datasets/HouseholdComposition_level_1.dta')
hhCompLvl2 = pd.read_stata('./Datasets/HouseholdComposition_members_level_2.dta')

fDiaryLvl1 = pd.read_stata('./Datasets/33.FoodDiary_level_1.dta').sort_values(by=['hh_ID']).reset_index(drop=True)
fDiaryLvl2 = pd.read_stata('./Datasets/34.FoodDiary_food_level_2.dta').sort_values(by=['hh_ID', 'food_1_ID',
                                                                                       'food_2_ID'])
fDiaryLvl3 = pd.read_stata('./Datasets/35.Fooddiary_food_foodtype_level_3.dta')
# Reading in the data from stata format into a pandas data frame

fDiaryLvl1.drop(['submissiondate', 'start_time', 'end_time', 'today', 'start_date', 'expiration_date',
                'max_submissions', 'task_value', 'task_length'], axis=1, inplace=True)
fDiaryLvl2.drop(['food_label'], axis=1, inplace=True)
fDiaryLvl3.drop(['food_type_label', 'food_unit_label'], axis=1, inplace=True)
# Removing irrelevant information to this project

fDiary1Link2 = fDiaryLvl1.merge(fDiaryLvl2)
fDiary2Link3 = fDiary1Link2.merge(fDiaryLvl3).sort_values(by=['hh_ID', 'week_number']).reset_index(drop=True)
# Linking the food diary levels using the unique ID numbers

# fDiary2Link3.drop(fDiary2Link3.ix([:,''])
# Deleting a range of columns


householdIDLinked = pd.Series(fDiaryLvl1.hh_ID.unique()).sort_values()
weekNumbers = pd.Series(fDiaryLvl1.week_number.unique()).sort_values()
unitsUsed = pd.Series(fDiaryLvl3.food_type_unit.unique())
foodsList = pd.DataFrame(fDiary2Link3.food_type_name.unique(), columns=['food_type'])
# The list of different foods which will be used to calculate calories
foodGroups = pd.Series(fDiary2Link3.food_grp_namec.unique())
foodsCalories = pd.read_excel('FoodCalories.xlsx', sheet_name='Sheet1')
# Calories for each food
foodsCalories = foodsCalories.set_index(foodsCalories['food_type']).fillna(0).drop(columns=['Unnamed: 0', 'food_type'])
missingCalories = foodsCalories[foodsCalories.calories == 0]

foodGroupsHousehold = pd.DataFrame(columns=weekNumbers, index=householdIDLinked)
foodGroupsHousehold = foodGroupsHousehold.fillna(0)
grpFDiary2Link3 = fDiary2Link3.groupby(['hh_ID', 'food_grp_namec', 'week_number'], as_index=False).sum()
# Adds the amount of food for each food group by week and hh_ID

# Unit conversions - TODO: How to make this more efficient?
for x in fDiary2Link3.index:
    if fDiary2Link3.loc[x, 'food_type_unit'] == 'Kg':
        fDiary2Link3.loc[x, 'food_type_quant'] *= 1000
    elif fDiary2Link3.loc[x, 'food_type_unit'] == 'Count':
        fDiary2Link3.loc[x, 'food_type_quant'] *= 0.1
        # Hard to determine what this conversion should be
    elif fDiary2Link3.loc[x, 'food_type_unit'] == 'Teaspoon':
        fDiary2Link3.loc[x, 'food_type_quant'] /= 4
    elif fDiary2Link3.loc[x, 'food_type_unit'] == 'Drops':
        fDiary2Link3.loc[x, 'food_type_quant'] *= 4
    elif fDiary2Link3.loc[x, 'food_type_unit'] == 'Tablespoon':
        fDiary2Link3.loc[x, 'food_type_quant'] *= 12
    elif fDiary2Link3.loc[x, 'food_type_unit'] == 'Liter':
        fDiary2Link3.loc[x, 'food_type_quant'] *= 1000
    elif fDiary2Link3.loc[x, 'food_type_unit'] == 'Milliliter':
        fDiary2Link3.loc[x, 'food_type_quant'] *= 1

fDiary2Link3.food_type_unit = 'Grams'

hhMemberCount = hhCompLvl2[['hh_ID', 'member_1_ID']].set_index('hh_ID').groupby('hh_ID').count()

mask = fDiary2Link3.crowdsource == 'Yes'
crowdSource = fDiary2Link3[mask]
noCrowdSource = fDiary2Link3[~mask]

cSWeekly = crowdSource[crowdSource.recall == 'week']
cSMonthly = crowdSource[crowdSource.recall == 'month']
cSSeasonal = crowdSource[crowdSource.recall == 'season']

noCSWeekly = noCrowdSource[noCrowdSource.recall == 'week']
noCSMonthly = noCrowdSource[noCrowdSource.recall == 'month']
noCSSeasonal = noCrowdSource[noCrowdSource.recall == 'season']


def food_group_sums(food_group, df):
    for z in grpFDiary2Link3.index:
        if grpFDiary2Link3.loc[z, 'food_grp_namec'] == food_group:
            df.at[grpFDiary2Link3.loc[z, 'hh_ID'], grpFDiary2Link3.loc[z, 'week_number']] =\
                grpFDiary2Link3.loc[z, 'food_type_quant']
# Sums the amount of each food by food group per week


meatEggGroup = pd.DataFrame()
food_group_sums('meategg', meatEggGroup)
meatEggGroup = meatEggGroup.sort_index(axis=1).transpose()
vegetablesGroup = pd.DataFrame()
food_group_sums('vegetables', vegetablesGroup)
vegetablesGroup = vegetablesGroup.sort_index(axis=1).transpose()
dairyGroup = pd.DataFrame()
food_group_sums('dairy', dairyGroup)
dairyGroup = dairyGroup.sort_index(axis=1).transpose()
