
library(lme4)
library(Matrix)
library(ggplot2)
library(stats)
options(contrasts = c("contr.treatment", "contr.poly"))
library(lmerTest)
library(lmtest)
library(car)
library(MASS)





# Mixed effrcts models(example)
data_test <- data("Machines", package = "nlme")
Machines[, "Worker"] <- factor(Machines[, "Worker"], levels = 1:6, ordered = FALSE)
str(Machines, give.attr = FALSE) ## give.attr in order to shorten output

ggplot(Machines, aes(x = Machine, y = score, group = Worker, col = Worker)) + 
  geom_point() + stat_summary(fun.y = mean, geom = "line")

## classical interaction plot would be 
with(Machines, interaction.plot(x.factor = Machine, trace.factor = Worker, 
                                response = score))
fit <- lmer(score ~ Machine + (1 | Worker) + (1 | Worker:Machine), data = Machines)
anova(fit)
summary(fit)



# One way ANOVA

v13141 <- read.csv("C:/Users/chenq/Desktop/working/AB_test/1131141.csv")
attach(v13141)
#tail(v13141)
#head(v13141)
# typeof(v13141)
version <- as.factor(app_version)
ggplot(v13141, aes(x = version, y = reward, group = app_version, col = app_version)) + 
  geom_point() + stat_summary(fun.y = mean, geom = "line")

ggplot(v13141, aes(x = version, y = inter, group = app_version, col = app_version)) + 
  geom_point() + stat_summary(fun.y = mean, geom = "line")

ggplot(v13141, aes(x = version, y = total, group = app_version, col = app_version)) + 
  geom_point() + stat_summary(fun.y = mean, geom = "line")
# boxplot
boxplot(reward ~ app_version, data = v13141)
boxplot(reward ~ app_version, data = v13141[which(v13141$reward >= 30), ])
boxplot(reward ~ app_version, data = v13141[which(v13141$reward < 30), ])

# model
model13141 <- aov(reward ~ app_version, data = v13141[which(v13141$reward < 2), ])
anova(model13141)
# summary(model1314)
confint(model13141)

model13141 <- aov(inter ~ app_version, data = v13141)
anova(model13141)
# summary(model1314)
confint(model13141)

model13141 <- aov(total ~ app_version, data = v13141)
anova(model13141)
# summary(model1314)
confint(model13141)

# Residual Analysis 
qqnorm(resid(model13141), main = "Residuals")
dwtest(model13141)
leveneTest(reward ~ app_version, v13141)

# box-cox
res <- boxcox(aov(reward ~ app_version, data = v13141), optimize = TRUE, objective.name = "Log-Likelihood", plotit = TRUE)
lambda <- res$x # lambda values
lik <- res$y # log likelihood values for SSE
bc <- cbind(lambda, lik) # combine lambda and lik
sorted_bc <- bc[order(-lik),] # values are sorted to identify the lambda value for the maximum log likelihood for obtaining minimum SSE
head(sorted_bc, n = 10)

# ln model 
lnmodel13141 <- aov((reward^(-0.1) -1)/-0.1 ~ app_version, data = v13141)
anova(lnmodel13141)
confint(lnmodel13141)

# Residual Analysis 
qqnorm(resid(lnmodel13141), main = "Residuals")

std <- sqrt(length(resid(lnmodel13141))/(length(resid(lnmodel13141)) - 1)*var(resid(lnmodel13141)))
ks.test(resid(lnmodel13141)/std, "pnorm", 0, 1)
shapiro.test(resid(lnmodel13141))
dwtest(model13141)
leveneTest(reward ~ app_version, v13141)

# Non parametric test 
wilcox.test(reward ~ app_version, v13141)
wilcox.test(inter ~ app_version, v13141)
wilcox.test(total ~ app_version, v13141)








# model with small small sample
model131430 <- aov(count ~ app_version, data = v1314[which(v1314$count <=30  & v1314$count > 3 ), ])
anova(model131430)
# summary(model1314)
confint(model131430)

# Residual Analysis 
qqnorm(resid(model131430), main = "Residuals")
dwtest(model131430)
leveneTest(count ~ app_version, v1314[which(v1314$count < 30), ])

# ln model 
lnmodel131430 <- aov(log(count) ~ app_version, data = v1314[which(v1314$count < 30), ])
anova(lnmodel131430)
# summary(lnmodel1314)
confint(lnmodel131430)

# Residual Analysis 
qqnorm(resid(lnmodel131430), main = "Residuals")
dwtest(lnmodel131430)
leveneTest(count ~ app_version, v1314[which(v1314$count < 30), ])

# Non parametric test 
wilcox.test(count ~ app_version, v1314[which(v1314$count < 30), ])

wilcox.test(count ~ app_version, v1314[which(v1314$count >= 30), ])

# Can not get sample randomly!!! ???

model1314300 <- aov(count ~ app_version, data = v1314[which(v1314$count <= 1), ])
anova(model1314300)
# summary(model1314300)
confint(model1314300)

# Residual Analysis 

hist(resid(model1314), xlim = c(-100,100))


qqnorm(resid(model1314300) - 1, main = "Residuals")
dwtest(model1314300)
leveneTest(count ~ app_version, v1314[which(v1314$count >= 30), ])

n <- min(resid(model1314))
hist(resid(model1314) - n)
ks.test(resid(model1314) - n, "ppois", 11)


# Mixed effrcts models(for media_source)

WOR_ED_1F1R <- read.csv(file = "C:/Users/chenq/Desktop/mpmf_人均_ad_reward_20210308-20210314.csv")
attach(WOR_ED_1F1R)
tail(WOR_ED_1F1R)
head(WOR_ED_1F1R)
typeof(WOR_ED_1F1R)
# WOR_ED_1F1R['version'] 
version <- as.factor(version)
media_source <- as.factor(media_source)

