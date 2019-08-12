data {
  int n;
  int n_temp;
  vector[n] y;
  vector[n] dose;
  vector[n_temp] temp;
  int temp_id[n];
  real<lower=0> zero_lim;
  real<lower=0> b;
  real<lower=0> alpha_df;
  real<lower=0> alpha_scale;
  real<lower=0> sigma_alpha_df;
  real<lower=0> sigma_alpha_scale;
}

parameters {
  vector<lower=0>[n_temp] a;
  vector<lower=0>[n_temp] sigma;
  vector[2] alpha;
  real<lower=0> sigma_alpha;
}

transformed parameters {
  vector<lower=0>[n] y_mean;
  vector<lower=0>[n] y_sd;
  vector[n_temp] a_mean;

  for (i in 1:n) {

    y_mean[i] = zero_lim/(1 + (dose[i]/a[temp_id[i]])^b);
    y_sd[i] = sigma[temp_id[i]];
  }

  a_mean = alpha[1] + alpha[2]*temp;
}

model {
  y ~ normal(y_mean, y_sd);
  a ~ normal(a_mean, sigma_alpha);
  alpha ~ student_t(alpha_df, 0, alpha_scale);
  sigma_alpha ~ student_t(sigma_alpha_df, 0, sigma_alpha_scale);
}
