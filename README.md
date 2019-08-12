## Prerequisites

R must be installed
[https://www.r-project.org/](https://www.r-project.org/) as well as
the R packages `tidyverse`
[https://www.tidyverse.org/](https://www.tidyverse.org/) and `rstan`
[https://mc-stan.org/users/interfaces/rstan.html](https://mc-stan.org/users/interfaces/rstan.html)

## Running the code

The `.R` files can be run interactively or in BATCH mode.

**OS note:** The code should run unmodified under Windows, Linux, or
Mac.  It has been tested under Windows and Linux.

## List of files and descriptions

- `data/`
    1. `PE_Florida_ambient_plus_panel_temps.xlsx`
    2. `PE_FL_outdoor_meta_data_Aug_162016_to_Feb_282017.xlsx`
    3. `pe_indoor_data.xlsx`
    4. `sealanta_FL_ambient_conditions.csv`
    5. `sealanta_indoor_data.csv`
    6. `sealanta_outdoor_modulus_measurements_9_15_to_2_17.csv`
    7. `two_stage_trial_1.csv`
    8. `two_stage_trial_2.csv`
    9. `two_stage_trial_3.csv`
    10. `two_stage_trial_4.csv`
- `R_code/`
    1. `run_pe_model.R`
        - *input* -- `data/pe_indoor_data.xlsx` and
        `stan_code/pe_model.stan`
        - *output* -- `pe_post_samps.rds`
        - *dependencies* -- None
    2. `run_sealanta_model.R`
        - *input* -- `data/sealanta_indoor_data.csv` and
        `stan_code/sealanta_model.stan`
        - *output* -- `sealanta_post_samps.rds`
        - *dependencies* -- None
    3. `predict_2_stage.R`
        - *input* -- `data/sealanta_indoor_data.csv` and
        `data/two_stage_trial_*.csv` and
        `sealanta_post_samps.rds`.  The value of the symbol "*" is set
        inside of the script in two places, the variables `file_path`
        and `save_name`
        - *output* -- `predict_two_stage_trial_*.pdf`
        - *dependencies* -- The script `run_sealanta_model.R` must be
        ran first
    4. `pe_interpolate_outdoor_values.R`
        - *input* -- `data/Florida_ambient_plus_panel_temps.xlsx`
        - *output* --  `data/PE_FL_ambient_conditions_after_interp.csv`
        - *dependencies* -- None
    5. `sealanta_interpolate_outdoor_values.R`
        - *input* -- `data/sealanta_FL_ambient_conditions.csv`
        - *output* -- `data/sealanta_FL_ambient_conditions_after_interp.csv`
        - *dependencies* -- None
    6. `pe_outdoor_predictions.R`
        - *input* -- `data/PE_FL_ambient_conditions_after_interp.csv`,
        `data/PE_FL_outdoor_meta_data_Aug_162016_to_Feb_282017.xlsx`,
        `data/pe_indoor_data.xlsx`, and `pe_post_samps.rds`.  A
        variable in the script called `test_group` also must be set,
        taking values 14, 17, 18, 20, 22, or 23
        - *output* --
        `outdoor_predictions_measurements_overlaid_test_group_*.pdf`,
        where the "*" symbol is the value of the variable
        `test_group`.
        - *dependencies* -- The scripts `run_pe_model.R` and
        `pe_interpolate_outdoor_values.R` must be ran first
    7. `sealanta_predict_outdoor.R`
        - *input* --
        `data/sealanta_outdoor_modulus_measurements_9_15_to_2_17.csv`,
        `data/sealanta_indoor_data.csv`,
        `data/sealanta_FL_ambient_conditions_after_interp.csv`, and
        `sealanta_post_samps.rds`. A variable in the script called
        `test_num` also must be set, taking values 1 through 7
        - *output* -- `outdoor_comparison_test_num_*.pdf`, where the
        "*" symbol is the value of the variable `test_num`
        - *dependencies* -- The scripts `run_sealanta_model.R` and
        `sealanta_interpolate_outdoor_values.R` must be ran first
- `stan_code/`
    1. `pe_model.stan`
    2. `sealanta_model.stan`

