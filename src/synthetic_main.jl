#############################
######## ENVIRONMENT ########
#############################

using Pkg                               # Import package manager
Pkg.activate(".")                       # Activate Julia environment
Pkg.instantiate()                       # Instantiate the Julia environment 

#############################
######### PACKAGES ##########
#############################

# Import necessary dependencies
using HTTP, CSV                         # Data download and handling
using Distributions, DistributionsUtils # Probability distributions
using Dates                             # Data types
using DataStructures, DataFrames        # Dat wrangling
using Plots, Plots.PlotMeasures         # Data visualization
using Optim                             # Parameter optimization
using JLD2, Serialization               # Julia data structures saving
using ProgressMeter                     # Progress bar
#############################
##### CUSTOM FUNCTIONS ######
#############################

# Include Julia files containing all the necessary functions 
include("synthetic_utilities.jl");
include("sequences.jl");
include("time_delays.jl");
include("plotting.jl");

#############################
###### PRE-PROCESSING #######
#############################

# URL to Piedmont confirmed cases data
const piedmont_confirmed_url = "https://raw.githubusercontent.com/InPhyT/COVID19-Italy-Integrated-Surveillance-Data/main/3_output/data/iss_age_date_piedmont_confirmed.csv"

# Download Piedmont confirmed cases data
const piedmont_confirmed_raw_df = DataFrame(CSV.File(HTTP.get(piedmont_confirmed_url).body));

# Aggregate age classes
const max_line = findfirst(x -> x == Date("2020-12-15"), piedmont_confirmed_raw_df.date)
const piedmont_confirmed_aggregated_df = DataFrame();
piedmont_confirmed_aggregated_df.date = piedmont_confirmed_raw_df.date[2:max_line]
piedmont_confirmed_aggregated_df[!, "0_39"] = sum([piedmont_confirmed_raw_df[!, "0_5"], piedmont_confirmed_raw_df[!, "6_12"], piedmont_confirmed_raw_df[!, "13_19"], piedmont_confirmed_raw_df[!, "20_29"], piedmont_confirmed_raw_df[!, "30_39"]], dims=1)[1][2:max_line]
piedmont_confirmed_aggregated_df[!, "40_59"] = sum([piedmont_confirmed_raw_df[!, "40_49"], piedmont_confirmed_raw_df[!, "50_59"]], dims=1)[1][2:max_line]
piedmont_confirmed_aggregated_df[!, "60_69"] = piedmont_confirmed_raw_df[!, "60_69"][2:max_line]
piedmont_confirmed_aggregated_df[!, "70_79"] = piedmont_confirmed_raw_df[!, "70_79"][2:max_line]
piedmont_confirmed_aggregated_df[!, "80_+"] = sum([piedmont_confirmed_raw_df[!, "80_89"], piedmont_confirmed_raw_df[!, "90_+"]], dims=1)[1][2:max_line]

# Local root path
const root_path = dirname(@__DIR__)

# Load age structure data and age classes representation switching dictionaries
const all_age_groups_path = joinpath(root_path, "data/population/fine.csv");
const all_age_groups = CSV.read(all_age_groups_path, DataFrame)[!, "population"]
const age_classes_string_integer_dct = Dict("0_39" => 0, "40_59" => 40, "60_69" => 60, "70_79" => 70, "80_+" => 80)
const age_classes_representations = Dict(0 => "[0,39]",
                                        40 => "[40,59]",
                                        50 => "[50,59]",
                                        60 => "[60,69]",
                                        70 => "[70,79]",
                                        80 => "[80+]"
                                    )


