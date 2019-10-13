import pandas as pd
import seaborn as sns
from CaloriesConversions import *


"""for i in fDiary2Link3.index:
    for u in hhMemberCount.index:
        if fDiary2Link3.loc[i, 'hh_ID'] == u:
            fDiary2Link3.at[i, 'food_type_quant'] /= u"""


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

sns.heatmap(meatEggGroup, cmap='PiYG', vmax=500)
# plt.show()
# TODO: Look into how the color pallets work
# TODO: Find a way to differentiate between no response and no food in the graphs
# TODO: Normalize the graphs so it is food/person in each household instead of food/household
# Some households may have more people than others, which is why they receive more food


responseTest = pd.DataFrame(columns=weekNumbers, index=householdIDLinked)
responseTest = responseTest.fillna(0)
# If there is a hh_ID, find its week number and count that, otherwise there was no response
# Set it so the lvl1 gives a 1, the linked gives a 2, and both of them gives a 3
# Does not work as intended because there are multiple responses per week
for y in fDiaryLvl1.index:
    responseTest.at[fDiaryLvl1.loc[y, 'hh_ID'], fDiaryLvl1.loc[y, 'week_number']] = 1

for x in fDiary2Link3.index:
    responseTest.at[fDiary2Link3.loc[x, 'hh_ID'], fDiary2Link3.loc[x, 'week_number']] = 2

testCase = pd.DataFrame(fDiaryLvl3[(fDiaryLvl3['hh_ID'] == 222257)])
