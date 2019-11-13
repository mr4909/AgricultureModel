import pandas as pd
import seaborn as sns
from CaloriesConversions import *


#fDiary2Link3.set_index('food_type_quant').mul(foodsCalories.reindex(fDiary2Link3['food_type_name'])['calories'], axis=0).reset_index()
#fDiary2Link3.assign(food_type_quant=fDiary2Link3.food_type_quant*(foodsCalories['calories'].reindex(fDiary2Link3.food_type_name).values))
fDiary2Link3 = fDiary2Link3.assign(food_type_quant=fDiary2Link3.food_type_quant*fDiary2Link3.food_type_name.map(foodsCalories['calories']))
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
