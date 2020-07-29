
##################################################################
# Regression Analysis
# by Mari Roberts
##################################################################

df_all <- read_csv("final_data.csv")
# remove unwanted variables

summary(ols <- lm(pct_meat ~ numChildren + hh_members + sex + age + maritalStatus + literacy +
                    education + attendingCollege + occupationType + canCarry20L + canWalk5Km +
                    canStandOwn + pctCanCarry20L + pctCanWalk5Km + pctCanStandOwn, data = df_all))

summary(ols <- lm(pctCanStandOwn ~ pct_protein, data = df_all))

# generate variable ====== average for the year, and then within responses and variation 
# frac family that can --health-- 
# avg meat and variation in calories -- 
# variation - within subject variation along year of protein and calories
# mean calorie and variation

# look at illness data NOT ENOUGH
# illness <- `85. illness_level_1.dta` %>% filter(crowdsource==0 & recall=="week") 
# illness <- illness %>% dplyr::select(hh_ID, 
#                               week_number, 
#                               illness_status)
# df <- merge(df_all, illness, by = c("hh_ID", "week_number"))
# # unique(df$hh_ID) #45 only

# factor variables
str(df)
df$hh_ID <- factor(df$hh_ID)
df$cluster <- factor(df$cluster)
df$week_number <- factor(df$week_number)
df$sex <- factor(df$sex)
df$maritalStatus <- factor(df$maritalStatus)
df$literacy <- factor(df$literacy)
df$education <- factor(df$education)
df$attendingCollege <- factor(df$attendingCollege)
df$occupationType <- factor(df$occupationType)
df$year <- factor(df$year)
df$month_num <- factor(df$month_num)

m <- lmer(avg_calories_member ~ numChildren + hh_members + sex + age + maritalStatus + literacy +
            education + attendingCollege + occupationType + canCarry20L + canWalk5Km +
            canStandOwn + pctCanCarry20L + pctCanWalk5Km + pctCanStandOwn + week_number_f + (1 | hh_ID), data=df_all)
summary(m)

head(df)

xyplot(avg_calories_member~pct_meat|canCarry20L, data=df_all,
       panel=function(x,y){
         panel.xyplot(x,y)
         panel.lmline(x,y,)})
xyplot(avg_calories_member~pct_meat|canWalk5Km, data=df_all,
       panel=function(x,y){
         panel.xyplot(x,y)
         panel.lmline(x,y,)})
xyplot(avg_calories_member~pct_meat|canStandOwn, data=df_all,
       panel=function(x,y){
         panel.xyplot(x,y)
         panel.lmline(x,y,)})

#basic linear model
fit.1<-glm(avg_calories_member ~ numChildren + hh_members + sex + age + maritalStatus + literacy +
             education + attendingCollege + occupationType + canCarry20L + canWalk5Km +
             canStandOwn + pctCanCarry20L + pctCanWalk5Km + pctCanStandOwn + week_number, data=df_all)
summary(fit.1)

#random intercept model for individual hh differences
fit.2<-lmer(avg_calories_member ~ numChildren + hh_members + sex + age + maritalStatus + literacy +
              education + attendingCollege + occupationType + canCarry20L + canWalk5Km +
              canStandOwn + pctCanCarry20L + pctCanWalk5Km + pctCanStandOwn + week_number +(1|hh_ID), data=df_all)
summary(fit.2)

#individual trajectory model with random slope for time
fit.3<-lmer(avg_calories_member ~ numChildren + hh_members + sex + age + maritalStatus + literacy +
              education + attendingCollege + occupationType + canCarry20L + canWalk5Km +
              canStandOwn + pctCanCarry20L + pctCanWalk5Km + pctCanStandOwn + week_number +(week_number|hh_ID), data=df_all)
summary(fit.3)
anova(fit.3, fit.2)

#curvilinear trajectory model with random nonlinear time
fit.4<-lmer(avg_calories_member ~ numChildren + hh_members + sex + age + maritalStatus + literacy +
              education + attendingCollege + occupationType + canCarry20L + canWalk5Km +
              canStandOwn + pctCanCarry20L + pctCanWalk5Km + pctCanStandOwn + week_number+I(week_number^2)+(week_number+I(week_number^2)|hh_ID), data=df_all)
summary(fit.4)
anova(fit.4, fit.3)

#individual trajectory model with fixed effects 
fit.5<-lmer(avg_calories_member ~ week_number*(numChildren + hh_members + sex + age + maritalStatus + literacy +
                                                 education + attendingCollege + occupationType + canCarry20L + canWalk5Km +
                                                 canStandOwn + pctCanCarry20L + pctCanWalk5Km + pctCanStandOwn)+(week_number|hh_ID), data=df_all)
summary(fit.5)
anova(fit.4, fit.5)

AIC(fit.1)
AIC(fit.2)
AIC(fit.3)
AIC(fit.4)
AIC(fit.5) # best fit
# https://rpubs.com/corey_sparks/32835

# Examples of confounding factors
# • Biological
# • Time of day (e.g. alertness, metabolism activity)
# • Day of week (e.g. stress, alcohol usage, cardiovascular diseases)
# • Season (e.g. vitamin D levels, body weight)
