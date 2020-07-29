
########################
# Regression Analysis
# by Mari Roberts
########################

# load necessary packages
requiredPackages = c('foreign', # read dta
                     'dplyr', # data manipulation
                     'haven',
                     'gridExtra', # data manipulation
                     'readr', # read files
                     'readxl',# read files
                     'dummies', # PCA
                     'lubridate', # data manipulation
                     'data.table', # data manipulation
                     'FactoMineR', # PCA
                     'factoextra', # PCA
                     'psych', # PCA
                     'nFactors', # PCA
                     'lattice', # plots
                     'glmnet', # lasso
                     'caret', # lasso
                     'ggplot2', # plots
                     'cluster', # clustering
                     'Rtsne', # clustering
                     'lmer', # linear mixed effects model
                     'tidyverse') # missing values using map
# only downloads packages if needed
for(p in requiredPackages){
  if(!require(p,character.only = TRUE)) install.packages(p)
  library(p,character.only = TRUE)
}

# read final data
df <- read_csv("final_data.csv")

# # find yearly average consumption rates for each household 
# # meat
# avg <- df %>% group_by(hh_ID) %>% summarise(freq = n())
# avg <- avg %>% select(hh_ID, weeks=freq)
# avg1 <- df %>% group_by(hh_ID) %>% tally(pct_meat)
# avg <- merge(avg1, avg, by = c("hh_ID"))
# avg <- avg %>% mutate(avg_pct_meat = n/weeks) %>% select(hh_ID, avg_pct_meat)
# df <- merge(df, avg, by = c("hh_ID"))
# 
# # fish
# avg <- df %>% group_by(hh_ID) %>% summarise(freq = n())
# avg <- avg %>% select(hh_ID, weeks=freq)
# avg1 <- df %>% group_by(hh_ID) %>% tally(pct_fish)
# avg <- merge(avg1, avg, by = c("hh_ID"))
# avg <- avg %>% mutate(avg_pct_fish = n/weeks) %>% select(hh_ID, avg_pct_fish)
# df <- merge(df, avg, by = c("hh_ID"))
# 
# # protein
# avg <- df %>% group_by(hh_ID) %>% summarise(freq = n())
# avg <- avg %>% select(hh_ID, weeks=freq)
# avg1 <- df %>% group_by(hh_ID) %>% tally(pct_protein)
# avg <- merge(avg1, avg, by = c("hh_ID"))
# avg <- avg %>% mutate(avg_pct_protein = n/weeks) %>% select(hh_ID, avg_pct_protein)
# df <- merge(df, avg, by = c("hh_ID"))
# 
# # calories
# avg <- df %>% group_by(hh_ID) %>% summarise(freq = n())
# avg <- avg %>% select(hh_ID, weeks=freq)
# avg1 <- df %>% group_by(hh_ID) %>% tally(avg_calories_member)
# avg <- merge(avg1, avg, by = c("hh_ID"))
# avg <- avg %>% mutate(avg_calories_year = n/weeks) %>% select(hh_ID, avg_calories_year)
# df <- merge(df, avg, by = c("hh_ID"))

####################
# mean,var, sd
####################

df <- df %>% select(hh_ID,
                    week_number,
                       numChildren,
                       hh_members,
                       sex,
                       age,
                       maritalStatus,
                       literacy,
                       education,
                       attendingCollege,   
                       occupationType,
                       canCarry20L,
                       canWalk5Km,
                       canStandOwn,
                       pctCanCarry20L,
                       pctCanWalk5Km,
                       pctCanStandOwn,     
                       pct_meat,
                       pct_fish,
                       pct_protein,
                       avg_calories_member)

df_temp <- df %>% select(hh_ID, pct_meat, pct_fish, pct_protein, avg_calories_member)
df_temp <- df_temp %>% group_by(hh_ID) %>% summarise_each(funs(mean, sd, var))
df_temp <- merge(df, df_temp, by = c("hh_ID"))

df_final <- df_temp %>% select(hh_ID,
                                  numChildren,
                                  hh_members,
                                  sex,
                                  age,
                                  maritalStatus,
                                  literacy,
                                  education,
                                  attendingCollege,   
                                  occupationType,
                                  canCarry20L,
                                  canWalk5Km,
                                  canStandOwn,
                                  pctCanCarry20L,
                                  pctCanWalk5Km,
                                  pctCanStandOwn,     
                                  pct_meat_mean,
                                  pct_meat_var,
                                  pct_meat_sd,
                                  pct_fish_mean,
                                  pct_fish_var,
                                  pct_fish_sd,
                                  pct_protein_mean,
                                  pct_protein_var,
                                  pct_protein_sd,
                                  avg_calories_member_mean,
                                  avg_calories_member_var,
                                  avg_calories_member_sd) 

