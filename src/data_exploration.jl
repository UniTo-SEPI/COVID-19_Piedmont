#############################
######## ENVIRONMENT ########
#############################

using Pkg                               # Import package manager
Pkg.activate("./Code/Julia")            # Activate Julia environment
Pkg.instantiate()                       # Instantiate the Julia environment

#############################
######### PACKAGES ##########
#############################

# Import necessary dependencies
using CSV, SASLib                       # Data loading and saving
using Dates, Missings                   # Data types
using DataStructures, DataFrames        # Data wrangling
using Statistics                        # Data analysis and statistics
using Plots, Plots.PlotMeasures         # Data visualization
using Distributions #, DistributionsUtils # Probability distributions
using Optim                             # Parameter optimization
using JLD2, Serialization               # Julia data structures saving
using ProgressMeter                     # Progress bar
using ICD_GEMs                          # ICD-10 <-> ICD-9 conversion via GEMs
using Base.Threads                      # Multithreading

include("utilities.jl");

const absolute_path_to_input_data = raw"C:\Progetti\True_input" # "./Fake_input" # "/Users/pietro/GitHub/SEPI/Fake_input" 

# Define paths to .sas7bdat files
const join_all_path              = joinpath(absolute_path_to_input_data, "join_all.sas7bdat")
const positivi_quarantena_path   = joinpath(absolute_path_to_input_data, "positivi_quarantena.sas7bdat")
const trasf_trasposti_path       = joinpath(absolute_path_to_input_data, "trasf_trasposti.sas7bdat")
const mort_2015_2018_path        = joinpath(absolute_path_to_input_data, "mort_2015_2018.sas7bdat")
const trasf_trasposti_15_19_path = joinpath(absolute_path_to_input_data, "trasf_trasposti_15_19_rev.sas7bdat")

# Load .sas7bdat files and convert them to DataFrames
const join_all_df              = load_sas7bdat(join_all_path)
const positivi_quarantena_df   = load_sas7bdat(positivi_quarantena_path)
const trasf_trasposti_df       = load_sas7bdat(trasf_trasposti_path)
const mort_2015_2018_df        = load_sas7bdat(mort_2015_2018_path)
const trasf_trasposti_15_19_df = load_sas7bdat(trasf_trasposti_15_19_path)

const raw_line_list_pi_10_de = CSV.read(raw"C:\Progetti\Intermediate_Output\riabilitativo\2-raw_line_list\COVID-19\pi_10\raw_line_list_pi_10.csv", DataFrame)

const line_list_ricoveri_quarantene_pi_10_de = CSV.read(raw"C:\Progetti\Intermediate_Output\riabilitativo\4-quarantine_isolation\COVID-19\pi_10\line_list_ricoveri_quarantene_pi_10.csv", DataFrame)

const line_list_ricoveri_pi_10_de = CSV.read(raw"C:\Progetti\Intermediate_Output\riabilitativo\3-hospitalization_period\COVID-19\pi_10\line_list_ricoveri_pi_10.csv", DataFrame)

const processed_line_list_pi_10_de  = CSV.read(raw"C:\Progetti\Intermediate_Output\riabilitativo\7-processed_line_lists\COVID-19\line_list_ricoveri_quarantene_fp_is_lim_pi_10.csv", DataFrame)

processed_line_list_pi_10[.!ismissing.(processed_line_list_pi_10.data_FQO) .& .!ismissing.(processed_line_list_pi_10.data_G) .& (processed_line_list_pi_10.data_FQO .> processed_line_list_pi_10.data_G), :]

processed_line_list_pi_10[processed_line_list_pi_10.ID .== 63, :]

ID = 63
println(join_all_df[join_all_df.ID_SOGGETTO .== ID, :])
println(positivi_quarantena_df_de[positivi_quarantena_df_de.ID_SOGGETTO .== ID, :])
println(trasf_trasposti_df_de[trasf_trasposti_df_de.ID_SOGGETTO .== ID, :])
println(line_list_ricoveri_pi_10_de[line_list_ricoveri_pi_10_de.ID .== ID,:])
println(line_list_ricoveri_quarantene_pi_10_de[line_list_ricoveri_quarantene_pi_10_de.ID .== ID,:])
println(processed_line_list_pi_10_de[processed_line_list_pi_10_de.ID .== ID, :])

trasf_trasposti_df[(trasf_trasposti_df.dt_ammiss .== Date("2020-03-07")) .& (trasf_trasposti_df.dt_uscita .== Date("2020-03-18")), :]

skipmissing([Date("2020-03-18"), missing, missing])

maximum(skipmissing([Date("2020-03-18"), missing, missing]))

sort()
line_list_ricoveri_quarantene_fp_is_pi_10[in.(line_list_ricoveri_quarantene_fp_is_pi_10.ID , Ref([4,5,19])), :]

line_list_ricoveri_quarantene_fp_is_pi_10[]