ggplot(WOR_ED_1F1R, aes(x = version, y = value, group = media_source, col = media_source)) + 
  geom_point() + stat_summary(fun.y = mean, geom = "line")

with(WOR_ED_1F1R, interaction.plot(x.factor = version, trace.factor = media_source, 
                                response = value))


mix_eff_model <- lmer(value ~ version + (1|media_source) + (1|media_source:version), data = WOR_ED_1F1R)

anova(mix_eff_model)
summary(mix_eff_model)
fixef(mix_eff_model)
confint(mix_eff_model, oldNames = FALSE)



# Tukey-Anscombe plot: 
plot(mix_eff_model)


## QQ-plots:
par(mfrow = c(1, 3))
qqnorm(ranef(mix_eff_model)$media_source[, 1], main = "Random effects of media_source")
qqnorm(ranef(mix_eff_model)$'media_source:version'[, 1], main = "Random interaction")
qqnorm(resid(mix_eff_model), main = "Residuals")

### media_source is a fixed effect but not random effect.  


mix_eff_model.fixed <- aov(value ~ version * media_source, data = WOR_ED_1F1R) # fixed effects model. 
summary(mix_eff_model.fixed)
coefficients(mix_eff_model.fixed)
par(mfrow = c(2, 2))
plot(mix_eff_model.fixed)

qqnorm(mix_eff_model.fixed$res)
qqline(mix_eff_model.fixed$res)

plot(mix_eff_model.fixed$fit,mix_eff_model.fixed$res,xlab="Ajuested Values",ylab="Residuals",
     main="residuals with levels")
abline(h=0,lty=2)

# Verify residuals that complete hypotesis

plot(fitted.values(mix_eff_model.fixed),rstandard(mix_eff_model.fixed),
     xlab="Ajuested Values", ylab="standerlized residuals",pch=20)

plot(jitter(mix_eff_model.fixed$fit),mix_eff_model.fixed$res,xlab="Fitted",ylab="Residuos",
     main="Jittered Graph")

# no parametric test Kruskal-wallis
krus <- kruskal.test(value, version)
krus



# LSD test

n1 <- sum(mix_eff_model.fixed$model$version == "v0.9")
n4 <- sum(mix_eff_model.fixed$model$version=="v1")
s <- sqrt(sum((mix_eff_model.fixed$residuals)^2)/mix_eff_model.fixed$df.residual)
tcrit <- qt(0.025, mix_eff_model.fixed$df.residual, lower.tail=F)
LSD <- tcrit*s*sqrt((1/n1)+(1/n4))
LSD


# Bonferroni method
pairwise.t.test(value, version, p.adjust.method = "bonferroni")

# Tukey test
Tukey_method <- TukeyHSD(mix_eff_model.fixed)

par(mfrow = c(1, 1))
plot(Tukey_method)



# Contrasts and Multiple Testing

# -conservative  LSD, Duncan, Newman-Keuls, Tukey, Bonferroni   +conservative





# Mixed effects Nesting model(for campaign) -----> staggered nested design

WOR_ED_1F1R <- read.csv(file = "C:/Users/chenq/Desktop/mpmf_ad_reward的人均次数_20210308-20210314.csv")
attach(WOR_ED_1F1R)
tail(WOR_ED_1F1R)
head(WOR_ED_1F1R)
typeof(WOR_ED_1F1R)
    # WOR_ED_1F1R['ï..version'] 
ï..version <- as.factor(ï..version)
media_source <- as.factor(media_source)

ggplot(WOR_ED_1F1R, aes(x = ï..version, y = one, group = media_source, col = media_source)) + 
  geom_point() + stat_summary(fun.y = mean, geom = "line")


par(mfrow = c(2, 1))
stripchart(one ~ ï..version, vertical = TRUE, pch = 1, xlab = "ï..version", data = WOR_ED_1F1R, main = "diffrent version")
stripchart(one ~ media_source, vertical = TRUE, pch = 1, xlab = "ï..version", data = WOR_ED_1F1R, main = "diffrent media source")

model_one <- lmer(one ~ ï..version + ï..version/(1|media_source), data = WOR_ED_1F1R)
anova(model_one)

summary(model_one)
fixef(model_one) # Get the parameter estimates of the fixed effects
confint(model_one, oldNames = FALSE)
ranef(model_one) # ## "estimated" (better: conditional means of) random effects
plot(model_one) # Tukey-Anscombe plot:

par(mfrow = c(1, 2))
qqnorm(ranef(model_one)$media_source[, "(Intercept)"], main = "Random effects")
qqnorm(resid(model_one), main = "Residuals")



# sum 

ggplot(WOR_ED_1F1R, aes(x = ï..version, y = sum, group = media_source, col = media_source)) + 
  geom_point() + stat_summary(fun.y = mean, geom = "line")


model_sum <- lmer(sum ~ ï..version + ï..version/(1|media_source), data = WOR_ED_1F1R)
anova(model_sum)

summary(model_sum)
fixef(model_sum) # Get the parameter estimates of the fixed effects
confint(model_sum, oldNames = FALSE)
ranef(model_sum) # ## "estimated" (better: conditional means of) random effects
plot(model_sum) # Tukey-Anscombe plot:

par(mfrow = c(1, 2))
qqnorm(ranef(model_sum)$media_source[, "(Intercept)"], main = "Random effects")
qqnorm(resid(model_sum), main = "Residuals")

# reduce factor level. 


# generate nested model with aov() function 
model_one_aov <- aov(one ~ ï..version + /Error(media_source), data = WOR_ED_1F1R)





