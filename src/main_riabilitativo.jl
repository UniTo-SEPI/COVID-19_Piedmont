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
using Random                            # Randomizing 


#############################
##### CUSTOM FUNCTIONS ######
#############################

# Include Julia files containing all the necessary functions
#= include("./Code/Julia/utilities.jl");
include("./Code/Julia/raw_line_list.jl");
include("./Code/Julia/sdo_sm.jl")
include("./Code/Julia/processed_line_list.jl");
include("./Code/Julia/sequences.jl");
include("./Code/Julia/time_delays.jl");
include("./Code/Julia/plotting.jl"); =#


include("utilities.jl");
include("raw_line_list.jl");
include("sdo_sm.jl")
include("processed_line_list.jl");
include("sequences.jl");
include("time_delays.jl");
include("plotting.jl");

#############################
####### INSTRUCTIONS ########
#############################

# Please set the pwd to the root folder of SEPI repository (if you are using VSCode, click File -> Open Folder -> .../SEPI)

# Path to SEPI repository folder
const absolute_path_to_repository_moroni    = "D:\\GitHub\\SEPI"
const absolute_path_to_repository_monticone = "/Users/pietro/GitHub/SEPI"
const absolute_path_to_repository_strippoli = raw"//SERVER-EPI5/dati_progetti/covid19/Valorizzazioni/ISI/SEPI-main"   
const absolute_path_to_repository_ferracin  = raw"C:\Progetti\SEPI"
const absolute_path_to_repository           = absolute_path_to_repository_ferracin

# Include Julia file with folder structure creation utilities
# include("./Code/Julia/folder_structure.jl");
include(".\\folder_structure.jl");

# Path to folder that contains:
# - join_all.sas7bdat
# - positivi_quarantena.sas7bdat
# - trasf_trasposti.sas7bdat
# - mort_2015_2018.sas7bdat
# - trasf_trasposti_15_19.sas7bdat
#
# It must be absolute since these data cannot be part of the repository
const absolute_path_to_input_data = raw"C:\Progetti\True_input" # "./Fake_input" # "/Users/pietro/GitHub/SEPI/Fake_input" 

const run_name = "riabilitativo"

# Path to folder that will contain intermediate outputs
# It must be absolute since these data cannot be part of the repository
const absolute_path_to_intermediate_output = raw"C:\Progetti\Intermediate_Output" # "./True_intermediate_output" #"./tmp/intermediate_output" #/Users/pietro/GitHub/SEPI/tmp/intermediate_output"
# Create intermediate output folder structure
make_intermediate_output_folder_structure(absolute_path_to_intermediate_output, run_name )

# Absolute path to output folder
const absolute_path_to_output =  ".\\Output" # "./True_output" #".\\tmp\\output"
# Create output folder structure
make_output_folder_structure(absolute_path_to_output, run_name)

# Absolute path to folder where to store intermediate plots
#const absolute_path_to_intermediate_plots = ".\\tmp\\intermediate_plots" #"./tmp/intermediate_plots" #"/Users/pietro/GitHub/SEPI/tmp/intermediate_plots"
# Create output folder structure
# make_intermediate_plots_folder_structure(absolute_path_to_intermediate_plots)

# Absolute path to folder where to store output
const absolute_path_to_output_plots = ".\\Output_Plots"
# Create output plots folder structure
make_output_plots_folder_structure(absolute_path_to_output_plots, run_name)

const save = true
const skip_sdo_pre_processing = false


#############################
###### PRE-PROCESSING #######
#############################

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

# Define dictionary of the names of dates of key events
const events_dates_names = Dict( :data_P   => :data_P,
                                 :data_IS  => :data_IS,
                                 :date_IQ  => :date_IQ,
                                 :date_FQ  => :date_FQ,
                                 :data_IQP => :data_IQP,
                                 :data_FQP => :data_FQP,
                                 :data_IQO => :data_IQO,
                                 :data_FQO => :data_FQO,
                                 :data_AO  => :data_AO,
                                 :data_DO  => :data_DO,
                                 :data_AI  => :data_AI,
                                 :data_DI  => :data_DI,
                                 :data_AR  => :data_AR,
                                 :data_DR  => :data_DR,
                                 :data_G   => :data_G,
                                 :data_D   => :data_D)

# Define the dictionary linking age classes as reported in the input data to their interval representation
const age_classes_representations = Dict( 0 => "[0,39]" ,
                                         40 => "[40,59]",
                                         60 => "[60,69]",
                                         70 => "[70,79]",
                                         80 => "[80+]"
                                        )

# Define missing values placeholder (MVP) and associated check function (is_MVP)
const MVP    = missing
const is_MVP = ismissing

# Load GEMs
const I10_I9_GEMs_dict = get_GEM_dict_from_cdc_gem_txt(".\\Code\\Julia\\ICD_GEMs.jl\\raw_gems\\2018_I10gem.txt", "I10_I9")

# ICD-10 -> ICD-9 translations of InPhyT 2022 codes
const ICD_9_CM_translations = Dict(
                                "Intestinal infections"    => execute_applied_mapping(I10_I9_GEMs_dict, ["A00-A09"], "all"),
                                "Intestinal complications" => execute_applied_mapping(I10_I9_GEMs_dict, ["A00-A09", "K50-K67"], "all"),
                                "Some infectious diseases" => execute_applied_mapping(I10_I9_GEMs_dict, ["A00-A99", "B00-B99"], "all"),
                                "Sepsis and bacterial infections of unspecified site" => execute_applied_mapping(I10_I9_GEMs_dict, ["A40-A41", "A49", "B34", "B37", "B44", "B99"], "all"),
                                "Sepsis, septic shock, and infections" => execute_applied_mapping(I10_I9_GEMs_dict, ["A40–A41", "A49", "B25–B49", "B99", "R572"], "all"),
                                "Neoplasms" => execute_applied_mapping(I10_I9_GEMs_dict, ["C00-C99","D00-D48"], "all"),
                                "Diseases of blood and blood forming organs" => execute_applied_mapping(I10_I9_GEMs_dict, ["D50-D99"], "all"),
                                "Endocrine diseases" => execute_applied_mapping(I10_I9_GEMs_dict, ["E10-E14"], "all"),
                                "Nutritional disorders" => execute_applied_mapping(I10_I9_GEMs_dict, ["E40-E46"], "all"),
                                "Obesity" => execute_applied_mapping(I10_I9_GEMs_dict, ["E66"], "all"),
                                "Other diseases of the metabolism" => execute_applied_mapping(I10_I9_GEMs_dict, ["E70-E90"], "all"),
                                "Mental and behavioural disorders" => execute_applied_mapping(I10_I9_GEMs_dict, ["F00-F99"], "all"),
                                "Other diseases of the nervous system" => execute_applied_mapping(I10_I9_GEMs_dict, ["G00-G99", "H00-H99"], "all"),
                                "Encephalitis, myelitis and encephalomyelitis" => execute_applied_mapping(I10_I9_GEMs_dict, ["G04, G93"], "all"),
                                "Specified cardiac diseases" => execute_applied_mapping(I10_I9_GEMs_dict, ["I00-I09", "I27-I45", "I47", "I52"], "all"),
                                "Hypertensive heart diseases" => execute_applied_mapping(I10_I9_GEMs_dict, ["I10-I15"], "all"),
                                "Myocardial infarction" => execute_applied_mapping(I10_I9_GEMs_dict, ["I20-I24"], "all"),
                                "Acute myocardial infarction" => execute_applied_mapping(I10_I9_GEMs_dict, ["I21"], "all"),
                                "Pulmonary embolism" => execute_applied_mapping(I10_I9_GEMs_dict, ["I26"], "all"),
                                "Other circulatory diseases" => execute_applied_mapping(I10_I9_GEMs_dict, ["I70-I79", "I83-I89", "I95-I99"], "all"),
                                "Cardiac arrest" => execute_applied_mapping(I10_I9_GEMs_dict, ["I46"], "all"),
                                "Atrial fibrillation and other arrhythmias" => execute_applied_mapping(I10_I9_GEMs_dict, ["I48-I49"], "all"),
                                "Heart complications (heart failure and unspecified cardiac disease)" => execute_applied_mapping(I10_I9_GEMs_dict, ["I50-I51"], "all"),
                                "Acute cerebrovascular accidents" => execute_applied_mapping(I10_I9_GEMs_dict, ["I60-I64"], "all"),
                                "Phlebitis, thrombophlebitis and thrombosis of peripheral vessels" => execute_applied_mapping(I10_I9_GEMs_dict, ["I80-I82"], "all"),
                                "Other respiratory diseases" => execute_applied_mapping(I10_I9_GEMs_dict, ["J00-J99"], "all"),
                                "Pneumonia-Grippo" => execute_applied_mapping(I10_I9_GEMs_dict, ["J12-J18", "J84","J98"], "all"),
                                "Pneumonia-Orsi" => execute_applied_mapping(I10_I9_GEMs_dict, ["J12-J18", "J849"], "all"),
                                "ARDS and pulmonary oedema" => execute_applied_mapping(I10_I9_GEMs_dict, ["J80-J81"], "all"),
                                "Adult respiratory distress syndrome (ARDS)" => execute_applied_mapping(I10_I9_GEMs_dict, ["J80"], "all"),
                                "Respiratory failure" => execute_applied_mapping(I10_I9_GEMs_dict, ["J960", "J969"], "all"),
                                "Respiratory failure and related symptoms" => execute_applied_mapping(I10_I9_GEMs_dict, ["J96", "R04", "R06", "R09"], "all"),
                                "Other diseases of the digestive system" => execute_applied_mapping(I10_I9_GEMs_dict, ["K00-K99"], "all"),
                                "Other diseases of intestine and peritoneum" => execute_applied_mapping(I10_I9_GEMs_dict, ["K50-K67"], "all"),
                                "Chronic liver diseases" => execute_applied_mapping(I10_I9_GEMs_dict, ["K70-K77"], "all"),
                                "Diseases of the musculoskeletal system and connective tissue" => execute_applied_mapping(I10_I9_GEMs_dict, ["M00-M99"], "all"),                               
                                "Kidney failure" => execute_applied_mapping(I10_I9_GEMs_dict, ["N00", "N04", "N17", "N19"], "all"),
                                "Renal failure" => execute_applied_mapping(I10_I9_GEMs_dict, ["N17", "N19"], "all"),
                                "Other diseases of the genitourinary system" => execute_applied_mapping(I10_I9_GEMs_dict, ["N00-N99"], "all"),
                                "Symptoms and signs involving the respiratory system" => execute_applied_mapping(I10_I9_GEMs_dict, ["R04-R09"], "all"),
                                "Shock" => execute_applied_mapping(I10_I9_GEMs_dict, ["R57"], "all"),
                                "Shock (cardiogenic)" => execute_applied_mapping(I10_I9_GEMs_dict, ["R57 "], "all"),
                                "Systemic inflammatory response syndrome (SIRS)" => execute_applied_mapping(I10_I9_GEMs_dict, ["R65"], "all"),
                                "External causes" => execute_applied_mapping(I10_I9_GEMs_dict, ["S00-S99", "T00-T98", "V01-V99", "W00-W99", "X00-X99", "Y00-Y98"], "all")
)

