
library(tidyverse)
library(rstan)
library(stringr)

orig_data <- read_csv('../data/sealanta_indoor_data.csv')
min_temp <- min(orig_data$Temp)
max_temp <- max(orig_data$Temp)
min_strain <- min(orig_data$Strain)
max_strain <- max(orig_data$Strain)

file_path <- '../data/two_stage_trial_1.csv'
save_name <- 'predict_two_stage_trial_1.pdf'
raw_data <- read_csv(file_path)
raw_data <- filter(raw_data, group == 1)
raw_data <- mutate(raw_data,
                   Temp = (2/(max_temp - min_temp))*(X1 - min_temp) - 1,
                   Strain = (2/(max_strain - min_strain))*(X3 - min_strain) - 1,
                   Time = X12,
                   UV = X5/100,
                   Modulus = Y,
                   diff_time = c(first(Time), diff(Time)))

raw_data <- select(raw_data, Temp, Strain, Time, UV, Modulus, diff_time)

raw_data %>%
  mutate(UV = ifelse(UV == 0.5, 26.24/36.39, UV)) %>%
  mutate(Intensity = UV*36.39) %>%
  mutate(Dose = Intensity*diff_time*24*60*60/1e6) %>%
  mutate(lmod = log(Modulus)) -> raw_data

post_samps <- readRDS('./sealanta_post_samps.rds')

slope_coef <- rstan::extract(post_samps, 'slope_coef')[[1]]
sig_slope <- rstan::extract(post_samps, 'sig_slope')[[1]]
sig <- rstan::extract(post_samps, 'sig')[[1]]

deg_path <- matrix(nrow = nrow(raw_data),
                   ncol = length(sig))

slope <- -exp(slope_coef[, 1] + slope_coef[, 2]*raw_data$Temp[1] +
  slope_coef[, 3]*raw_data$Strain[1] +
  slope_coef[, 4]*(raw_data$Temp[1]*raw_data$Strain[1]) +
    slope_coef[, 5]*(raw_data$Temp[1]*raw_data$Temp[1]) +
  sig_slope*rnorm(length(sig_slope)))
deg_path[1, ] <- slope*raw_data$Dose[1]
for (i in 2:nrow(raw_data)) {

  slope <- -exp(slope_coef[, 1] + slope_coef[, 2]*raw_data$Temp[i] +
    slope_coef[, 3]*raw_data$Strain[i] +
    slope_coef[, 4]*(raw_data$Temp[i]*raw_data$Strain[i]) +
      slope_coef[, 5]*(raw_data$Temp[i]*raw_data$Temp[i]) +
    sig_slope*rnorm(length(sig_slope)))
  deg_path[i, ] <- deg_path[(i - 1), ] + slope*raw_data$Dose[i]
}
deg_path <- sweep(deg_path, 2, sig*rnorm(length(sig)), '+')
deg_path <- exp(deg_path)
deg_path <- apply(deg_path, 1, quantile, probs = c(0.025, 0.5, 0.975), na.rm = TRUE)

pred_data <- mutate(raw_data,
                    est = deg_path[2, ],
                    lb = deg_path[1, ],
                    ub = deg_path[3, ])

read_csv(file_path) %>%
  select(X12, Y, X5) %>%
  rename(Time = X12, Modulus = Y) %>%
  mutate(lmod = log(Modulus)) -> raw_data2

ggplot(data = pred_data,
       mapping = aes(x = Time, y = Modulus)) +
  geom_ribbon(mapping = aes(ymin = lb,
                            ymax = ub),
              alpha = 0.5, fill = 'red') +
  geom_line(mapping = aes(y = est), color = 'red') +
  geom_point(data = raw_data2) +
  ylab('Modulus Ratio') +
  xlab('Time (Days)') +
  theme_classic() +
  theme(text = element_text(size = 20))
ggsave(save_name)