const event_title_incidences_COVID_19_plots = Dict(  "IQP" => Dict("prefix" =>"Daily", "suffix" =>"Precautionary Quarantines by Date of Quarantine Onset"),
                                                     "FQP" => Dict("prefix" =>"Daily", "suffix" =>"Precautionary Quarantines by Date of Quarantine    Onset"),
                                                     "IS" => Dict("prefix" =>"Daily", "suffix" =>"Symptomatic Cases by Date of Symptoms Onset"),
                                                     "P" => Dict("prefix" =>"Daily", "suffix" =>"Confirmed Cases by Date of Diagnosis"),
                                                     "IQO" => Dict("prefix" =>"Daily", "suffix" =>"Ordinary Quarantines by Date of Quarantine Onset"),
                                                     "FQO" => Dict("prefix" =>"Daily", "suffix" =>"Ordinary Quarantines by Date of Quarantine Ending"),
                                                     "AO" => Dict("prefix" =>"Daily", "suffix" =>"Ordinary Admissions by Date of Admission"),
                                                     "DO" => Dict("prefix" =>"Daily", "suffix" =>"Ordinary Discharges by Date of Discharge"),
                                                     "AI" => Dict("prefix" =>"Daily", "suffix" =>"ICU Admissions by Date of Admission"),
                                                     "DI" => Dict("prefix" =>"Daily", "suffix" =>"ICU Discharges by Date of Discharge"),
                                                     "AR" => Dict("prefix" =>"Daily", "suffix" =>"Rehabilitative Admissions by Date of Admission"),
                                                     "DR" => Dict("prefix" =>"Daily", "suffix" =>"Rehabilitative Discharges by Date of Discharge"),
                                                     "G" => Dict("prefix" =>"Daily", "suffix" =>"Recovery by Date of Recovery"),
                                                     "D" => Dict("prefix" =>"Daily", "suffix" =>"Deceased Cases by Date of Death")
) 


const event_title_incidences_SDO_plots = Dict(  "IQP" => Dict("prefix" =>"Daily", "suffix" =>"IQP"),
                                                "FQP" => Dict("prefix" =>"Daily", "suffix" =>"FQP"),
                                                "IS" => Dict("prefix" =>"Daily", "suffix" =>"IS"),
                                                "P" => Dict("prefix" =>"Daily", "suffix" =>"P"),
                                                "IQO" => Dict("prefix" =>"Daily", "suffix" =>"IQO"),
                                                "FQO" => Dict("prefix" =>"Daily", "suffix" =>"FQO"),
                                                "AO" => Dict("prefix" =>"Daily", "suffix" =>"AO"),
                                                "DO" => Dict("prefix" =>"Daily", "suffix" =>"DO"),
                                                "AI" => Dict("prefix" =>"Daily", "suffix" =>"AI"),
                                                "DI" => Dict("prefix" =>"Daily", "suffix" =>"DI"),
                                                "AR" => Dict("prefix" =>"Daily", "suffix" =>"AR"),
                                                "DR" => Dict("prefix" =>"Daily", "suffix" =>"DR"),
                                                "G" => Dict("prefix" =>"Daily", "suffix" =>"G"),
                                                "D" => Dict("prefix" =>"Daily", "suffix" =>"D")
) 
#############################
######## TRANSITIONS ########
#############################

# Load transitions
const symptomatic_path = joinpath(root_path, "data/parameters/transition-rates/Symptomatic_Fraction/Symptomatic_Fraction_Piedmont_Davies.csv");
const hospitalization_path = joinpath(root_path, "data/parameters/transition-rates/Hospitalization_Fraction/H_Fraction_Ferguson.csv");
const icu_rate_path = joinpath(root_path, "data/parameters/transition-rates/ICU_Fraction/ICU_Fraction_Ferguson.csv");
const ifr_path = joinpath(root_path, "data/parameters/transition-rates/IFR/IFR_Italy_Brazeau.csv");
const hfr_path = joinpath(root_path, "data/parameters/transition-rates/HFR/HFR_France_Salje.csv");

# Aggregate transitions to the desired age classes
## Symptomatic fraction
const s = from_N_to_n("Mean", [1:4, 5:6, 7, 8, 8], all_age_groups, [1:4, 5:6, 7, 8, 9]; path=symptomatic_path, column_population_aggregations=[1:9, 10:19, 20:29, 30:39, 40:49, 50:59, 60:69, 70:79, 80:length(all_age_groups)])

## Hospitalization rate
const η = from_N_to_n("Hospitalized_Fraction", [1:4, 5:6, 7, 8, 9], all_age_groups, [1:4, 5:6, 7, 8, 9]; path=hospitalization_path, column_population_aggregations=[1:9, 10:19, 20:29, 30:39, 40:49, 50:59, 60:69, 70:79, 80:length(all_age_groups)])

