import pandas as pd
from FormatData import foodsList

foodsList.to_excel('FoodCalories.xlsx')

foodsCalories = pd.read_excel('FoodCalories.xlsx', sheet_name='Sheet1')