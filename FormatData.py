import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
from CaloriesConversions import *


def prep_heat_map(original):
    df = pd.DataFrame()
    for z in original.index:
        df.at[original.loc[z, 'hh_ID'], original.loc[z, 'week_number']] = original.loc[z, 'food_type_quant']
    return df.transpose()


def create_heat_map(original):
    df = sns.heatmap(prep_heat_map(original), cmap='PiYG', vmax=500)
    df.set(xlabel='hh_ID', ylabel='week_number')
    return df


# csWeeklyHeat = sns.heatmap(prep_heat_map(cSWeekly), cmap='PiYG', vmax=500)

plt.figure()
cSWeeklyHeat = create_heat_map(cSWeekly)
cSWeeklyHeat.set(title="cSWeekly")

plt.figure()
cSMonthlyHeat = create_heat_map(cSMonthly)
cSMonthlyHeat.set(title='cSMonthly')

plt.figure()
cSSeasonalHeat = create_heat_map(cSSeasonal)
cSSeasonalHeat.set(title='cSSeasonal')

plt.figure()
noCSWeeklyHeat = create_heat_map(noCSWeekly)
noCSWeeklyHeat.set(title='noCSWeekly')

plt.figure()
noCSMonthlyHeat = create_heat_map(noCSMonthly)
noCSMonthlyHeat.set(title='noCSMonthly')

plt.figure()
noCSSeasonalHeat = create_heat_map(noCSSeasonal)
noCSSeasonalHeat.set(title='noCSSeasonal')

plt.show()


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