## ICU rate
const χ = from_N_to_n("ICU_Fraction", [1:4, 5:6, 7, 8, 9], all_age_groups, [1:4, 5:6, 7, 8, 9]; path=icu_rate_path, column_population_aggregations=[1:9, 10:19, 20:29, 30:39, 40:49, 50:59, 60:69, 70:79, 80:length(all_age_groups)]) #ICU fraction ( do not multply by HOSP if you put ICU serially after HOSP)

## IFR
const δ = from_N_to_n("Seroadjusted_IFR_Mean", [1:4, 5:6, 7, 8, 9], all_age_groups, [1:4, 5:6, 7, 8, 9]; path=ifr_path, column_population_aggregations=[1:9, 10:19, 20:29, 30:39, 40:49, 50:59, 60:69, 70:79, 80:length(all_age_groups)])

## H-IFR
const δ_H = from_N_to_n("Mean", [1:3, 4:5, 6, 7, 8], all_age_groups, [1:3, 4:5, 6, 7, 8]; path=hfr_path, column_population_aggregations=[1:19, 20:29, 30:39, 40:49, 50:59, 60:69, 70:79, 80:length(all_age_groups)])

## ICU-IFR
const δ_ICU = (δ ./ χ) ./ η #(( δ ./ χ) ./ η) ./s

## Q-IFR
const δ_Q = δ ./ s

#############################
#### DELAYS DISTRIBUTIONS ###
#############################

# S -> P
const λ_SP_prior = Uniform(-3, 3) #Truncated(NegativeBinomial(1.0,(1-(7.385/(7.385 + 1)))), 0, 40)

# P -> IQP
const λ_P_IQP_prior = Uniform(-20, -1)

# T -> AO
const λ_TH_prior_zhang_lognormal = LogNormal(-0.94, 1.71)  # AIC = 3486.1

# AO -> DO
const λ_H_0_39_prior_zardini_optim = fit_distributions((Gamma, LogNormal, Weibull), Dict((quantile, (0.25,)) => 0.0, (quantile, (0.5,)) => 4.0, (quantile, (0.75,)) => 10.0), ([0.5, 0.5], [0.5, 0.5], [0.5, 0.5]), (([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0])); return_best=true)
const λ_H_40_59_prior_zardini_optim = fit_distributions((Gamma, LogNormal, Weibull), Dict((quantile, (0.25,)) => 1.0, (quantile, (0.5,)) => 9.0, (quantile, (0.75,)) => 18.0), ([0.5, 0.5], [0.5, 0.5], [0.5, 0.5]), (([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0])); return_best=true)
const λ_H_60_69_prior_zardini_optim = fit_distributions((Gamma, LogNormal, Weibull), Dict((quantile, (0.25,)) => 6.0, (quantile, (0.5,)) => 13.0, (quantile, (0.75,)) => 24.0), ([0.5, 0.5], [0.5, 0.5], [0.5, 0.5]), (([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0])); return_best=true)
const λ_H_70_79_prior_zardini_optim = fit_distributions((Gamma, LogNormal, Weibull), Dict((quantile, (0.25,)) => 5.0, (quantile, (0.5,)) => 12.0, (quantile, (0.75,)) => 24.0), ([0.5, 0.5], [0.5, 0.5], [0.5, 0.5]), (([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0])); return_best=true)
const λ_H_80_plus_prior_zardini_optim = fit_distributions((Gamma, LogNormal, Weibull), Dict((quantile, (0.25,)) => 4.0, (quantile, (0.5,)) => 10.0, (quantile, (0.75,)) => 24.0), ([0.5, 0.5], [0.5, 0.5], [0.5, 0.5]), (([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0])); return_best=true)
const λ_H_priors_zardini = [λ_H_0_39_prior_zardini_optim, λ_H_40_59_prior_zardini_optim, λ_H_60_69_prior_zardini_optim, λ_H_70_79_prior_zardini_optim, λ_H_80_plus_prior_zardini_optim]