#ICD-10 -> ICD-9 transaltions of Orsi 2021 codes
const ICD_9_CM_translations_orsi = Dict(
                                # Antencedents
                                "Neoplasms"                          => execute_applied_mapping(I10_I9_GEMs_dict, ["C00-C99", "D00-D48"], "all"),
                                "Chronic lower respiratory diseases" => execute_applied_mapping(I10_I9_GEMs_dict, ["J40-J47"], "all"),
                                "Cerebrovascular accident"           => execute_applied_mapping(I10_I9_GEMs_dict, ["I60-I66", "I670", "I672-I679"], "all"),
                                "Hypertensive heart disease"         => execute_applied_mapping(I10_I9_GEMs_dict, ["I10-I13"], "all"),
                                "Dementia"                           => execute_applied_mapping(I10_I9_GEMs_dict, ["F00-F03"], "all"),
                                "Chronic ischemic heart disease" => execute_applied_mapping(I10_I9_GEMs_dict, ["I25"], "all"),
                                "Diabetes mellitus" => execute_applied_mapping(I10_I9_GEMs_dict, ["E10-E14"], "all"),
                                "Atrial fibrillation" => execute_applied_mapping(I10_I9_GEMs_dict, ["I48"], "all"),
                                "Alzheimer disease" => execute_applied_mapping(I10_I9_GEMs_dict, ["G30-G31"], "all"),
                                "Chronic renal failure" => execute_applied_mapping(I10_I9_GEMs_dict, ["N18"], "all"),
                                # Precipitating conditions
                                "Heart failure and other cardiac diseases" => execute_applied_mapping(I10_I9_GEMs_dict, ["I50-I51"], "all"),
                                "Sepsis and infections of unspecified site" => execute_applied_mapping(I10_I9_GEMs_dict, ["A40-A41", "B37", "B49", "B99"], "all"),
                                "Shock" => execute_applied_mapping(I10_I9_GEMs_dict, ["R570-R571", "R573-R579"], "all"),
                                "Renal failure, acute and unspecified" => execute_applied_mapping(I10_I9_GEMs_dict, ["N17", "N19"], "all"),
                                "Other diseases of the respiratory system" => execute_applied_mapping(I10_I9_GEMs_dict, ["J00-J11", "J30-J39", "J60-J70", "J820-J848", "J85-J99"], "all"),
                                "Volume depletion and other fluid disorders" => execute_applied_mapping(I10_I9_GEMs_dict, ["E86-E87"], "all"),
                                "Acute ischemic heart diseases" => execute_applied_mapping(I10_I9_GEMs_dict, ["I20-I24"], "all"),
                                "Pulmonary embolism" => execute_applied_mapping(I10_I9_GEMs_dict, ["I26"], "all"),
                                "Other infectious and parasitic diseases" => execute_applied_mapping(I10_I9_GEMs_dict, ["A00-A39", "A42-A99", "B00-B36", "B38-B48", "B50-B98"], "all"),
                                "Other circulatory diseases" => execute_applied_mapping(I10_I9_GEMs_dict, ["I00-I09", "I90-I99"], "all"),
                                "Pulmonary oedema" => execute_applied_mapping(I10_I9_GEMs_dict, ["J81"], "all"),
                                # Complications
                                "Pneumonia" => execute_applied_mapping(I10_I9_GEMs_dict, ["J12-J18", "J849"], "all"),
                                "Respiratory failure" => execute_applied_mapping(I10_I9_GEMs_dict, ["J960", "J969"], "all"),
                                "Adult respiratory distress syndrome (ARDS)" => execute_applied_mapping(I10_I9_GEMs_dict, ["J80"], "all"),
                                "Symptoms and signs involving the respiratory system" => execute_applied_mapping(I10_I9_GEMs_dict, ["R04-R09"], "all"),
                                "Systemic inflammatory response syndrome (SIRS)" => execute_applied_mapping(I10_I9_GEMs_dict, ["R65"], "all"))


# Convert codes to string (padding with zeros so that there are always three digits before the ".", and remove the dot)
const all_codes = [string(code) for code in  unique(vcat(collect(values(ICD_9_CM_translations_orsi))...))]
# All codes converted to strings ad truncated at the third digit
const all_codes_converted_to_strings_censored = convert_ICD9_codes_to_strings(all_codes, 3)

## Save the string codes as an array (by writing it as a string to file  returning every 20 codes to improve readability)
string_variable = nothing
open(joinpath(absolute_path_to_output, "ICD9_codes\\ICD9_codes_returned_orsi.txt"), "w") do file
    string_variable = string(all_codes_converted_to_strings_censored)
    string_variable_splitted = split(string_variable,",")
    for (i,code) in enumerate(string_variable_splitted)
        if i%20 == 0
            insert!(string_variable_splitted, i, "\n")
        end
    end
    string_variable =  join(string_variable_splitted, ",")
    string_variable = replace(string_variable, ",\n," => ",\n")
    println(string_variable)
    write(file, string_variable)
end

# Define aggregations
const ICD_9_CM_aggregations = Dict("aggregations" => ICD_9_CM_translations_orsi, "n_digits" => nothing)



# Process `join_all_df`, to give it proper format and column names.
# The function checks that each line of every datasets with different plausibility intervals (pi) has either a data_G XOR a data_D to ensure consistency
const join_all_processed_df_pi_30, join_all_processed_df_pi_20, join_all_processed_df_pi_10 = process_join_all(join_all_df, events_dates_names; MVP = MVP, is_MVP = is_MVP)

# Process `positivi_quarantena_df`, to give it proper format and column names
const positivi_quarantena_processed_df = process_positivi_quarantena(positivi_quarantena_df, events_dates_names; MVP = MVP, is_MVP = is_MVP)

# Process `trasf_trasposti_df`, to give it proper format and column names
const trasf_trasposti_processed_df = process_trasf_trasposti(trasf_trasposti_df)

if save
    # Save these intermediate outputs
    ## join_all
    CSV.write(joinpath(absolute_path_to_intermediate_output, run_name, "1-pre_processing/COVID-19/join_all_processed_pi_30.csv"), join_all_processed_df_pi_30)
    CSV.write(joinpath(absolute_path_to_intermediate_output, run_name, "1-pre_processing/COVID-19/join_all_processed_pi_20.csv"), join_all_processed_df_pi_20)
    CSV.write(joinpath(absolute_path_to_intermediate_output, run_name, "1-pre_processing/COVID-19/join_all_processed_pi_10.csv"), join_all_processed_df_pi_10)
    ## positivi_quarantena
    CSV.write(joinpath(absolute_path_to_intermediate_output, run_name, "1-pre_processing/COVID-19/positivi_quarantena_processed.csv"), positivi_quarantena_processed_df)
    ## trasf_trasposti
    CSV.write(joinpath(absolute_path_to_intermediate_output, run_name, "1-pre_processing/COVID-19/trasf_trasposti_processed.csv"), trasf_trasposti_processed_df)
end


# SDO
## If sdo_skip_pre_processing, attempt to load sdo-related pre-processing data from intermediate_output/sdo_skip_pre_processing, else compute such datasets
const trasf_trasposti_15_19_multiple_ricoveros_per_patient_processed, ICD9CM_processedTrasfTraspostiOne_dct, ICD9CM_processed_joinAll_dct, ICD9CM_processedPositiviQuarantena_dct = DataFrame(), OrderedDict{String, DataFrame}(), OrderedDict{String, DataFrame}(), OrderedDict{String, DataFrame}()
const ICD_9_CM_actual = String[]
if !skip_sdo_pre_processing
    # Process datasets from SDO and schede di morte
    trasf_trasposti_15_19_multiple_ricoveros_per_patient_processed, ICD9CM_processedTrasfTraspostiOne_dct, ICD9CM_processed_joinAll_dct, ICD9CM_processedPositiviQuarantena_dct  = process_trasf_trasposti_15_19_and_mort_2015_2018(trasf_trasposti_15_19_df;  ICD_9_CM_aggregations = ICD_9_CM_aggregations, MVP = MVP, is_MVP =is_MVP) # mort_2015_2018_processed # mort_2015_2018_df

    # Get codes that actually existed in datasets
    @assert length(setdiff(keys(ICD9CM_processedTrasfTraspostiOne_dct),keys(ICD9CM_processed_joinAll_dct))) == length(setdiff(keys(ICD9CM_processedTrasfTraspostiOne_dct),keys(ICD9CM_processedPositiviQuarantena_dct))) == 0
    const ICD_9_CM_actual = collect(keys(ICD9CM_processedTrasfTraspostiOne_dct))

    if save
        ## Save datasets to CSV
        CSV.write(joinpath(absolute_path_to_intermediate_output, run_name, "1-pre_processing/SDO/trasf_trasposti_15_19_mul_ric_pat_proc.csv"), trasf_trasposti_15_19_multiple_ricoveros_per_patient_processed)

        for (ICD_9_CM, diagnosis_dataframe) in collect(ICD9CM_processedTrasfTraspostiOne_dct)
            CSV.write(joinpath(absolute_path_to_intermediate_output, run_name, "1-pre_processing/SDO/trasf_trasposti_SDO_OneRicoveroPerPatient_groupedby_ICD_9_CM/trasf_trasposti_SDO_$(ICD_9_CM).csv"), diagnosis_dataframe)
        end

        for (ICD_9_CM, diagnosis_dataframe) in collect(ICD9CM_processed_joinAll_dct)
            CSV.write(joinpath(absolute_path_to_intermediate_output, run_name, "1-pre_processing/SDO/mort_SDO_OneRicoveroPerPatient_groupedby_ICD_9_CM/join_all_SDO_$(ICD_9_CM).csv"), diagnosis_dataframe)
        end

        for (ICD_9_CM, positivi_quarantena_dataframe) in collect(ICD9CM_processedPositiviQuarantena_dct)
            CSV.write(joinpath(absolute_path_to_intermediate_output,  run_name, "1-pre_processing/SDO/positivi_quarantena_SDO_groupedby_ICD_9_CM/positivi_quarantena_SDO_$(ICD_9_CM).csv"), positivi_quarantena_dataframe)
        end

        ## Save datasets as julia objects
        save_julia_variable(trasf_trasposti_15_19_multiple_ricoveros_per_patient_processed, joinpath(absolute_path_to_intermediate_output, run_name, "1-pre_processing/SDO/skip_sdo_pre_processing/trasf_trasposti_15_19_mul_ric_pat_proc"), "trasf_trasposti_15_19_mul_ric_pat_proc" )

        save_julia_variable(ICD9CM_processedTrasfTraspostiOne_dct, joinpath(absolute_path_to_intermediate_output, run_name, "1-pre_processing/SDO/skip_sdo_pre_processing/ICD9CM_processedTrasfTraspostiOne_dct"), "ICD9CM_processedTrasfTraspostiOne_dct" )

        save_julia_variable(ICD9CM_processed_joinAll_dct, joinpath(absolute_path_to_intermediate_output, run_name, "1-pre_processing/SDO/skip_sdo_pre_processing/ICD9CM_processed_joinAll_dct"), "ICD9CM_processed_joinAll_dct" )

        save_julia_variable(ICD9CM_processedPositiviQuarantena_dct, joinpath(absolute_path_to_intermediate_output, run_name, "1-pre_processing/SDO/skip_sdo_pre_processing/ICD9CM_processedPositiviQuarantena_dct"), "ICD9CM_processedPositiviQuarantena_dct" )

    end

