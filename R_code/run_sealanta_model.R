
library(tidyverse)
library(rstan)

read_csv('../data/sealanta_indoor_data.csv') %>%
  mutate(UV = as.factor(round(UV*100)),
         lmod = log(Modulus),
         Run = as.numeric(as.factor(Run))) -> raw_data

run_first_obs <- do(group_by(raw_data, Run), .[1, ])

strain <- (2/(max(raw_data$Strain) - min(raw_data$Strain))) *
  (run_first_obs$Strain - min(raw_data$Strain)) - 1
temp <- (2/(max(raw_data$Temp) - min(raw_data$Temp))) *
  (run_first_obs$Temp - min(raw_data$Temp)) - 1

stan_code <- stan_model('../stan_code/sealanta_model.stan',
                        auto_write = TRUE)

stan_data <- list(n = nrow(raw_data),
                  nrun = max(raw_data$Run),
                  lmod = raw_data$lmod,
                  run = raw_data$Run,
                  dose = raw_data$Dose,
                  temp = temp,
                  strain = strain)

post_samps <- sampling(object = stan_code,
                       data = stan_data,
                       iter = 2000,
                       seed = 654321,
                       chain = 5)

saveRDS(post_samps, 'sealanta_post_samps.rds')
