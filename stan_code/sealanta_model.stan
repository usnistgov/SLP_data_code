data {
  int n;
  int nrun;
  vector[n] lmod;
  int run[n];
  vector[n] dose;
  vector[nrun] temp;
  vector[nrun] strain;
}

parameters {
  vector[nrun] slope;
  vector[5] slope_coef;
  real<lower=0> sig;
  real<lower=0> sig_slope;
}

transformed parameters {
  vector[n] lmod_mean;
  vector[nrun] slope_mean;

  lmod_mean = -exp(slope[run]) .* dose;
  slope_mean = slope_coef[1] + slope_coef[2]*temp +
    slope_coef[3]*strain + slope_coef[4]*(temp .* strain) +
    slope_coef[5]*(temp .* temp);
}

model {
  lmod ~ normal(lmod_mean, sig);
  slope ~ normal(slope_mean, sig_slope);
}