else

    trasf_trasposti_15_19_multiple_ricoveros_per_patient_processed = load_julia_variable(joinpath(absolute_path_to_intermediate_output, "1-pre_processing\\SDO\\skip_sdo_pre_processing\\trasf_trasposti_15_19_mul_ric_pat_proc"))

    ICD9CM_processedTrasfTraspostiOne_dct                          = load_julia_variable(joinpath(absolute_path_to_intermediate_output, run_name, "1-pre_processing\\SDO\\skip_sdo_pre_processing\\ICD9CM_processedTrasfTraspostiOne_dct"))

    ICD9CM_processed_joinAll_dct                                   = load_julia_variable(joinpath(absolute_path_to_intermediate_output, run_name, "1-pre_processing\\SDO\\skip_sdo_pre_processing\\ICD9CM_processed_joinAll_dct"))

    ICD9CM_processedPositiviQuarantena_dct                         = load_julia_variable(joinpath(absolute_path_to_intermediate_output, run_name, "1-pre_processing\\SDO\\skip_sdo_pre_processing\\ICD9CM_processedPositiviQuarantena_dct"))

    ICD_9_CM_actual = collect(keys(ICD9CM_processedTrasfTraspostiOne_dct))
end

# Output line-lists by outer-joining on `ID` columns.
## uw = upper whisker
## COVID-19 data
# include("./Code/Julia/raw_line_list.jl");
const line_lists_columns = [:ID, :classe_eta, :data_IS, :data_P, :date_IQ, :date_FQ, :ricoveri, :data_G, :data_D]
const raw_line_list_pi_30, P_FP_uw_pi_30, P_G_uw_pi_30, P_D_uw_pi_30 = outerjoin_and_replace_missing(join_all_processed_df_pi_30, positivi_quarantena_processed_df, trasf_trasposti_processed_df, line_lists_columns; on = [:ID], MVP = MVP, is_MVP = is_MVP)
const raw_line_list_pi_20, P_FP_uw_pi_20, P_G_uw_pi_20, P_D_uw_pi_20 = outerjoin_and_replace_missing(join_all_processed_df_pi_20, positivi_quarantena_processed_df, trasf_trasposti_processed_df, line_lists_columns; on = [:ID], MVP = MVP, is_MVP = is_MVP)
const raw_line_list_pi_10, P_FP_uw_pi_10, P_G_uw_pi_10, P_D_uw_pi_10 = outerjoin_and_replace_missing(join_all_processed_df_pi_10, positivi_quarantena_processed_df, trasf_trasposti_processed_df, line_lists_columns; on = [:ID], MVP = MVP, is_MVP = is_MVP)

const covid_19_upper_whiskers = Dict("P_FP_uw_pi_30" => P_FP_uw_pi_30, "P_G_uw_pi_30" =>P_G_uw_pi_30, "P_D_uw_pi_30" =>P_D_uw_pi_30,"P_FP_uw_pi_20" =>P_FP_uw_pi_20, "P_G_uw_pi_20" =>P_G_uw_pi_20, "P_D_uw_pi_20" =>P_D_uw_pi_20, "P_FP_uw_pi_10" =>P_FP_uw_pi_10, "P_G_uw_pi_10" =>P_G_uw_pi_10, "P_D_uw_pi_10" => P_D_uw_pi_10)

## SDO data
## We save upper and lower whiskers (although they have no meaning for SDOs as we will disregard imputed qurantines before 2020) since later functions require them as arguments.
const raw_line_lists_SDO = OrderedDict{String, DataFrame}()
const P_FP_uws_SDO = OrderedDict{String, Dates.Day}()
const P_G_uws_SDO = OrderedDict{String, Dates.Day}()
const P_D_uws_SDO = OrderedDict{String, Dates.Day}()

for ICD_9_CM in ICD_9_CM_actual
    raw_line_list_SDO, P_FP_uw_SDO, P_G_uw_SDO, P_D_uw_SDO = outerjoin_and_replace_missing(ICD9CM_processed_joinAll_dct[ICD_9_CM], ICD9CM_processedPositiviQuarantena_dct[ICD_9_CM], ICD9CM_processedTrasfTraspostiOne_dct[ICD_9_CM], line_lists_columns; on = [:ID], MVP = MVP, is_MVP = is_MVP)
    push!(raw_line_lists_SDO, ICD_9_CM => raw_line_list_SDO)
    push!(P_FP_uws_SDO, ICD_9_CM   => P_FP_uw_SDO)
    push!(P_G_uws_SDO, ICD_9_CM    => P_G_uw_SDO)
    push!(P_D_uws_SDO, ICD_9_CM    => P_D_uw_SDO)
end

# const sdo_upper_whiskers = Dict("P_FP_uws_SDO" => P_FP_uws_SDO, "P_G_uws_SDO" => P_G_uws_SDO, "P_D_uws_SDO" => P_D_uws_SDO  )

if save
    # Save intermediate_output raw_line_list
    ## COVID-19 data
    CSV.write(joinpath(absolute_path_to_intermediate_output, run_name, "2-raw_line_list/COVID-19/pi_30/raw_line_list_pi_30.csv"), raw_line_list_pi_30)
    CSV.write(joinpath(absolute_path_to_intermediate_output, run_name, "2-raw_line_list/COVID-19/pi_20/raw_line_list_pi_20.csv"), raw_line_list_pi_20)
    CSV.write(joinpath(absolute_path_to_intermediate_output, run_name, "2-raw_line_list/COVID-19/pi_10/raw_line_list_pi_10.csv"), raw_line_list_pi_10)
    ## COVID-19 upper whiskers 
    jldsave(joinpath(absolute_path_to_output, run_name,"upper_whiskers/COVID-19/upper_whiskers_covid_19.jld2"); upper_whiskers = covid_19_upper_whiskers )
    Serialization.serialize(joinpath(absolute_path_to_output, run_name,"upper_whiskers/COVID-19/upper_whiskers_covid_19.jls"), covid_19_upper_whiskers)
    open(joinpath(absolute_path_to_output, run_name,"upper_whiskers/COVID-19/upper_whiskers_covid_19.txt"), "w") do file
        write(file, string(covid_19_upper_whiskers))
    end;
    ## SDO data
    # We don't save this processing step for SDO data since this dataset would present dates that are just a made-up variables needed to have the piepline working . We will just
    # for (ICD_9_CM, raw_line_list) in collect(raw_line_lists_SDO)
    #     CSV.write(joinpath(absolute_path_to_intermediate_output, "2-raw_line_list/SDO/raw_line_list_SDO_$ICD_9_CM.csv", raw_line_list)
    # end
end

#############################
######### RICOVERI ##########
#############################

## COVID-19 data
# include("./Code/Julia/processed_line_list.jl");
const with_riabilitativo = true
const line_list_ricoveri_pi_30, data_quality_IDs_ricoveri_pi_30, data_quality_ricoveri_pi_30 = process_ricoveri(raw_line_list_pi_30, events_dates_names; with_riabilitativo = with_riabilitativo, MVP = MVP, is_MVP = is_MVP)
const line_list_ricoveri_pi_20, data_quality_IDs_ricoveri_pi_20, data_quality_ricoveri_pi_20 = process_ricoveri(raw_line_list_pi_20, events_dates_names; with_riabilitativo = with_riabilitativo, MVP = MVP, is_MVP = is_MVP)
const line_list_ricoveri_pi_10, data_quality_IDs_ricoveri_pi_10, data_quality_ricoveri_pi_10 = process_ricoveri(raw_line_list_pi_10, events_dates_names; with_riabilitativo = with_riabilitativo, MVP = MVP, is_MVP = is_MVP)

## SDO data
line_lists_ricoveri_SDO            = OrderedDict{String, DataFrame}()
data_quality_IDs_ricoveri_SDO      = OrderedDict{String, Dict{String, Any}}()
data_quality_ricoveri_SDO          =  OrderedDict{String, Dict{String, Int64}}()
for ICD_9_CM in ICD_9_CM_actual
    line_list_ricoveri_SDO, data_quality_IDs_SDO, data_quality_SDO = process_ricoveri(raw_line_lists_SDO[ICD_9_CM], events_dates_names; with_riabilitativo = with_riabilitativo, MVP = MVP, is_MVP = is_MVP)
    push!(line_lists_ricoveri_SDO, ICD_9_CM => line_list_ricoveri_SDO)
    push!(data_quality_IDs_ricoveri_SDO, ICD_9_CM => data_quality_IDs_SDO)
    push!(data_quality_ricoveri_SDO, ICD_9_CM => data_quality_SDO)
end

if save
    # Save intermediate_output hospitalization_period
    ## COVID-19
    CSV.write(joinpath(absolute_path_to_intermediate_output, run_name, "3-hospitalization_period/COVID-19/pi_30/line_list_ricoveri_pi_30.csv"), line_list_ricoveri_pi_30)
    CSV.write(joinpath(absolute_path_to_intermediate_output, run_name,"3-hospitalization_period/COVID-19/pi_20/line_list_ricoveri_pi_20.csv"), line_list_ricoveri_pi_20)
    CSV.write(joinpath(absolute_path_to_intermediate_output, run_name,"3-hospitalization_period/COVID-19/pi_10/line_list_ricoveri_pi_10.csv"), line_list_ricoveri_pi_10)
    ## COVID-19 data quality
    ### IDs
    for (data_quality_IDs,pi_string) in zip((data_quality_IDs_ricoveri_pi_30, data_quality_IDs_ricoveri_pi_20, data_quality_IDs_ricoveri_pi_10),("pi_30","pi_20","pi_10"))
        save_julia_variable(data_quality_IDs, joinpath(absolute_path_to_intermediate_output, run_name, "3-hospitalization_period/COVID-19", pi_string, "data_quality"), "data_quality_ricoveri_$(pi_string)_IDs" )
    end
    ### Aggregated
    for (data_quality,pi_string) in zip((data_quality_ricoveri_pi_30, data_quality_ricoveri_pi_20, data_quality_ricoveri_pi_10),("pi_30","pi_20","pi_10"))
        save_julia_variable(data_quality, joinpath(absolute_path_to_output, run_name,"3-hospitalization_period/COVID-19", pi_string, "data_quality"), "data_quality_ricoveri_$(pi_string)" )
    end
    ## SDO
    # We don't save this processing step for SDO data since this dataset would present dates that are just a made-up variables needed to have the piepline working 
    for (ICD_9_CM, line_list_ricoveri_SDO) in collect(line_lists_ricoveri_SDO)
        CSV.write(joinpath(absolute_path_to_intermediate_output, run_name, "3-hospitalization_period/SDO/line_list_ricoveri_SDO_$ICD_9_CM.csv"), line_list_ricoveri_SDO)
    end
    ## SDO data quality
    ### IDs
    save_julia_variable(data_quality_IDs_ricoveri_SDO, joinpath(absolute_path_to_intermediate_output, run_name, "3-hospitalization_period/SDO", "data_quality"), "data_quality_ricoveri_SDO_IDs" )
    ### Aggregated
    save_julia_variable(data_quality_ricoveri_SDO, joinpath(absolute_path_to_output, run_name, "3-hospitalization_period/SDO", "data_quality"), "data_quality_ricoveri_SDO" )
end


#############################
######## QUARANTENE #########
#############################

