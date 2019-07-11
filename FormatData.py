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

fDiaryLvl1 = pd.read_stata('./Datasets/33.FoodDiary_level_1.dta')
fDiaryLvl2 = pd.read_stata('./Datasets/34.FoodDiary_food_level_2.dta')
fDiaryLvl3 = pd.read_stata('./Datasets/35.Fooddiary_food_foodtype_level_3.dta')

fDiaryLvl1.drop(['submissiondate', 'start_time', 'end_time', 'today', 'start_date', 'expiration_date',
                    'max_submissions', 'task_value', 'task_length'], axis=1, inplace=True)
fDiaryLvl2.drop(['food_label'], axis=1, inplace=True)
fDiaryLvl3.drop(['food_type_label', 'food_unit_label'], axis=1, inplace=True)

fDiary1Link2 = pd.merge(fDiaryLvl1, fDiaryLvl2)
fDiary2Link3 = pd.merge(fDiary1Link2, fDiaryLvl3)
