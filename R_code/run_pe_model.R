
library(rstan)
library(purrr)
library(readxl)
library(dplyr)

read_excel(path = '../data/pe_indoor_data.xlsx',
           sheet = 'Sheet2', col_names = FALSE, skip = 15) %>%
  select(num_range('X__', c(1, 4, 6, 7, 8))) %>%
  filter(X__7 != 0, X__6 != 0) %>%
  rename(y = X__1, temp = X__4, uv = X__6, exp_time = X__7, dose = X__8) %>%
  filter(uv <= 40) %>%
  mutate(Temp = factor(temp),
         UV = factor(uv),
         ttemp = (2/(max(temp) - min(temp)))*(temp - min(temp)) - 1) %>%
  arrange(ttemp) -> raw_data

read_excel(path = '../data/pe_indoor_data.xlsx',
           sheet = 'Sheet2', col_names = FALSE, skip = 15) %>%
  select(num_range('X__', c(1, 4, 6, 7))) %>%
  filter(X__7 == 0) %>%
  summarize(median(X__1)) -> zero_lim

zero_lim <- unlist(zero_lim)
b <- 4.18


stan_data <- list(n = nrow(raw_data),
                  n_temp = length(unique(raw_data$ttemp)),
                  y = raw_data$y,
                  dose = raw_data$dose,
                  temp = unique(raw_data$ttemp),
                  temp_id = as.integer(raw_data$Temp),
                  zero_lim = as.numeric(zero_lim),
                  b = b,
                  alpha_df = 100,
                  alpha_scale = 50,
                  sigma_alpha_df = 100,
                  sigma_alpha_scale = 5)

stan_code <- stan_model(file = '../stan_code/pe_model.stan', auto_write = TRUE)

post_samps <- rstan::sampling(object = stan_code,
                       data = stan_data,
                       chains = 5,
                       iter = 3000,
                       warmup = 2000,
                       seed = 654321,
                       cores = 5,
                       control = list(max_treedepth = 12, adapt_delta = 0.95))

saveRDS(post_samps, file = 'pe_post_samps.rds')