# COVID-19 data
# include("./Code/Julia/processed_line_list.jl");
const T_quarantena                        = Dates.Day(14);
const line_lists_quarantene_columns       = [:ID, :classe_eta, :data_IS, :data_P, :data_IQP, :data_FQP, :data_IQO, :data_FQO, :data_AO, :data_DO, :data_AI, :data_DI, :data_AR, :data_DR, :data_G, :data_D]
const line_list_ricoveri_quarantene_pi_30, data_quality_IDs_quarantene_pi_30, data_quality_quarantene_pi_30 = process_quarantene_compact(line_list_ricoveri_pi_30, events_dates_names, T_quarantena, P_G_uw_pi_30, P_D_uw_pi_30, line_lists_quarantene_columns; MVP = MVP, is_MVP = is_MVP)
const line_list_ricoveri_quarantene_pi_20, data_quality_IDs_quarantene_pi_20, data_quality_quarantene_pi_20 = process_quarantene_compact(line_list_ricoveri_pi_20, events_dates_names, T_quarantena, P_G_uw_pi_20, P_D_uw_pi_20, line_lists_quarantene_columns; MVP = MVP, is_MVP = is_MVP)
include("processed_line_list.jl");
const line_list_ricoveri_quarantene_pi_10, data_quality_IDs_quarantene_pi_10, data_quality_quarantene_pi_10 = process_quarantene_compact(line_list_ricoveri_pi_10, events_dates_names, T_quarantena, P_G_uw_pi_10, P_D_uw_pi_10, line_lists_quarantene_columns; MVP = MVP, is_MVP = is_MVP)

# SDO data
line_lists_ricoveri_quarantene_SDO            = OrderedDict{String, DataFrame}()
data_quality_IDs_ricoveri_quarantene_SDO =  OrderedDict{String, Dict{String, Any}}()
data_quality_ricoveri_quarantene_SDO          =  OrderedDict{String, Dict{String, Int64}}()
for ICD_9_CM in ICD_9_CM_actual
    line_list_ricoveri_quarantene_SDO, data_quality_IDs_SDO, data_quality_SDO = process_quarantene_compact(line_lists_ricoveri_SDO[ICD_9_CM], events_dates_names ,T_quarantena, P_G_uws_SDO[ICD_9_CM], P_D_uws_SDO[ICD_9_CM], line_lists_quarantene_columns; MVP = MVP, is_MVP = is_MVP)
    push!(line_lists_ricoveri_quarantene_SDO, ICD_9_CM            => line_list_ricoveri_quarantene_SDO)
    push!(data_quality_IDs_ricoveri_quarantene_SDO, ICD_9_CM => data_quality_IDs_SDO)
    push!(data_quality_ricoveri_quarantene_SDO, ICD_9_CM          => data_quality_SDO)
end

if save
    # Save intermediate_output quarantine_isolation
    ## COVID-19 data
    CSV.write(joinpath(absolute_path_to_intermediate_output, run_name, "4-quarantine_isolation/COVID-19/pi_30/line_list_ricoveri_quarantene_pi_30.csv"), line_list_ricoveri_quarantene_pi_30)
    CSV.write(joinpath(absolute_path_to_intermediate_output, run_name, "4-quarantine_isolation/COVID-19/pi_20/line_list_ricoveri_quarantene_pi_20.csv"), line_list_ricoveri_quarantene_pi_20)
    CSV.write(joinpath(absolute_path_to_intermediate_output, run_name, "4-quarantine_isolation/COVID-19/pi_10/line_list_ricoveri_quarantene_pi_10.csv"), line_list_ricoveri_quarantene_pi_10)
    ## COVID-19 data quality
    ### IDs
    for (data_quality_IDs,pi_string) in zip((data_quality_IDs_quarantene_pi_30, data_quality_IDs_quarantene_pi_20, data_quality_IDs_quarantene_pi_10),("pi_30","pi_20","pi_10"))
        save_julia_variable(data_quality_IDs, joinpath(absolute_path_to_intermediate_output, run_name, "4-quarantine_isolation/COVID-19", pi_string, "data_quality"), "data_quality_ricoveri_quarantene_$(pi_string)_IDs" )
    end
    ### Aggregated
    for (data_quality,pi_string) in zip((data_quality_quarantene_pi_30, data_quality_quarantene_pi_20, data_quality_quarantene_pi_10),("pi_30","pi_20","pi_10"))
        save_julia_variable(data_quality, joinpath(absolute_path_to_output, run_name, "4-quarantine_isolation/COVID-19", pi_string, "data_quality"), "data_quality_ricoveri_quarantene_$(pi_string)" )
    end
    ## SDO data
    # We don't save this processing step for SDO data since this dataset would present dates that are just a made-up variables needed to have the piepline working 
    # for (ICD_9_CM, line_list_ricoveri_quarantene_SDO) in collect(line_lists_ricoveri_quarantene_SDO)
    #     CSV.write(joinpath(absolute_path_to_intermediate_output, run_name, "4-quarantine_isolation/SDO/line_list_ricoveri_quarantene_SDO_$ICD_9_CM.csv", line_list_ricoveri_quarantene_SDO)
    # end
    ## SDO data quality
    # We don't save this processing step for SDO data since this dataset would present dates that are just a made-up variables needed to have the piepline working 
end

##########################################
######## DATE FINE PERCORSO (FP) #########
##########################################

# COVID-19 data
const line_list_ricoveri_quarantene_fp_pi_30, data_quality_IDs_ricoveri_quarantene_fp_pi_30, data_quality_ricoveri_quarantene_fp_pi_30 = process_date_FP(line_list_ricoveri_quarantene_pi_30; MVP = MVP, is_MVP = is_MVP)
const line_list_ricoveri_quarantene_fp_pi_20, data_quality_IDs_ricoveri_quarantene_fp_pi_20, data_quality_ricoveri_quarantene_fp_pi_20 = process_date_FP(line_list_ricoveri_quarantene_pi_20; MVP = MVP, is_MVP = is_MVP)
const line_list_ricoveri_quarantene_fp_pi_10, data_quality_IDs_ricoveri_quarantene_fp_pi_10, data_quality_ricoveri_quarantene_fp_pi_10 = process_date_FP(line_list_ricoveri_quarantene_pi_10; MVP = MVP, is_MVP = is_MVP)
# SDO data
line_lists_ricoveri_quarantene_fp_SDO = OrderedDict{String, DataFrame}()
data_quality_IDs_ricoveri_quarantene_fp_SDO =  OrderedDict{String, Dict{String, Any}}()
data_quality_ricoveri_quarantene_fp_SDO          =  OrderedDict{String, Dict{String, Int64}}()
for ICD_9_CM in ICD_9_CM_actual
    line_list_ricoveri_quarantene_fp_SDO, data_quality_IDs_SDO, data_quality_SDO = process_date_FP(line_lists_ricoveri_quarantene_SDO[ICD_9_CM]; MVP = MVP, is_MVP = is_MVP)
    push!(line_lists_ricoveri_quarantene_fp_SDO, ICD_9_CM => line_list_ricoveri_quarantene_fp_SDO)
    push!(data_quality_IDs_ricoveri_quarantene_fp_SDO, ICD_9_CM => data_quality_IDs_SDO)
    push!(data_quality_ricoveri_quarantene_fp_SDO, ICD_9_CM          => data_quality_SDO)
end

if save
    # Save intermediate_output end_of_clinical_progression
    ## COVID-19 data
    CSV.write(joinpath(absolute_path_to_intermediate_output, run_name, "5-end_of_clinical_progression/COVID-19/pi_30/line_list_ricoveri_quarantene_fp_pi_30.csv"), line_list_ricoveri_quarantene_fp_pi_30)
    CSV.write(joinpath(absolute_path_to_intermediate_output, run_name, "5-end_of_clinical_progression/COVID-19/pi_20/line_list_ricoveri_quarantene_fp_pi_20.csv"), line_list_ricoveri_quarantene_fp_pi_20)
    CSV.write(joinpath(absolute_path_to_intermediate_output, run_name, "5-end_of_clinical_progression/COVID-19/pi_10/line_list_ricoveri_quarantene_fp_pi_10.csv"), line_list_ricoveri_quarantene_fp_pi_10)
    ## COVID-19 data quality
    ### IDs
    for (data_quality_IDs,pi_string) in zip((data_quality_IDs_ricoveri_quarantene_fp_pi_30, data_quality_IDs_ricoveri_quarantene_fp_pi_20, data_quality_IDs_ricoveri_quarantene_fp_pi_10),("pi_30","pi_20","pi_10"))
        save_julia_variable(data_quality_IDs, joinpath(absolute_path_to_intermediate_output, run_name, "5-end_of_clinical_progression/COVID-19", pi_string, "data_quality"), "data_quality_quarantene_ricoveri_fp_$(pi_string)_IDs" )
    end
    ### Aggregated
    for (data_quality,pi_string) in zip((data_quality_ricoveri_quarantene_fp_pi_30, data_quality_ricoveri_quarantene_fp_pi_20 , data_quality_ricoveri_quarantene_fp_pi_10),("pi_30","pi_20","pi_10"))
        save_julia_variable(data_quality, joinpath(absolute_path_to_output, run_name, "5-end_of_clinical_progression/COVID-19", pi_string, "data_quality"), "data_quality_quarantene_ricoveri_fp_$(pi_string)" )
    end
    ## SDO data
    # We don't save this processing step for SDO data since this dataset would present dates that are just a made-up variables needed to have the piepline working 
    for (ICD_9_CM, line_list_ricoveri_quarantene_fp_SDO) in collect(line_lists_ricoveri_quarantene_fp_SDO)
        CSV.write(joinpath(absolute_path_to_intermediate_output, run_name, "5-end_of_clinical_progression/SDO/line_list_ricoveri_quarantene_fp_SDO_$ICD_9_CM.csv"), line_list_ricoveri_quarantene_fp_SDO)
    end
    ### IDs
    save_julia_variable(data_quality_IDs_ricoveri_quarantene_fp_SDO, joinpath(absolute_path_to_intermediate_output, run_name, "5-end_of_clinical_progression/SDO", "data_quality"), "data_quality_quarantene_ricoveri_fp_SDO_IDs" )
    ### Aggregated
    save_julia_variable(data_quality_ricoveri_quarantene_fp_SDO, joinpath(absolute_path_to_output, run_name, "5-end_of_clinical_progression/SDO", "data_quality"), "data_quality_quarantene_ricoveri_fp_SDO" )
end

##########################################
######### INIZIO SINTOMI (IS) ############
##########################################

# COVID-19 data
# include("./Code/Julia/processed_line_list.jl");
const line_list_ricoveri_quarantene_fp_is_pi_30, data_quality_IDs_quarantene_fp_is_pi_30, data_quality_quarantene_fp_is_pi_30 = process_inizi_sintomi(line_list_ricoveri_quarantene_fp_pi_30; MVP = MVP, is_MVP = is_MVP)
const line_list_ricoveri_quarantene_fp_is_pi_20, data_quality_IDs_quarantene_fp_is_pi_20, data_quality_quarantene_fp_is_pi_20 = process_inizi_sintomi(line_list_ricoveri_quarantene_fp_pi_20; MVP = MVP, is_MVP = is_MVP)
const line_list_ricoveri_quarantene_fp_is_pi_10, data_quality_IDs_quarantene_fp_is_pi_10, data_quality_quarantene_fp_is_pi_10 = process_inizi_sintomi(line_list_ricoveri_quarantene_fp_pi_10; MVP = MVP, is_MVP = is_MVP)
# SDO data
line_lists_ricoveri_quarantene_fp_is_SDO = OrderedDict{String, DataFrame}()
data_quality_IDs_ricoveri_quarantene_fp_is_SDO =  OrderedDict{String, Dict{String, Any}}()
data_quality_ricoveri_quarantene_fp_is_SDO          =  OrderedDict{String, Dict{String, Int64}}()
for ICD_9_CM in ICD_9_CM_actual
    line_list_ricoveri_quarantene_fp_is, data_quality_IDs_SDO, data_quality_SDO= process_inizi_sintomi(line_lists_ricoveri_quarantene_fp_SDO[ICD_9_CM]; MVP = MVP, is_MVP = is_MVP)
    push!(line_lists_ricoveri_quarantene_fp_is_SDO,            ICD_9_CM => line_list_ricoveri_quarantene_fp_is)
    push!(data_quality_IDs_ricoveri_quarantene_fp_is_SDO, ICD_9_CM => data_quality_IDs_SDO)
    push!(data_quality_ricoveri_quarantene_fp_is_SDO,          ICD_9_CM => data_quality_SDO)
