import pyreadr
import pandas as pd

data = pyreadr.read_r('/Users/amorgan/Downloads/AgriculturalExtensionServices.RData')

pData = data['table']
