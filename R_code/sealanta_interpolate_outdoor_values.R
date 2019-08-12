
library(tidyverse)
library(readxl)
library(rstan)
library(lubridate)
library(stringr)

read_csv(file = '../data/sealanta_FL_ambient_conditions.csv',
         skip = 0, col_names = TRUE) -> ambient_conditions

all_date_time <- tibble(date_time = seq(first(ambient_conditions$date_time), last(ambient_conditions$date_time), by = '1 hour'))
all_date_time <- mutate(all_date_time,
                        hour_of_day = hour(date_time))

ambient_conditions <- left_join(all_date_time, ambient_conditions, by = 'date_time')

predFun <- function(y, date_time) {
  predict(lm(y ~ poly(date_time, deg = 5)),
          newdata = data.frame(date_time = date_time))
}
residFun <- function(y, date_time) {
  residuals(lm(y ~ poly(date_time, deg = 5), na.action = na.exclude))
}

ambient_conditions <- mutate(group_by(ambient_conditions, hour_of_day),
                             pred_temp = predFun(temp, date_time),
                             resid_temp = residFun(temp, date_time),
                             pred_strain = predFun(strain, date_time),
                             resid_strain = residFun(strain, date_time),
                             pred_dose = predFun(dose, date_time),
                             resid_dose = residFun(dose, date_time))
ambient_conditions <- ungroup(ambient_conditions)

ambient_conditions <- mutate(ambient_conditions,
                             temp_use = ifelse(is.na(temp), pred_temp, temp),
                             strain_use = ifelse(is.na(strain), pred_strain, strain),
                             dose_use = pmax((ifelse(is.na(dose), pred_dose, dose)), 0))

write_csv(ambient_conditions, '../data/sealanta_FL_ambient_conditions_after_interp.csv')

ggplot(data = ambient_conditions,
       mapping = aes(x = date_time, y = temp)) +
  geom_line() +
  geom_line(mapping = aes(y = pred_temp), color = 'red') +
  facet_wrap(~hour_of_day, labeller = 'label_both')

ggplot(data = ambient_conditions,
       mapping = aes(x = date_time, y = dose)) +
  geom_line() +
  geom_line(mapping = aes(y = pred_dose), color = 'red') +
  facet_wrap(~hour_of_day, labeller = 'label_both')

ggplot(data = ambient_conditions,
       mapping = aes(x = date_time, y = strain)) +
  geom_line() +
  geom_line(mapping = aes(y = pred_strain), color = 'red') +
  facet_wrap(~hour_of_day, labeller = 'label_both')

ggplot(data = ambient_conditions,
       mapping = aes(x = date_time, y = resid_temp)) +
  geom_point() +
  geom_hline(yintercept = 0, color = 'red') +
  facet_wrap(~hour_of_day)

ggplot(data = ambient_conditions,
       mapping = aes(x = date_time, y = resid_dose)) +
  geom_point() +
  geom_hline(yintercept = 0, color = 'red') +
  facet_wrap(~hour_of_day)

ggplot(data = ambient_conditions,
       mapping = aes(x = date_time, y = resid_strain)) +
  geom_point() +
  geom_hline(yintercept = 0, color = 'red') +
  facet_wrap(~hour_of_day)

ggplot(data = ambient_conditions,
       mapping = aes(x = date_time, y = temp_use)) +
  geom_line() +
  geom_line(mapping = aes(y = temp), color = 'red')

ggplot(data = ambient_conditions,
       mapping = aes(x = date_time, y = dose_use)) +
  geom_line() +
  geom_line(mapping = aes(y = dose), color = 'red')

ggplot(data = ambient_conditions,
       mapping = aes(x = date_time, y = strain_use)) +
  geom_line() +
  geom_line(mapping = aes(y = strain), color = 'red')