end

if save
    # Save intermediate_output end_of_clinical_progression
    ## COVID-19 data
    CSV.write(joinpath(absolute_path_to_intermediate_output, run_name, "6-symptoms_onset/COVID-19/pi_30/line_list_ricoveri_quarantene_fp_is_pi_30.csv"), line_list_ricoveri_quarantene_fp_is_pi_30)
    CSV.write(joinpath(absolute_path_to_intermediate_output, run_name, "6-symptoms_onset/COVID-19/pi_20/line_list_ricoveri_quarantene_fp_is_pi_20.csv"), line_list_ricoveri_quarantene_fp_is_pi_20)
    CSV.write(joinpath(absolute_path_to_intermediate_output, run_name, "6-symptoms_onset/COVID-19/pi_10/line_list_ricoveri_quarantene_fp_is_pi_10.csv"), line_list_ricoveri_quarantene_fp_is_pi_10)
    ## COVID-19 data quality
    ### IDs
    for (data_quality_IDs,pi_string) in zip((data_quality_IDs_quarantene_fp_is_pi_30, data_quality_IDs_quarantene_fp_is_pi_20, data_quality_IDs_quarantene_fp_is_pi_10),("pi_30","pi_20","pi_10"))
        save_julia_variable(data_quality_IDs, joinpath(absolute_path_to_intermediate_output, run_name, "6-symptoms_onset/COVID-19", pi_string, "data_quality"), "data_quality_ricoveri_quaranetene_fp_is_$(pi_string)_IDs" )
    end
    ### Aggregated
    for (data_quality,pi_string) in zip((data_quality_quarantene_fp_is_pi_30, data_quality_quarantene_fp_is_pi_20 , data_quality_quarantene_fp_is_pi_10),("pi_30","pi_20","pi_10"))
        save_julia_variable(data_quality, joinpath(absolute_path_to_output, run_name, "6-symptoms_onset/COVID-19", pi_string, "data_quality"), "data_quality_ricoveri_quaranetene_fp_is_$pi_string" )
    end
    ## SDO data
    # We don't save this processing step for SDO data since this dataset would present dates that are just a made-up variables needed to have the piepline working 
    ## SDO data quality
    # We don't save this processing step for SDO data since this dataset would present dates that are just a made-up variables needed to have the piepline working 
end

##############################
######## LIMIT DATES #########
##############################

# COVID-19 data
const limit_date = Date("2020-12-31")
const line_list_ricoveri_quarantene_fp_is_lim_pi_30 = delete_lines_exceeding_date(line_list_ricoveri_quarantene_fp_is_pi_30,limit_date)
const line_list_ricoveri_quarantene_fp_is_lim_pi_20 = delete_lines_exceeding_date(line_list_ricoveri_quarantene_fp_is_pi_20,limit_date)
const line_list_ricoveri_quarantene_fp_is_lim_pi_10 = delete_lines_exceeding_date(line_list_ricoveri_quarantene_fp_is_pi_10,limit_date)
# SDO data
line_lists_ricoveri_quarantene_fp_is_lim_SDO = OrderedDict{String, DataFrame}()

for ICD_9_CM in ICD_9_CM_actual
    line_list_ricoveri_quarantene_fp_is_lim = delete_lines_exceeding_date(line_lists_ricoveri_quarantene_fp_is_SDO[ICD_9_CM], limit_date)
    ## Remove dates that have no meaning for the SDO datasets
    select!(line_list_ricoveri_quarantene_fp_is_lim, Not([:data_P, :data_IQP, :data_FQP, :data_IQO, :data_FQO])) #We keep :data_IS column (which is composed of only missing values) since it is later needed by the get_delays function.
    push!(line_lists_ricoveri_quarantene_fp_is_lim_SDO, ICD_9_CM => line_list_ricoveri_quarantene_fp_is_lim)
end

if save
    # Save intermediate_output processed_line_lists
    ## COVID-19 data
    CSV.write(joinpath(absolute_path_to_intermediate_output, run_name, "7-processed_line_lists/COVID-19/line_list_ricoveri_quarantene_fp_is_lim_pi_30.csv"), line_list_ricoveri_quarantene_fp_is_lim_pi_30)
    CSV.write(joinpath(absolute_path_to_intermediate_output, run_name, "7-processed_line_lists/COVID-19/line_list_ricoveri_quarantene_fp_is_lim_pi_20.csv"), line_list_ricoveri_quarantene_fp_is_lim_pi_20)
    CSV.write(joinpath(absolute_path_to_intermediate_output, run_name, "7-processed_line_lists/COVID-19/line_list_ricoveri_quarantene_fp_is_lim_pi_10.csv"), line_list_ricoveri_quarantene_fp_is_lim_pi_10)
    ## SDO data
    ## Don't save :data_ID column.
    for (ICD_9_CM, line_list_ricoveri_quarantene_fp_is_lim) in collect(line_lists_ricoveri_quarantene_fp_is_lim_SDO)
        CSV.write(joinpath(absolute_path_to_intermediate_output, run_name, "7-processed_line_lists/SDO/line_list_ricoveri_quarantene_fp_is_lim_SDO_$ICD_9_CM.csv"), select(line_list_ricoveri_quarantene_fp_is_lim,Not(:data_IS)))
    end
end

#############################
######## SEQUENCES ##########
#############################

# # Get sequences
# ## Uncersored sequences
# ### COVID-19 data
# const sequences_pi_30 = get_sequences(line_list_ricoveri_quarantene_fp_is_lim_pi_30  ; lower_date_limit = Date("2020-01-01"), upper_date_limit = Date("2020-12-31"), aggregate = false, privacy_policy = false, MVP = MVP, is_MVP = is_MVP)
# const sequences_pi_20 = get_sequences(line_list_ricoveri_quarantene_fp_is_lim_pi_20; lower_date_limit = Date("2020-01-01"), upper_date_limit = Date("2020-12-31"),   aggregate = false, privacy_policy = false, MVP = MVP, is_MVP = is_MVP)
# const sequences_pi_10 = get_sequences(line_list_ricoveri_quarantene_fp_is_lim_pi_10  ; lower_date_limit = Date("2020-01-01"), upper_date_limit = Date("2020-12-31"), aggregate = false, privacy_policy = false, MVP = MVP, is_MVP = is_MVP)
# ### SDO data
# sequences_SDO = OrderedDict{String, OrderedDict{Tuple{Vararg{String}}, OrderedDict{Int64, DataFrame}}}()
# for (i,ICD_9_CM) in enumerate(ICD_9_CM_actual)
#     println("$i  / $(length(ICD_9_CM_actual))")
#     sequences_SDO_code_specific = get_sequences(select(line_lists_ricoveri_quarantene_fp_is_lim_SDO[ICD_9_CM], Not(:data_IS)); lower_date_limit = Date("2010-01-01"), upper_date_limit = Date("2020-12-31"), aggregate = false, privacy_policy = false, MVP = MVP, is_MVP = is_MVP)
#     push!(sequences_SDO, ICD_9_CM => sequences_SDO_code_specific)
# end

# ## Censored sequences
# ### COVID-19 data

# const sequences_censored_pi_30, data_quality_sequences_censored_pi_30= get_sequences(line_list_ricoveri_quarantene_fp_is_lim_pi_30; lower_date_limit = Date("2020-01-01"), upper_date_limit = Date("2020-12-31"), aggregate = false, privacy_policy = true, MVP = MVP, is_MVP = is_MVP)
# const sequences_censored_pi_20, data_quality_sequences_censored_pi_20= get_sequences(line_list_ricoveri_quarantene_fp_is_lim_pi_20; lower_date_limit = Date("2020-01-01"), upper_date_limit = Date("2020-12-31"), aggregate = false, privacy_policy = true, MVP = MVP, is_MVP = is_MVP)
# const sequences_censored_pi_10, data_quality_sequences_censored_pi_10 = get_sequences(line_list_ricoveri_quarantene_fp_is_lim_pi_10; lower_date_limit = Date("2020-01-01"), upper_date_limit = Date("2020-12-31"), aggregate = false, privacy_policy = true, MVP = MVP, is_MVP = is_MVP)
# ### SDO data
# sequences_censored_SDO = OrderedDict{String, OrderedDict{Tuple{Vararg{String}}, OrderedDict{Int64, DataFrame}}}()
# data_quality_sequences_SDO = OrderedDict{String, Dict{String,Int64}}()
# for ICD_9_CM in ICD_9_CM_actual
#     sequences_SDO_code_specific, data_quality_sequences_SDO_code_specific  = get_sequences(select(line_lists_ricoveri_quarantene_fp_is_lim_SDO[ICD_9_CM], Not(:data_IS)); lower_date_limit = Date("2010-01-01"), upper_date_limit = Date("2020-12-31"), aggregate = false,  privacy_policy = true, MVP = MVP, is_MVP = is_MVP)
#     push!(sequences_censored_SDO, ICD_9_CM => sequences_SDO_code_specific)
#     push!(data_quality_sequences_SDO, ICD_9_CM => data_quality_sequences_SDO_code_specific)
# end
# ## COVID-19 data aggregated by sequence
# const incidences_pi_30= get_sequences(line_list_ricoveri_quarantene_fp_is_lim_pi_30; lower_date_limit = Date("2020-01-01"), upper_date_limit = Date("2020-12-31"), aggregate = true, privacy_policy = false, MVP = MVP, is_MVP = is_MVP)
# const incidences_pi_20= get_sequences(line_list_ricoveri_quarantene_fp_is_lim_pi_20; lower_date_limit = Date("2020-01-01"), upper_date_limit = Date("2020-12-31"), aggregate = true, privacy_policy = false, MVP = MVP, is_MVP = is_MVP)
# const incidences_pi_10 = get_sequences(line_list_ricoveri_quarantene_fp_is_lim_pi_10; lower_date_limit = Date("2020-01-01"), upper_date_limit = Date("2020-12-31"), aggregate = true, privacy_policy = false, MVP = MVP, is_MVP = is_MVP)

# ## COVID-19 data aggregated by sequence before applying privacy policy
# # include("./Code/Julia/sequences.jl");
# # include("sequences.jl");
# const incidences_censored_pi_30,  data_quality_incidences_pi_30 = get_sequences(line_list_ricoveri_quarantene_fp_is_lim_pi_30; lower_date_limit = Date("2020-01-01"), upper_date_limit = Date("2020-12-31"), aggregate = true, privacy_policy = true, MVP = MVP, is_MVP = is_MVP)
# const incidences_censored_pi_20, data_quality_incidences_pi_20 = get_sequences(line_list_ricoveri_quarantene_fp_is_lim_pi_20; lower_date_limit = Date("2020-01-01"), upper_date_limit = Date("2020-12-31"), aggregate = true, privacy_policy = true, MVP = MVP, is_MVP = is_MVP)
# const incidences_censored_pi_10, data_quality_incidences_pi_10 = get_sequences(line_list_ricoveri_quarantene_fp_is_lim_pi_10; lower_date_limit = Date("2020-01-01"), upper_date_limit = Date("2020-12-31"), aggregate = true, privacy_policy = true, MVP = MVP, is_MVP = is_MVP)