df_final <- df_final %>% distinct()

# factor variables
str(df_final)
df_final$hh_ID <- factor(df_final$hh_ID)
df_final$sex <- factor(df_final$sex)
df_final$maritalStatus <- factor(df_final$maritalStatus)
df_final$literacy <- factor(df_final$literacy)
df_final$education <- factor(df_final$education)
df_final$attendingCollege <- factor(df_final$attendingCollege)
df_final$occupationType <- factor(df_final$occupationType)
df_final$canCarry20L <- factor(df_final$canCarry20L)
df_final$canStandOwn <- factor(df_final$canStandOwn)
df_final$canWalk5Km <- factor(df_final$canWalk5Km)

########################################
# Regression  
########################################

# generate variable ====== average for the year, and then within responses and variation 
# frac family that can --health-- 
# avg meat and variation in calories -- 
# variation - within subject variation along year of protein and calories
# mean calorie and variation

# no significant findings from pct_protein_var, pct_meat_var, pct_fish_var
# summary(ols <- lm(pctCanWalk5Km ~ pct_protein_var, data = df_final))
# summary(ols <- lm(canCarry20L ~ pct_fish_var, data = df_final))
# summary(ols <- lm(canStandOwn ~ pct_meat_var, data = df_final))

summary(ols <- lm(pctCanWalk5Km ~ pct_protein_var, data = df_final))

summary(ols <- lm(pct_meat_var ~ numChildren + hh_members + sex + age + maritalStatus + literacy +
                    education + attendingCollege + occupationType + canCarry20L + canWalk5Km +
                    canStandOwn + pctCanCarry20L + pctCanWalk5Km + pctCanStandOwn, data = df_final))

########################################

#basic linear model
fit.1<-glm(pct_meat_var ~ numChildren + hh_members + sex + age + maritalStatus + literacy +
             education + attendingCollege + occupationType + canCarry20L + canWalk5Km +
             canStandOwn + pctCanCarry20L + pctCanWalk5Km + pctCanStandOwn, data=df_final)
summary(fit.1)

#random intercept model for individual differences
fit.2<-lmer(pct_meat_var ~ numChildren + hh_members + sex + age + maritalStatus + literacy +
              education + attendingCollege + occupationType + canCarry20L + canWalk5Km +
              canStandOwn + pctCanCarry20L + pctCanWalk5Km + pctCanStandOwn +(1|hh_ID), data=df_final)
summary(fit.2)

# #individual trajectory model with random slope for time
# fit.3<-lmer(avg_calories_member ~ numChildren + hh_members + sex + age + maritalStatus + literacy +
#               education + attendingCollege + occupationType + canCarry20L + canWalk5Km +
#               canStandOwn + pctCanCarry20L + pctCanWalk5Km + pctCanStandOwn + week_number +(week_number|hh_ID), data=df_final)
# summary(fit.3)
# anova(fit.3, fit.2)
# 
# #curvilinear trajectory model with random nonlinear time
# fit.4<-lmer(avg_calories_member ~ numChildren + hh_members + sex + age + maritalStatus + literacy +
#               education + attendingCollege + occupationType + canCarry20L + canWalk5Km +
#               canStandOwn + pctCanCarry20L + pctCanWalk5Km + pctCanStandOwn + week_number+I(week_number^2)+(week_number+I(week_number^2)|hh_ID), data=df_final)
# summary(fit.4)
# anova(fit.4, fit.3)
# 
# #individual trajectory model with fixed effects 
# fit.5<-lmer(avg_calories_member ~ week_number*(numChildren + hh_members + sex + age + maritalStatus + literacy +
#                                                  education + attendingCollege + occupationType + canCarry20L + canWalk5Km +
#                                                  canStandOwn + pctCanCarry20L + pctCanWalk5Km + pctCanStandOwn)+(week_number|hh_ID), data=df_final)
# summary(fit.5)
# anova(fit.4, fit.5)

AIC(fit.1)
AIC(fit.2)
# AIC(fit.3)
# AIC(fit.4)
# AIC(fit.5) 