# AO -> AI
const λ_HICU_0_39_prior_zardini_optim = fit_distributions((Gamma, LogNormal, Weibull), Dict((quantile, (0.25,)) => 0.0, (quantile, (0.5,)) => 1.0, (quantile, (0.75,)) => 5.0), ([0.5, 0.5], [0.5, 0.5], [0.5, 0.5]), (([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0])); return_best=true)
const λ_HICU_40_59_prior_zardini_optim = fit_distributions((Gamma, LogNormal, Weibull), Dict((quantile, (0.25,)) => 0.0, (quantile, (0.5,)) => 2.0, (quantile, (0.75,)) => 6.0), ([0.5, 0.5], [0.5, 0.5], [0.5, 0.5]), (([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0])); return_best=true)
const λ_HICU_60_69_prior_zardini_optim = fit_distributions((Gamma, LogNormal, Weibull), Dict((quantile, (0.25,)) => 0.0, (quantile, (0.5,)) => 3.0, (quantile, (0.75,)) => 7.0), ([0.5, 0.5], [0.5, 0.5], [0.5, 0.5]), (([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0])); return_best=true)
const λ_HICU_70_79_prior_zardini_optim = fit_distributions((Gamma, LogNormal, Weibull), Dict((quantile, (0.25,)) => 1.0, (quantile, (0.5,)) => 4.0, (quantile, (0.75,)) => 7.0), ([0.5, 0.5], [0.5, 0.5], [0.5, 0.5]), (([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0])); return_best=true)
const λ_HICU_80_plus_prior_zardini_optim = fit_distributions((Gamma, LogNormal, Weibull), Dict((quantile, (0.25,)) => 0.0, (quantile, (0.5,)) => 2.0, (quantile, (0.75,)) => 11.5), ([0.5, 0.5], [0.5, 0.5], [0.5, 0.5]), (([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0])); return_best=true)
const λ_HICU_priors_zardini = [λ_HICU_0_39_prior_zardini_optim, λ_HICU_40_59_prior_zardini_optim, λ_HICU_60_69_prior_zardini_optim, λ_HICU_70_79_prior_zardini_optim, λ_HICU_80_plus_prior_zardini_optim]

# AO -> G
const λ_HR_prior_nair_optim = fit_distributions((Gamma, LogNormal, Weibull), Dict((quantile, (0.05,)) => 8.0, (quantile, (0.5,)) => 9.0, (quantile, (0.95,)) => 15.0), ([0.5, 0.5], [0.5, 0.5], [0.5, 0.5]), (([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0])); return_best=true)

# AO -> D
const λ_HD_0_64_prior_palmieri_optim = fit_distributions((Gamma, LogNormal, Weibull), Dict((quantile, (0.25,)) => 5.0, (quantile, (0.5,)) => 9.0, (quantile, (0.75,)) => 17.0), ([0.5, 0.5], [0.5, 0.5], [0.5, 0.5]), (([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0])); return_best=true)
const λ_HD_65_plus_prior_palmieri_optim = fit_distributions((Gamma, LogNormal, Weibull), Dict((quantile, (0.25,)) => 7.0, (quantile, (0.5,)) => 10.0, (quantile, (0.75,)) => 22.0), ([0.5, 0.5], [0.5, 0.5], [0.5, 0.5]), (([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0])); return_best=true)

# AI -> DI
const λ_ICU_0_39_prior_zardini_optim = fit_distributions((Gamma, LogNormal, Weibull), Dict((quantile, (0.25,)) => 4.0, (quantile, (0.5,)) => 9.0, (quantile, (0.75,)) => 15.75), ([0.5, 0.5], [0.5, 0.5], [0.5, 0.5]), (([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0])); return_best=true)
const λ_ICU_40_59_prior_zardini_optim = fit_distributions((Gamma, LogNormal, Weibull), Dict((quantile, (0.25,)) => 6.0, (quantile, (0.5,)) => 11.0, (quantile, (0.75,)) => 19.0), ([0.5, 0.5], [0.5, 0.5], [0.5, 0.5]), (([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0])); return_best=true)
const λ_ICU_60_69_prior_zardini_optim = fit_distributions((Gamma, LogNormal, Weibull), Dict((quantile, (0.25,)) => 6.0, (quantile, (0.5,)) => 12.0, (quantile, (0.75,)) => 20.0), ([0.5, 0.5], [0.5, 0.5], [0.5, 0.5]), (([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0])); return_best=true)
const λ_ICU_70_79_prior_zardini_optim = fit_distributions((Gamma, LogNormal, Weibull), Dict((quantile, (0.25,)) => 5.0, (quantile, (0.5,)) => 10.0, (quantile, (0.75,)) => 18.0), ([0.5, 0.5], [0.5, 0.5], [0.5, 0.5]), (([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0])); return_best=true)
const λ_ICU_80_plus_prior_zardini_optim = fit_distributions((Gamma, LogNormal, Weibull), Dict((quantile, (0.25,)) => 3.0, (quantile, (0.5,)) => 5.0, (quantile, (0.75,)) => 10.75), ([0.5, 0.5], [0.5, 0.5], [0.5, 0.5]), (([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0])); return_best=true)
const λ_ICU_priors_zardini = [λ_ICU_0_39_prior_zardini_optim, λ_ICU_40_59_prior_zardini_optim, λ_ICU_60_69_prior_zardini_optim, λ_ICU_70_79_prior_zardini_optim, λ_ICU_80_plus_prior_zardini_optim]