# ### SDO data aggregated by sequence
# incidences_aggregated_SDO =OrderedDict{String, OrderedDict{String, OrderedDict{Int64, DataFrame}}}()
# for ICD_9_CM in ICD_9_CM_actual
#     incidences_SDO_code_specific  = get_sequences(select(line_lists_ricoveri_quarantene_fp_is_lim_SDO[ICD_9_CM], Not(:data_IS)); lower_date_limit = Date("2010-01-01"), upper_date_limit = Date("2020-12-31"), aggregate = true,  privacy_policy = false, MVP = MVP, is_MVP = is_MVP)
#     push!(incidences_aggregated_SDO, ICD_9_CM => incidences_SDO_code_specific)
# end


# ### SDO data aggregated by sequence before applying privacy policy
# incidences_aggregated_censored_SDO =OrderedDict{String, OrderedDict{String, OrderedDict{Int64, DataFrame}}}()
# data_quality_incidences_SDO = OrderedDict{String, Dict{String,Int64}}()
# for ICD_9_CM in ICD_9_CM_actual
#     incidences_SDO_code_specific, data_quality_code_specific  = get_sequences(select(line_lists_ricoveri_quarantene_fp_is_lim_SDO[ICD_9_CM], Not(:data_IS)); lower_date_limit = Date("2010-01-01"), upper_date_limit = Date("2020-12-31"), aggregate = true,  privacy_policy = true, MVP = MVP, is_MVP = is_MVP)
#     push!(incidences_aggregated_censored_SDO, ICD_9_CM => incidences_SDO_code_specific)
#     push!(data_quality_incidences_SDO, ICD_9_CM => data_quality_code_specific)
# end

# if save
#     # Save sequences
#     ## COVID-19 sequences
#     save_sequences_as_csv(sequences_censored_pi_30, joinpath(absolute_path_to_output, run_name, "sequences/COVID-19/pi_30"), age_classes_representations)
#     save_sequences_as_csv(sequences_censored_pi_20, joinpath(absolute_path_to_output, run_name, "sequences/COVID-19/pi_20"), age_classes_representations)
#     save_sequences_as_csv(sequences_censored_pi_10, joinpath(absolute_path_to_output, run_name, "sequences/COVID-19/pi_10"), age_classes_representations)
#     ## COVID-19 data quality
#     for (data_quality,pi_string) in zip((data_quality_sequences_censored_pi_30, data_quality_sequences_censored_pi_20 , data_quality_sequences_censored_pi_10),("pi_30","pi_20","pi_10"))
#         save_julia_variable(data_quality, joinpath(absolute_path_to_output, run_name, "sequences/COVID-19", pi_string, "data_quality"), "data_quality_sequences_COVID_19" )
#     end
#     ## SDO sequences
#     for (ICD_9_CM, sequences_SDO_censored_code_specific) in collect(sequences_censored_SDO)
#         save_sequences_as_csv(sequences_SDO_censored_code_specific,joinpath(absolute_path_to_output, run_name, "sequences/SDO"), age_classes_representations; extra_identifier = "_"*ICD_9_CM)
#     end
#     ## SDO sequences data quality
#     save_julia_variable(data_quality_sequences_SDO, joinpath(absolute_path_to_output, run_name, "sequences/SDO", "data_quality"), "data_quality_sequences_SDO")
#     ## COVID-19 incidences
#     for (incidences_censored,pi_string) in zip((incidences_censored_pi_30, incidences_censored_pi_20, incidences_censored_pi_10),("pi_30","pi_20","pi_10" ))
#         save_incidences_as_csv(incidences_censored, joinpath(absolute_path_to_output, run_name, "incidences/COVID-19", pi_string); extra_infix = "_"*pi_string )
#     end
#     ## COVID-19 incidences data quality
#     for (data_quality,pi_string) in zip((data_quality_incidences_pi_30, data_quality_incidences_pi_20, data_quality_incidences_pi_10),("pi_30","pi_20","pi_10" ))
#         save_julia_variable(data_quality, joinpath(absolute_path_to_output, run_name, "incidences/COVID-19", pi_string,"data_quality"), "data_quality_incidences_COVID_19" )
#     end
#     ## SDO incidences
#     for (code,incidences_censored) in collect(incidences_aggregated_censored_SDO)
#         save_incidences_as_csv(incidences_censored, joinpath(absolute_path_to_output, run_name, "incidences/SDO"); extra_infix = "_"*code )
#     end
#     ## SDO incidences data quality
#     save_julia_variable(data_quality_incidences_SDO, joinpath(absolute_path_to_output, run_name, "incidences/SDO", "data_quality"), "data_quality_incidences_SDO")
# end



# Get sequences
## Uncersored sequences
### COVID-19 data
include("sequences.jl");

const sequences_pi_30 = get_sequences(line_list_ricoveri_quarantene_fp_is_lim_pi_30  ; lower_date_limit = Date("2020-01-01"), upper_date_limit = Date("2020-12-31"), MVP = MVP, is_MVP = is_MVP)
const sequences_pi_20 = get_sequences(line_list_ricoveri_quarantene_fp_is_lim_pi_20; lower_date_limit = Date("2020-01-01"), upper_date_limit = Date("2020-12-31"),  MVP = MVP, is_MVP = is_MVP)
const sequences_pi_10 = get_sequences(line_list_ricoveri_quarantene_fp_is_lim_pi_10  ; lower_date_limit = Date("2020-01-01"), upper_date_limit = Date("2020-12-31"), MVP = MVP, is_MVP = is_MVP)
### SDO data
sequences_SDO = OrderedDict{String, OrderedDict{Tuple{Vararg{String}}, OrderedDict{Int64, DataFrame}}}()
for (i,ICD_9_CM) in enumerate(ICD_9_CM_actual)
    println("$i  / $(length(ICD_9_CM_actual))")
    sequences_SDO_code_specific = get_sequences(select(line_lists_ricoveri_quarantene_fp_is_lim_SDO[ICD_9_CM], Not(:data_IS)); lower_date_limit = Date("2010-01-01"), upper_date_limit = Date("2020-12-31"), MVP = MVP, is_MVP = is_MVP)
    push!(sequences_SDO, ICD_9_CM => sequences_SDO_code_specific)
end

## Censored sequences
### COVID-19 data

const sequences_censored_pi_30, data_quality_sequences_censored_pi_30= apply_privacy_policy(sequences_pi_30)
const sequences_censored_pi_20, data_quality_sequences_censored_pi_20= apply_privacy_policy(sequences_pi_20)
const sequences_censored_pi_10, data_quality_sequences_censored_pi_10 = apply_privacy_policy(sequences_pi_10) 
### SDO data
sequences_censored_SDO = OrderedDict{String, OrderedDict{Tuple{Vararg{String}}, OrderedDict{Int64, DataFrame}}}()
data_quality_sequences_SDO = OrderedDict{String, Dict{String,Int64}}()
for (ICD_9_CM, sequences_SDO_code_specific) in collect(sequences_SDO)
    sequences_SDO_censored_code_specific, data_quality_sequences_SDO_code_specific  = apply_privacy_policy(sequences_SDO_code_specific)
    push!(sequences_censored_SDO, ICD_9_CM => sequences_SDO_censored_code_specific)
    push!(data_quality_sequences_SDO, ICD_9_CM => data_quality_sequences_SDO_code_specific)
end
## COVID-19 data aggregated by sequence
const incidences_pi_30= aggregate_sequences(sequences_pi_30,Date("2020-01-01"), Date("2020-12-31"))
const incidences_pi_20= aggregate_sequences(sequences_pi_20,Date("2020-01-01"), Date("2020-12-31"))
const incidences_pi_10 = aggregate_sequences(sequences_pi_10,Date("2020-01-01"), Date("2020-12-31"))

## COVID-19 data aggregated by sequence before applying privacy policy

# include("sequences.jl");
const incidences_censored_pi_30,  data_quality_incidences_pi_30 = apply_privacy_policy(incidences_pi_30) 
const incidences_censored_pi_20, data_quality_incidences_pi_20  = apply_privacy_policy(incidences_pi_20)
const incidences_censored_pi_10, data_quality_incidences_pi_10  = apply_privacy_policy(incidences_pi_10)

### SDO data aggregated by sequence
incidences_aggregated_SDO =OrderedDict{String, OrderedDict{String, OrderedDict{Int64, DataFrame}}}()
for (ICD_9_CM, sequences_SDO_code_specific) in collect(sequences_SDO)
    incidences_SDO_code_specific  = aggregate_sequences(sequences_SDO_code_specific, Date("2010-01-01"), Date("2020-12-31"))
    push!(incidences_aggregated_SDO, ICD_9_CM => incidences_SDO_code_specific)
end

### SDO data aggregated by sequence before applying privacy policy
incidences_aggregated_censored_SDO =OrderedDict{String, OrderedDict{String, OrderedDict{Int64, DataFrame}}}()
data_quality_incidences_SDO = OrderedDict{String, Dict{String,Int64}}()
for (ICD_9_CM, incidences_SDO_code_specific) in collect(incidences_aggregated_SDO)
    incidences_SDO_censored_code_specific, data_quality_code_specific  = apply_privacy_policy(incidences_SDO_code_specific) #get_sequences(select(line_lists_ricoveri_quarantene_fp_is_lim_SDO[ICD_9_CM], Not(:data_IS)); lower_date_limit = Date("2010-01-01"), upper_date_limit = Date("2020-12-31"), aggregate = true,  privacy_policy = true, MVP = MVP, is_MVP = is_MVP)
    push!(incidences_aggregated_censored_SDO, ICD_9_CM => incidences_SDO_censored_code_specific)
    push!(data_quality_incidences_SDO, ICD_9_CM => data_quality_code_specific)
end


