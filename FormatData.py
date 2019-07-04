import pandas as pd


agExtServices = pd.read_stata('./Datasets/01.AgriculturalExtensionServices.dta')
agProdLvl1 = pd.read_stata('./Datasets/02.AgriculturalProduction_level_1.dta')
agProdLvl2 = pd.read_stata('./Datasets/03.AgriculturalProduction_plot_repeat_begin_level_2.dta')
agProdLvl3 = pd.read_stata('./Datasets/04.AgriculturalProduction_crop_level_3.dta')
agProdLvl4 = pd.read_stata('./Datasets/05.AgriculturalProduction_group_crop_i_croptype_level_4.dta')
agSubsidyCard = pd.read_stata('./Datasets/06.AgriculturalSubsidyCard.dta')

cropsLvl1 = pd.read_stata('./Datasets/12.Crops_level_1.dta')
cropsLvl2 = pd.read_stata('./Datasets/13.Crops_plot_repeat_begin_level_2.dta')
cropsLvl3 = pd.read_stata('./Datasets/14.Crops_crop_level_3.dta')
cropsLvl4 = pd.read_stata('./Datasets/15.Crops_group_crop_i_croptype_level_4.dta')

foodDiaryLvl1 = pd.read_stata('./Datasets/33.FoodDiary_level_1.dta')
foodDiaryLvl2 = pd.read_stata('./Datasets/34.FoodDiary_food_level_2.dta')
foodDiaryLvl3 = pd.read_stata('./Datasets/35.Fooddiary_food_foodtype_level_3.dta')