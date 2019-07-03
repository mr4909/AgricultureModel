import pyreadr
import pandas as pd

data = pyreadr.read_r('/Users/amorgan/Documents/AgricultureModel/Datasets/01.AgriculturalExtensionServices.RData')
agExtServices = data['table']

data = pyreadr.read_r('/Users/amorgan/Documents/AgricultureModel/Datasets/02.AgriculturalProduction_level_1.RData')
agProdLvl1 = data['table']

data = pyreadr.read_r('/Users/amorgan/Documents/AgricultureModel/Datasets/'
                      '03.AgriculturalProduction_plot_repeat_begin_level_2.RData')
agProdLvl2 = data['table']

data = pyreadr.read_r('/Users/amorgan/Documents/AgricultureModel/Datasets/04.AgriculturalProduction_crop_level_3.RData')
agProdLvl3 = data['table']

data = pyreadr.read_r('/Users/amorgan/Documents/AgricultureModel/Datasets/'
                      '05.AgriculturalProduction_group_crop_i_croptype_level_4.RData')
agProdLvl4 = data['table']

data = pyreadr.read_r('/Users/amorgan/Documents/AgricultureModel/Datasets/06.AgriculturalSubsidyCard.RData')
agSubsidyCard = data['table']