if save
    # Save sequences
    ## COVID-19 sequences
    save_sequences_as_csv(sequences_censored_pi_30, joinpath(absolute_path_to_output, run_name, "sequences/COVID-19/pi_30"), age_classes_representations)
    save_sequences_as_csv(sequences_censored_pi_20, joinpath(absolute_path_to_output, run_name, "sequences/COVID-19/pi_20"), age_classes_representations)
    save_sequences_as_csv(sequences_censored_pi_10, joinpath(absolute_path_to_output, run_name, "sequences/COVID-19/pi_10"), age_classes_representations)
    ## COVID-19 data quality
    for (data_quality,pi_string) in zip((data_quality_sequences_censored_pi_30, data_quality_sequences_censored_pi_20 , data_quality_sequences_censored_pi_10),("pi_30","pi_20","pi_10"))
        save_julia_variable(data_quality, joinpath(absolute_path_to_output, run_name, "sequences/COVID-19", pi_string, "data_quality"), "data_quality_sequences_COVID_19" )
    end
    ## SDO sequences
    for (ICD_9_CM, sequences_SDO_censored_code_specific) in collect(sequences_censored_SDO)
        save_sequences_as_csv(sequences_SDO_censored_code_specific,joinpath(absolute_path_to_output, run_name, "sequences/SDO"), age_classes_representations; extra_identifier = "_"*ICD_9_CM)
    end
    ## SDO sequences data quality
    save_julia_variable(data_quality_sequences_SDO, joinpath(absolute_path_to_output, run_name, "sequences/SDO", "data_quality"), "data_quality_sequences_SDO")
    ## COVID-19 incidences
    for (incidences_censored,pi_string) in zip((incidences_censored_pi_30, incidences_censored_pi_20, incidences_censored_pi_10),("pi_30","pi_20","pi_10" ))
        save_incidences_as_csv(incidences_censored, joinpath(absolute_path_to_output, run_name, "incidences/COVID-19", pi_string); extra_infix = "_"*pi_string )
    end
    ## COVID-19 incidences data quality
    for (data_quality,pi_string) in zip((data_quality_incidences_pi_30, data_quality_incidences_pi_20, data_quality_incidences_pi_10),("pi_30","pi_20","pi_10" ))
        save_julia_variable(data_quality, joinpath(absolute_path_to_output, run_name, "incidences/COVID-19", pi_string,"data_quality"), "data_quality_incidences_COVID_19" )
    end
    ## SDO incidences
    for (code,incidences_censored) in collect(incidences_aggregated_censored_SDO)
        save_incidences_as_csv(incidences_censored, joinpath(absolute_path_to_output, run_name, "incidences/SDO"); extra_infix = "_"*code )
    end
    ## SDO incidences data quality
    save_julia_variable(data_quality_incidences_SDO, joinpath(absolute_path_to_output, run_name, "incidences/SDO", "data_quality"), "data_quality_incidences_SDO")
end



#############################
######## TIME DELAYS ########
#############################

# Get time delays distributions
# include("./Code/Julia/time_delays.jl");
const Ts = (0, 1, 7, 14, 21, 30, 60, 120, 240, 365 ) # theoretical maximum = 365
const date_start = Date("2020-01-01")
# const dt_continuous = vcat(InteractiveUtils.subtypes.((Distribution{Univariate, Continuous},))...)
# const dt_mostcommon =  (Gamma,)
## COVID-19 data
const delays_pi_30,delay_frequencies_pi_30 = get_delays(line_list_ricoveri_quarantene_fp_is_lim_pi_30; Ts = Ts, date_start = date_start, date_end = limit_date, privacy_policy = false, distributions_types = (), get_frequencies = true, MVP = MVP, is_MVP = is_MVP);
const delays_pi_20,delay_frequencies_pi_20 = get_delays(line_list_ricoveri_quarantene_fp_is_lim_pi_20; Ts = Ts, date_start = date_start, date_end = limit_date, privacy_policy = false, distributions_types = (), get_frequencies = true, MVP = MVP, is_MVP = is_MVP);
const delays_pi_10,delay_frequencies_pi_10 = get_delays(line_list_ricoveri_quarantene_fp_is_lim_pi_10; Ts = Ts, date_start = date_start, date_end = limit_date, privacy_policy = false, distributions_types = (), get_frequencies = true, MVP = MVP, is_MVP = is_MVP);
## SDO data
delays_SDO = OrderedDict{String, Dict{String, OrderedDict{Int64, OrderedDict{Int64, Dict{String, DataFrame}}}}}()
for ICD_9_CM in ICD_9_CM_actual
    delays_SDO_code_specific = get_delays(line_lists_ricoveri_quarantene_fp_is_lim_SDO[ICD_9_CM]; Ts = Ts,  date_start = Date("2010-01-01"), date_end = limit_date, privacy_policy = false, distributions_types = (), get_frequencies = true, MVP = MVP, is_MVP = is_MVP)
    push!(delays_SDO, ICD_9_CM => delays_SDO_code_specific[2])
end


# Since we are only interested in frequencies, we don't need to get the censored version of the empirical distributions 
# const delays_censored_pi_30 = get_delays(line_list_ricoveri_quarantene_fp_is_lim_pi_30; max_T = max_T, privacy_policy = true, distributions_types = (), get_frequencies = false, MVP = MVP, is_MVP = is_MVP)
# const delays_censored_pi_20 = get_delays(line_list_ricoveri_quarantene_fp_is_lim_pi_20; max_T = max_T, privacy_policy = true, distributions_types = (), get_frequencies = false, MVP = MVP, is_MVP = is_MVP)
# const delays_censored_pi_10 = get_delays(line_list_ricoveri_quarantene_fp_is_lim_pi_10; max_T = max_T, privacy_policy = true, distributions_types = (), get_frequencies = false, MVP = MVP, is_MVP = is_MVP)

# Save time delays distributions
## COVID-19 data
### Absolute
# save_delays_as_csv(delays_censored_pi_30, joinpath(absolute_path_to_output, run_name, "time_delays/empirical_absolute_distributions/pi_30"))
# save_delays_as_csv(delays_censored_pi_20, joinpath(absolute_path_to_output, run_name, "time_delays/empirical_absolute_distributions/pi_20"))
# save_delays_as_csv(delays_censored_pi_10, joinpath(absolute_path_to_output, run_name, "time_delays/empirical_absolute_distributions/pi_10"))
### Frequencies
save_delays_as_csv(delay_frequencies_pi_30, joinpath(absolute_path_to_output, run_name, "time_delays/empirical_frequencies_distributions/COVID-19/pi_30"))
save_delays_as_csv(delay_frequencies_pi_20, joinpath(absolute_path_to_output, run_name, "time_delays/empirical_frequencies_distributions/COVID-19/pi_20"))
save_delays_as_csv(delay_frequencies_pi_10, joinpath(absolute_path_to_output, run_name, "time_delays/empirical_frequencies_distributions/COVID-19/pi_10"))
### Estimated distributions
# julia_variable(estimated_delay_distributions_pi_30, joinpath(absolute_path_to_output, run_name, "time_delays/estimated_distributions/pi_30", "estimated_delay_distributions_pi_30"))
# julia_variable(estimated_delay_distributions_pi_20, joinpath(absolute_path_to_output, run_name, "time_delays/estimated_distributions/pi_20", "estimated_delay_distributions_pi_20"))
# julia_variable(estimated_delay_distributions_pi_10, joinpath(absolute_path_to_output, run_name, "time_delays/estimated_distributions/pi_10", "estimated_delay_distributions_pi_10"))
## SDO data
for (ICD_9_CM, delays_SDO_code_specific) in collect(delays_SDO)
    save_delays_as_csv(delays_SDO_code_specific,joinpath(absolute_path_to_output, run_name, "time_delays/empirical_frequencies_distributions/SDO"); extra_identifier = "_"*ICD_9_CM)
end

#############################
##### DATA VISUALIZATION ####
#############################
include("plotting.jl")

# Plot raw and processed line-list data
const n_lines = 30
const scatter_size = (1000,900)
const hlines_size = (2200,2000)
## Get rich portion of the synthetic dataset
const rich_raw_line_list_pi_30= raw_line_list_pi_30[.!is_MVP.(raw_line_list_pi_30.data_IS) .& .!is_MVP.(raw_line_list_pi_30.date_IQ) .& .!is_MVP.(raw_line_list_pi_30.date_FQ) .& .!is_MVP.(raw_line_list_pi_30.ricoveri) .& (.!is_MVP.(raw_line_list_pi_30.data_G) .| .!is_MVP.(raw_line_list_pi_30.data_D)  ) ,  :]

const rich_raw_line_list_pi_30_plots =  plot_multiple_samples_raw_line_list(rich_raw_line_list_pi_30, n_lines, "Raw COVID-19 individual-level surveillance data in Piedmont (PI = 30)", :scatter) 



const rich_raw_line_list_pi_20= raw_line_list_pi_20[.!is_MVP.(raw_line_list_pi_20.data_IS) .& .!is_MVP.(raw_line_list_pi_20.date_IQ) .& .!is_MVP.(raw_line_list_pi_20.date_FQ) .& .!is_MVP.(raw_line_list_pi_20.ricoveri) .& (.!is_MVP.(raw_line_list_pi_20.data_G) .| .!is_MVP.(raw_line_list_pi_20.data_D)  ) ,  :]

const rich_raw_line_list_pi_20_plots =  plot_multiple_samples_raw_line_list(rich_raw_line_list_pi_20, n_lines, "Raw COVID-19 individual-level surveillance data in Piedmont (PI = 20)", :scatter) 



const rich_raw_line_list_pi_10= raw_line_list_pi_10[.!is_MVP.(raw_line_list_pi_10.data_IS) .& .!is_MVP.(raw_line_list_pi_10.date_IQ) .& .!is_MVP.(raw_line_list_pi_10.date_FQ) .& .!is_MVP.(raw_line_list_pi_10.ricoveri) .& (.!is_MVP.(raw_line_list_pi_10.data_G) .| .!is_MVP.(raw_line_list_pi_10.data_D)  ) ,  :]

const rich_raw_line_list_pi_10_plots =  plot_multiple_samples_raw_line_list(rich_raw_line_list_pi_10, n_lines, "Raw COVID-19 individual-level surveillance data in Piedmont (PI = 10)", :scatter) 


for (i, plt) in enumerate(rich_raw_line_list_pi_30_plots)
    savefig(plt, joinpath(absolute_path_to_output_plots, run_name, "1-raw_line_list/COVID-19/raw_line_list_pi_30_plot_$(i).png"))
end

for (i, plt) in enumerate(rich_raw_line_list_pi_20_plots)
    savefig(plt, joinpath(absolute_path_to_output_plots, run_name, "1-raw_line_list/COVID-19/raw_line_list_pi_20_plot_$(i).png"))
end

for (i, plt) in enumerate(rich_raw_line_list_pi_10_plots)
    savefig(plt, joinpath(absolute_path_to_output_plots, run_name, "1-raw_line_list/COVID-19/raw_line_list_pi_10_plot_$(i).png"))
end


## Plot processed line-list data
const date_IQP = line_list_ricoveri_quarantene_fp_is_pi_30.data_IQP
const date_FQP = line_list_ricoveri_quarantene_fp_is_pi_30.data_FQP
const rich_processed_line_list_pi_30= line_list_ricoveri_quarantene_fp_is_pi_30[.!is_MVP.(line_list_ricoveri_quarantene_fp_is_pi_30.data_IS) .& .!is_MVP.(line_list_ricoveri_quarantene_fp_is_pi_30.data_IQP) .& .!is_MVP.(line_list_ricoveri_quarantene_fp_is_pi_30.data_AO) .& .!is_MVP.(line_list_ricoveri_quarantene_fp_is_pi_30.data_AI) .& (.!is_MVP.(line_list_ricoveri_quarantene_fp_is_pi_30.data_G) .| .!is_MVP.(line_list_ricoveri_quarantene_fp_is_pi_30.data_D)  )  .& (Dates.value.([ismissing(diff) ? Day(50) : diff for diff in date_FQP .- date_IQP]) .< 30 ) ,  :]

include("plotting.jl")
const rich_processed_line_list_pi_30_hlines_plots =  plot_multiple_samples_processed_line_list(rich_processed_line_list_pi_30, n_lines, "Processed COVID-19 individual-level surveillance data in Piedmont (PI = 30)", :hlines_annotations, hlines_size)

const rich_processed_line_list_pi_30_scatter_plots =  plot_multiple_samples_processed_line_list(rich_processed_line_list_pi_30, n_lines, "Processed COVID-19 individual-level surveillance data in Piedmont (PI = 30)", :scatter, scatter_size )

