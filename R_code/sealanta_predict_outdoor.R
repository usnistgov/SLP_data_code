
library(tidyverse)
library(rstan)
library(lubridate)

test_num <- 5
fig_ylims <- c(0.4, 1.2)
read_csv('../data/sealanta_outdoor_modulus_measurements_9_15_to_2_17.csv',
          skip = 1) %>%
  select(Modulus, `Start exposure`, `Stop exposure`, `Test#`) %>%
  rename(start = `Start exposure`, stop = `Stop exposure`,
         test = `Test#`) %>%
  filter(test == test_num) %>%
  mutate(stop = mdy_hms(paste0(stop, ' 23:00:00')),
         start = mdy_hms(paste0(start, ' 00:00:00')),
         Modulus = as.numeric(Modulus)) %>%
  filter(!is.na(Modulus)) %>%
  filter(Modulus > 0) %>%
  filter(!is.na(stop)) -> outdoor_modulus

start_date <- first(outdoor_modulus$start)
stop_date <- last(outdoor_modulus$stop)

orig_data <- read_csv('../data/sealanta_indoor_data.csv')
min_temp <- min(orig_data$Temp)
max_temp <- max(orig_data$Temp)
min_strain <- min(orig_data$Strain)
max_strain <- max(orig_data$Strain)

ambient_conditions <- read_csv('../data/sealanta_FL_ambient_conditions_after_interp.csv')
ambient_conditions <- mutate(ambient_conditions,
                   temp = (2/(max_temp - min_temp))*(temp_use - min_temp) - 1,
                   strain = (2/(max_strain - min_strain))*(strain_use - min_strain) - 1)
ambient_conditions <- filter(ambient_conditions,
                             date_time >= start_date,
                             date_time <= stop_date)

qplot(x = date_time, y = temp, data = ambient_conditions)

post_samps <- readRDS('./sealanta_post_samps.rds')

slope_coef <- rstan::extract(post_samps, 'slope_coef')[[1]]
sig_slope <- rstan::extract(post_samps, 'sig_slope')[[1]]
sig <- rstan::extract(post_samps, 'sig')[[1]]

deg_path <- matrix(nrow = nrow(ambient_conditions),
                   ncol = length(sig))

slope <- -exp(slope_coef[, 1] + slope_coef[, 2]*ambient_conditions$temp[1] +
  slope_coef[, 3]*ambient_conditions$strain[1] +
  slope_coef[, 4]*(ambient_conditions$temp[1]*ambient_conditions$strain[1]) +
    slope_coef[, 5]*(ambient_conditions$temp[1]^2) +
  sig_slope*rnorm(length(sig_slope)))
print(median(slope))
deg_path[1, ] <- slope*ambient_conditions$dose_use[1]
for (i in 2:nrow(ambient_conditions)) {

  slope <- -exp(slope_coef[, 1] + slope_coef[, 2]*ambient_conditions$temp[i] +
    slope_coef[, 3]*ambient_conditions$strain[i] +
    slope_coef[, 4]*(ambient_conditions$temp[i]*ambient_conditions$strain[i]) +
      slope_coef[, 5]*(ambient_conditions$temp[i]^2) +
    sig_slope*rnorm(length(sig_slope)))
  # print(median(slope))
  deg_path[i, ] <- deg_path[(i - 1), ] + slope*ambient_conditions$dose_use[i]
}
deg_path <- sweep(deg_path, 2, sig*rnorm(length(sig)), '+')
deg_path <- exp(deg_path)
deg_path <- apply(deg_path, 1, quantile, probs = c(0.025, 0.5, 0.975), na.rm = TRUE)

pred_data <- mutate(ambient_conditions,
                    est = deg_path[2, ],
                    lb = deg_path[1, ],
                    ub = deg_path[3, ])

all_years <- paste(unique(year(outdoor_modulus$stop)), collapse = ', ')

ggplot(data = pred_data,
       mapping = aes(x = date_time, y = est)) +
  geom_ribbon(mapping = aes(ymin = lb,
                            ymax = ub),
              alpha = 0.5, fill = 'red') +
  geom_line(color = 'red') +
  geom_point(data = outdoor_modulus,
             mapping = aes(x = stop, y = Modulus)) +
  ylab('Modulus Ratio') +
  xlab(paste0('Date (', all_years, ')')) +
  ylim(fig_ylims) +
  theme_classic() +
  theme(text = element_text(size = 20))
ggsave(paste0('outdoor_comparison_test_num_', test_num, '.pdf'))
