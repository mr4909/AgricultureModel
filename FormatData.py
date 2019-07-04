import pyreadr
import pandas as pd


data = pyreadr.read_r('./Datasets/01.AgriculturalExtensionServices.RData')
agExtServices = data['table']

data = pyreadr.read_r('./Datasets/02.AgriculturalProduction_level_1.RData')
agProdLvl1 = data['table']

data = pyreadr.read_r('./Datasets/03.AgriculturalProduction_plot_repeat_begin_level_2.RData')
agProdLvl2 = data['table']

data = pyreadr.read_r('./Datasets/04.AgriculturalProduction_crop_level_3.RData')
agProdLvl3 = data['table']

data = pyreadr.read_r('./Datasets/05.AgriculturalProduction_group_crop_i_croptype_level_4.RData')
agProdLvl4 = data['table']

data = pyreadr.read_r('./Datasets/06.AgriculturalSubsidyCard.RData')
agSubsidyCard = data['table']

foodDiaryLvl1 = pd.read_stata('./Datasets/33.FoodDiary_level_1.dta')

foodDiaryLvl2 = pd.read_stata('./Datasets/34.FoodDiary_food_level_2.dta')

foodDiaryLvl3 = pd.read_stata('./Datasets/35.Fooddiary_food_foodtype_level_3.dta')