#= rich_processed_line_list_pi_30 = rich_processed_line_list_pi_30[1:(size(rich_processed_line_list_pi_30,1) ÷ n_lines):size(rich_processed_line_list_pi_30,1),:]
rich_processed_line_list_pi_30.ID = collect(1:size(rich_processed_line_list_pi_30,1))
const processed_line_list_pi_30_plot = plot_line_list_processed(rich_processed_line_list_pi_30, MVP, is_MVP,
                                                                mode = :hlines_annotations,
                                                                title = "Processed COVID-19 individual-level surveillance data in Piedmont (PI = 30)",
                                                                size = (2200,2000),
                                                                lw = 15
                                                               ) =#

const rich_processed_line_list_pi_20= line_list_ricoveri_quarantene_fp_is_pi_20[.!is_MVP.(line_list_ricoveri_quarantene_fp_is_pi_20.data_IS) .& .!is_MVP.(line_list_ricoveri_quarantene_fp_is_pi_20.data_IQP) .& .!is_MVP.(line_list_ricoveri_quarantene_fp_is_pi_20.data_AO) .& .!is_MVP.(line_list_ricoveri_quarantene_fp_is_pi_20.data_AI) .& (.!is_MVP.(line_list_ricoveri_quarantene_fp_is_pi_20.data_G) .| .!is_MVP.(line_list_ricoveri_quarantene_fp_is_pi_20.data_D)  )  .& (Dates.value.([ismissing(diff) ? Day(50) : diff for diff in date_FQP .- date_IQP]) .< 30 ) ,  :]

const rich_processed_line_list_pi_20_hlines_plots =  plot_multiple_samples_processed_line_list(rich_processed_line_list_pi_20, n_lines, "Processed COVID-19 individual-level surveillance data in Piedmont (PI = 20)", :hlines_annotations, hlines_size)

const rich_processed_line_list_pi_20_scatter_plots =  plot_multiple_samples_processed_line_list(rich_processed_line_list_pi_20, n_lines, "Processed COVID-19 individual-level surveillance data in Piedmont (PI = 20)", :scatter, scatter_size )


#= rich_processed_line_list_pi_20 = rich_processed_line_list_pi_20[1:(size(rich_processed_line_list_pi_20,1) ÷ n_lines):size(rich_processed_line_list_pi_20,1),:]
rich_processed_line_list_pi_20.ID = collect(1:size(rich_processed_line_list_pi_20,1))
const processed_line_list_pi_20_plot = plot_line_list_processed(rich_processed_line_list_pi_20, MVP, is_MVP,
                                                                mode = :hlines_annotations,
                                                                title = "Processed COVID-19 individual-level surveillance data in Piedmont (PI = 20)",
                                                                size = (2200,2000),
                                                                lw = 15
                       
                                                                ) =#

const rich_processed_line_list_pi_10= line_list_ricoveri_quarantene_fp_is_pi_10[.!is_MVP.(line_list_ricoveri_quarantene_fp_is_pi_10.data_IS) .& .!is_MVP.(line_list_ricoveri_quarantene_fp_is_pi_10.data_IQP) .& .!is_MVP.(line_list_ricoveri_quarantene_fp_is_pi_10.data_AO) .& .!is_MVP.(line_list_ricoveri_quarantene_fp_is_pi_10.data_AI) .& (.!is_MVP.(line_list_ricoveri_quarantene_fp_is_pi_10.data_G) .| .!is_MVP.(line_list_ricoveri_quarantene_fp_is_pi_10.data_D)  ) .& (Dates.value.([ismissing(diff) ? Day(50) : diff for diff in date_FQP .- date_IQP]) .< 30 ) ,  :]

const rich_processed_line_list_pi_10_hlines_plots =  plot_multiple_samples_processed_line_list(rich_processed_line_list_pi_10, n_lines, "Processed COVID-19 individual-level surveillance data in Piedmont (PI = 10)", :hlines_annotations, hlines_size)

const rich_processed_line_list_pi_10_scatter_plots =  plot_multiple_samples_processed_line_list(rich_processed_line_list_pi_10, n_lines, "Processed COVID-19 individual-level surveillance data in Piedmont (PI = 10)", :scatter, scatter_size )

#= rich_processed_line_list_pi_10 = rich_processed_line_list_pi_10[1:(size(rich_processed_line_list_pi_10,1) ÷ n_lines):size(rich_processed_line_list_pi_10,1),:]
rich_processed_line_list_pi_10.ID = collect(1:size(rich_processed_line_list_pi_10,1))     
const processed_line_list_pi_10_plot = plot_line_list_processed(rich_processed_line_list_pi_10, MVP, is_MVP,
                                                                mode = :hlines_annotations,
                                                                title = "Processed COVID-19 individual-level surveillance data in Piedmont (PI = 10)",
                                                                size = (2200,2000),
                                                                lw = 15
                                                               ) =#

#= savefig(processed_line_list_pi_30_plot, joinpath(absolute_path_to_output_plots,  run_name, "2-processed_line_list/COVID-19/processed_line_list_pi_30_plot.png"))
savefig(processed_line_list_pi_20_plot, joinpath(absolute_path_to_output_plots,  run_name, "2-processed_line_list/COVID-19/processed_line_list_pi_20_plot.png"))
savefig(processed_line_list_pi_10_plot, joinpath(absolute_path_to_output_plots,  run_name, "2-processed_line_list/COVID-19/processed_line_list_pi_10_plot.png")) =#

for (i, plt) in enumerate(rich_processed_line_list_pi_30_hlines_plots)
    savefig(plt, joinpath(absolute_path_to_output_plots, run_name, "2-processed_line_list/COVID-19/processed_line_list_pi_30_hlines_plot_$(i).png"))
end

for (i, plt) in enumerate(rich_processed_line_list_pi_20_hlines_plots)
    savefig(plt, joinpath(absolute_path_to_output_plots, run_name, "2-processed_line_list/COVID-19/processed_line_list_pi_20_hlines_plot_$(i).png"))
end

for (i, plt) in enumerate(rich_processed_line_list_pi_10_hlines_plots)
    savefig(plt, joinpath(absolute_path_to_output_plots, run_name, "2-processed_line_list/COVID-19/processed_line_list_pi_10_hlines_plot_$(i).png"))
end



for (i, plt) in enumerate(rich_processed_line_list_pi_30_scatter_plots)
    savefig(plt, joinpath(absolute_path_to_output_plots, run_name, "2-processed_line_list/COVID-19/processed_line_list_pi_30_scatter_plot_$(i).png"))
end

for (i, plt) in enumerate(rich_processed_line_list_pi_20_scatter_plots)
    savefig(plt, joinpath(absolute_path_to_output_plots, run_name, "2-processed_line_list/COVID-19/processed_line_list_pi_20_scatter_plot_$(i).png"))
end

for (i, plt) in enumerate(rich_processed_line_list_pi_10_scatter_plots)
    savefig(plt, joinpath(absolute_path_to_output_plots, run_name, "2-processed_line_list/COVID-19/processed_line_list_pi_10_scatter_plot_$(i).png"))
end



# Plot sequences
## COVID-19
include("plotting.jl")
const sequences_plots_pi_30 = plot_sequences(sequences_pi_30, age_classes_representations; paltt = cgrad(:Paired_9 , categorical = true));
const sequences_plots_pi_20 = plot_sequences(sequences_pi_20, age_classes_representations; paltt = cgrad(:Paired_9 , categorical = true));
const sequences_plots_pi_10 = plot_sequences(sequences_pi_10, age_classes_representations; paltt = cgrad(:Paired_9 , categorical = true));

for (sequence, plt) in collect(sequences_plots_pi_30)
    savefig(plt, joinpath(absolute_path_to_output_plots, run_name, "sequences/COVID-19/pi_30",sequence))
end

for (sequence, plt) in collect(sequences_plots_pi_20)
    savefig(plt, joinpath(absolute_path_to_output_plots, run_name, "sequences/COVID-19/pi_20",sequence))
end

for (sequence, plt) in collect(sequences_plots_pi_10)
    savefig(plt, joinpath(absolute_path_to_output_plots, run_name, "sequences/COVID-19/pi_10",sequence))
end

## SDO
SDO_sequences_plots = OrderedDict{String, Dict{String, Plots.Plot}}()
for (ICD9_code, sequence_SDO) in collect(sequences_SDO)
    push!(SDO_sequences_plots, ICD9_code => plot_sequences(sequence_SDO, age_classes_representations;  paltt = cgrad(:Paired_9 , categorical = true)))
end

for (ICD9_code, SDO_sequence_plots) in collect(SDO_sequences_plots)
    for (sequence,SDO_sequence_plot) in collect(SDO_sequence_plots)
        savefig(SDO_sequence_plot, joinpath(absolute_path_to_output_plots, run_name, "sequences/SDO",ICD9_code*"_"*sequence))
    end
end

# Plot incidences
# include("plotting.jl")
## COVID-19
const incidences_plots_pi_30 = plot_incidences(incidences_pi_30, age_classes_representations)
const incidences_plots_pi_20 = plot_incidences(incidences_pi_20, age_classes_representations)
const incidences_plots_pi_10 = plot_incidences(incidences_pi_10, age_classes_representations)

for (event,incidence_plot) in collect(incidences_plots_pi_30)
    savefig(incidence_plot, joinpath(absolute_path_to_output_plots, run_name, "incidences/COVID-19/pi_30",event))
end

for (event,incidence_plot) in collect(incidences_plots_pi_20)
    savefig(incidence_plot, joinpath(absolute_path_to_output_plots, run_name, "incidences/COVID-19/pi_20",event))
end

for (event,incidence_plot) in collect(incidences_plots_pi_10)
    savefig(incidence_plot, joinpath(absolute_path_to_output_plots, run_name, "incidences/COVID-19/pi_10",event))
end

SDO_incidences_plots = OrderedDict{String, Dict{String, Plots.Plot}}()
for (ICD9_code, code_specific_incidences) in collect(incidences_aggregated_SDO)
    push!(SDO_incidences_plots, ICD9_code => plot_incidences(code_specific_incidences, age_classes_representations))
end

## SDO
for (ICD9_code, code_specific_incidences_plots) in collect(SDO_incidences_plots)
    for (event,code_event_specific_incidences_plot) in collect(code_specific_incidences_plots)
        savefig(code_event_specific_incidences_plot, joinpath(absolute_path_to_output_plots, run_name, "incidences/SDO",ICD9_code*"_"*event))
    end
end


## Plot time delays
#include("./Code/Julia/plotting.jl");
# const delays_plots_pi_30 = plot_delays(delay_frequencies_pi_30, 1, age_classes_representations);
# const delays_plots_pi_20 = plot_delays(delay_frequencies_pi_20, 1, age_classes_representations);
# const delays_plots_pi_10 = plot_delays(delay_frequencies_pi_10, 1, age_classes_representations);

# for (delay, plt) in collect(delays_plots_pi_30)
#     savefig(plt, joinpath(joinpath(absolute_path_to_intermediate_output, run_name, "4-time_delays/fake_input/pi_30",delay)))
# end

# for (delay, plt) in collect(delays_plots_pi_20)
#     savefig(plt, joinpath(joinpath(absolute_path_to_intermediate_output, run_name, "4-time_delays/fake_input/pi_20",delay)))
# end

# for (delay, plt) in collect(delays_plots_pi_10)
#     savefig(plt, joinpath(joinpath(absolute_path_to_intermediate_output, run_name, "4-time_delays/fake_input/pi_10",delay)))
# end
