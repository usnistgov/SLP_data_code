library(tidyverse)
library(readxl)
library(rstan)
library(lubridate)
library(stringr)

read_excel(path = '../data/PE_Florida_ambient_plus_panel_temps.xlsx',
                                 skip = 1, col_names = FALSE) %>%
  select(X__1, X__2, X__4, X__7, X__10) %>%
  rename(date = X__1, time = X__2, intensity = X__4, temp = X__7, panel_temp = X__10) -> ambient_conditions

ambient_conditions <- mutate(ambient_conditions,
                             date_time = ymd_hms(paste(date, str_sub(time, start = 12, end = 20))))
ambient_conditions <- select(ambient_conditions,
                             intensity, panel_temp, date_time, temp)
ambient_conditions <- mutate(ambient_conditions,
                             dose = intensity*60/1e6,
                             panel_temp = 0.1*(panel_temp - 30) - 1) -> ambient_conditions


all_date_time <- tibble(date_time = seq(first(ambient_conditions$date_time), last(ambient_conditions$date_time), by = '1 hour'))
all_date_time <- mutate(all_date_time,
                        hour_of_day = hour(date_time))

ambient_conditions <- left_join(all_date_time, ambient_conditions, by = 'date_time')

predFun <- function(y, date_time) {
  predict(lm(y ~ poly(date_time, deg = 3)),
          newdata = data.frame(date_time = date_time))
}
residFun <- function(y, date_time) {
  residuals(lm(y ~ poly(date_time, deg = 3), na.action = na.exclude))
}

ambient_conditions <- mutate(group_by(ambient_conditions, hour_of_day),
                             pred_panel_temp = predFun(panel_temp, date_time),
                             resid_panel_temp = residFun(panel_temp, date_time),
                             pred_dose = predFun(dose, date_time),
                             resid_dose = residFun(dose, date_time))
ambient_conditions <- ungroup(ambient_conditions)

ambient_conditions <- mutate(ambient_conditions,
                             panel_temp_use = ifelse(is.na(panel_temp), pred_panel_temp, panel_temp),
                             dose_use = pmax((ifelse(is.na(dose), pred_dose, dose)), 0))

write_csv(ambient_conditions, '../data/PE_FL_ambient_conditions_after_interp.csv')

ggplot(data = ambient_conditions,
       mapping = aes(x = date_time, y = panel_temp)) +
  geom_line() +
  geom_line(mapping = aes(y = pred_panel_temp), color = 'red') +
  facet_wrap(~hour_of_day, labeller = 'label_both')

ggplot(data = ambient_conditions,
       mapping = aes(x = date_time, y = dose)) +
  geom_line() +
  geom_line(mapping = aes(y = pred_dose), color = 'red') +
  facet_wrap(~hour_of_day, labeller = 'label_both')

ggplot(data = ambient_conditions,
       mapping = aes(x = date_time, y = resid_panel_temp)) +
  geom_point() +
  geom_hline(yintercept = 0, color = 'red') +
  facet_wrap(~hour_of_day)

ggplot(data = ambient_conditions,
       mapping = aes(x = date_time, y = resid_dose)) +
  geom_point() +
  geom_hline(yintercept = 0, color = 'red') +
  facet_wrap(~hour_of_day)

ggplot(data = ambient_conditions,
       mapping = aes(x = date_time, y = panel_temp_use)) +
  geom_line() +
  geom_line(mapping = aes(y = panel_temp), color = 'red')

ggplot(data = ambient_conditions,
       mapping = aes(x = date_time, y = dose_use)) +
  geom_line()