# AI -> R
const λ_ICUR_prior_hall = fit_distributions((Gamma,), Dict((quantile, (0.25,)) => 5.0, (quantile, (0.5,)) => 12.0, (quantile, (0.75,)) => 28.0), ([50.5, 50.5],), (([0.0, 0.0], [100.0, 100.0]),); return_best=true)

# AI -> D
const λ_ICUD_prior_hall = fit_distributions((Gamma,), Dict((quantile, (0.25,)) => 5.0, (quantile, (0.5,)) => 9.0, (quantile, (0.75,)) => 16.0), ([50.5, 50.5],), (([0.0, 0.0], [100.0, 100.0]),); return_best=true)

# AR -> DR
const λ_R_prior = Uniform(1, 10)

# IQO -> FQO
const λ_Q_prior = Uniform(14, 21)

#############################
##### SYNTHETIC DATASET #####
#############################

const MVP = missing
const is_MVP = ismissing

const synthetic_dataset = get_synthetic_dataset(piedmont_confirmed_aggregated_df; λ_SP_prior=λ_SP_prior, λ_TH_prior=λ_TH_prior_zhang_lognormal, λ_H_priors=λ_H_priors_zardini, λ_ICU_priors=λ_HICU_priors_zardini, λ_R_prior=λ_R_prior, λ_Q_prior=λ_Q_prior, symptomatic_fraction=s, quarantena_precauzionale_fraction=0.3, hospitalization_rate=η, ICU_rate=χ, rehabilitative_rate=0.8, infection_fatality_ratio=δ, age_classes_string_integer_dct=age_classes_string_integer_dct, MVP=MVP, is_MVP=is_MVP)

# Save synthetic dataset
CSV.write(joinpath(root_path, "data/synthetic-input/synthetic_input.csv"), synthetic_dataset)

#############################
######## SEQUENCES ##########
#############################

# Get censored and non-censored synthetic sequences
const synthetic_sequences = get_sequences(synthetic_dataset, lower_date_limit=Date("2020-01-01"), upper_date_limit=Date("2020-12-31"); MVP=MVP, is_MVP=is_MVP)
const synthetic_sequences_censored, data_quality_synthetic_sequences= apply_privacy_policy(synthetic_sequences)
const synthetic_incidences = aggregate_sequences(synthetic_sequences, Date("2020-01-01"), Date("2020-12-31"))
const synthetic_incidences_censored, data_quality_synthetic_incidences = apply_privacy_policy(synthetic_incidences) #get_sequences(synthetic_dataset; lower_date_limit = Date("2020-01-01"), upper_date_limit = Date("2020-12-31"), aggregate = true, privacy_policy = true, MVP = MVP, is_MVP = is_MVP)

# Save censored synthetic sequences
save_sequences_as_csv(synthetic_sequences_censored, joinpath(root_path, "data/synthetic-output/sequences"), age_classes_representations)
save_incidences_as_csv(synthetic_incidences_censored, joinpath(root_path, "data/synthetic-output/incidences"))

#############################
######## TIME DELAYS ########
#############################

