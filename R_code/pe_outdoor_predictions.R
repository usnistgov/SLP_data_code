
library(tidyverse)
library(readxl)
library(rstan)
library(lubridate)
library(stringr)

ambient_conditions <- read_csv('../data/PE_FL_ambient_conditions_after_interp.csv')

test_group <- 18 # possibilities 14, 17, 18, 20, 22, and 23,
read_excel('../data/PE_FL_outdoor_meta_data_Aug_162016_to_Feb_282017.xlsx',
           sheet = 'Sheet2') %>%
  filter(X4 == test_group) -> outdoor_deg
date1 <- first(outdoor_deg$X1)
date2 <- last(outdoor_deg$X2)

ambient_conditions <- filter(ambient_conditions, date_time >= date1, date_time <= date2)

read_excel(path = '../data/pe_indoor_data.xlsx',
           sheet = 'Sheet2', col_names = FALSE, skip = 15) %>%
  select(num_range('X__', c(1, 4, 6, 7))) %>%
  filter(X__7 == 0) %>%
  summarize(median(X__1)) %>%
  unlist() -> zero_lim

b <- 4.18

post_samps <- readRDS('./pe_post_samps.rds')
alpha <- rstan::extract(post_samps, 'alpha')[[1]]
sigma_alpha <- rstan::extract(post_samps, 'sigma_alpha')[[1]]
sig <- rstan::extract(post_samps, 'sigma')[[1]]
sig <- apply(sig, 1, mean)

a <- ambient_conditions$panel_temp_use %o% alpha[, 2]
int_plus_noise <- alpha[, 1] + sigma_alpha*rnorm(n = nrow(alpha))
a <- sweep(a, 2, int_plus_noise, '+')
deg <- matrix(nrow = nrow(a), ncol = ncol(a))
deg[1, ] <- zero_lim/(1 + (ambient_conditions$dose_use[1]/a[1, ])^b)
for (i in 2:nrow(deg)) {

  curr_dose <- a[i, ]*(((zero_lim - deg[(i - 1), ])/deg[(i - 1), ])^(1/b))
  deg1 <- zero_lim/(1 + (curr_dose/a[i, ])^b)
  deg2 <- zero_lim/(1 + ((curr_dose + ambient_conditions$dose_use[i])/a[i, ])^b)
  deg[i, ] <- deg[(i - 1), ] - (deg1 - deg2)
}

deg[is.na(deg)] <- 0
deg <- sweep(deg, 2, sig*rnorm(length(sig)), '+')

deg_summary <- apply(deg, 1, quantile, probs = c(0.025, 0.5, 0.975))

ggdata <- tibble(lb = deg_summary[1, ],
                 est = deg_summary[2, ],
                 ub = deg_summary[3, ],
                 date_time = ambient_conditions$date_time)

ggplot(data = ggdata,
       mapping = aes(x = date_time, y = est)) +
 geom_line(color = 'red') +
 geom_ribbon(mapping = aes(ymin = lb, ymax = ub),
             fill = 'red', alpha = 0.5) +
 geom_point(data = outdoor_deg,
            mapping = aes(x = X2, y = Y)) +
 ylab('Elongation at Break (%)') +
 xlab('Date') +
 geom_hline(yintercept = 0, color = 'black', size = 2) +
 theme_classic() +
 theme(text = element_text(size = 20))
ggsave(paste0('outdoor_predictions_measurements_overlaid_test_group_', test_group, '.pdf'))