const Ts = (0, 1, 7, 14, 21, 30, 60, 120, 240, 365) # theoretical maximum = 365
# Get censored and non-censored synthetic time delay distributions 
dt_mostcommon = (Gamma,) #NegativeBinomial LogNormal, NegativeBinomial, Weibull
# const synthetic_delays, synthetic_delays_frequencies, synthetic_delay_distributions = @time get_delays(synthetic_dataset; privacy_policy=false, max_T=2, distributions_types=dt_mostcommon, get_frequencies=true, time_limit=1, MVP=MVP, is_MVP=is_MVP);

const synthetic_delays, synthetic_delays_frequencies = get_delays(synthetic_dataset; Ts=Ts, date_start=Date("2020-01-01"), date_end=Date("2020-12-31"), privacy_policy=false, distributions_types=(), get_frequencies=true, MVP=MVP, is_MVP=is_MVP);

# Save synthetic time delay distributions
## Censored absolutes
save_delays_as_csv(synthetic_delays, joinpath(root_path, "data/synthetic-output/time-delays/empirical-absolute-distributions"))
## Frequencies
save_delays_as_csv(synthetic_delays_frequencies, joinpath(root_path, "data/synthetic-output/time-delays/empirical-frequency-distributions"))
## Estimated
save_estimated_delay_distributions(synthetic_delay_distributions, joinpath(root_path, "data/synthetic-output/time-delays/estimated-distributions"))

#############################
##### DATA VISUALIZATION ####
#############################

# Get rich portion of the synthetic dataset
const rich_synthetic_dataset = synthetic_dataset[.!is_MVP.(synthetic_dataset.data_AO).&.!is_MVP.(synthetic_dataset.data_AI).&.!is_MVP.(synthetic_dataset.data_IQP).&.!is_MVP.(synthetic_dataset.data_IQO), :]
rich_synthetic_dataset = rich_synthetic_dataset[1:(size(rich_synthetic_dataset, 1)÷30):size(rich_synthetic_dataset, 1), :]
rich_synthetic_dataset.ID = collect(1:size(rich_synthetic_dataset, 1))

# Get ICU-only portion of the synthetic dataset
# const icu_synthetic_dataset = synthetic_dataset[is_MVP.(synthetic_dataset.data_AO) .& .!is_MVP.(synthetic_dataset.data_AI),  :] #[1:(size(synthetic_dataset,1) ÷ 30):size(synthetic_dataset,1),:]
# icu_synthetic_dataset = icu_synthetic_dataset[1:(size(icu_synthetic_dataset,1) ÷ 30):size(icu_synthetic_dataset,1),:]
# icu_synthetic_dataset.ID = collect(1:size(icu_synthetic_dataset,1))

const synthetic_line_list_plot = plot_line_list_processed(rich_synthetic_dataset, MVP, is_MVP,
    mode=:hlines_annotations,
    title="Synthetic COVID-19 Individual-Level Surveillance Data in Piedmont",
    size=(2200, 2000),
    lw=15
)

# Save synthetic line lust plot
savefig(synthetic_line_list_plot, joinpath(root_path, "images/plots/synthetic-input/synthetic_line_list_plot.png"))

# Plot synthetic sequences
const sequences_plots = plot_sequences(synthetic_sequences, age_classes_representations; paltt=cgrad(:Paired_9, categorical=true));

# Save sequences plots
for (sequence, plt) in collect(sequences_plots)
    savefig(plt, joinpath(root_path, "images/plots/synthetic-output/sequences", sequence))
end

const synthetic_incidences_plots = plot_incidences(synthetic_incidences, age_classes_representations; event_title_associations = event_title_incidences_SDO_plots, disease = "COVID-19")

# Save incidences plots
for (incidence, plt) in collect(synthetic_incidences_plots)
    savefig(plt, joinpath(root_path, "images/plots/synthetic-output/incidences", incidence))
end

# Plot synthetic time delay distributions
const delays_plots = plot_delays(synthetic_delays_frequencies, 1, age_classes_representations)

# Save time delays distributions plots
for (delay, plt) in collect(delays_plots)
    savefig(plt, joinpath(root_path, "images/plots/synthetic-output/time-delays", delay))
end

# Plot estimated bvs empirical time delays distributions
const estimated_distributions_plots = plot_fitted_time_delay_distributions(synthetic_delays, synthetic_delay_distributions, 1, age_classes_representations)