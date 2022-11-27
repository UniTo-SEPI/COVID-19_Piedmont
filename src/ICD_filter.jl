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
using JLD2, Serialization               # Julia data structures saving
using ProgressMeter                     # Progress bar
using ICD_GEMs                          # ICD-10 <-> ICD-9 conversion via GEMs
using Base.Threads                      # Multithreading

#############################
##### CUSTOM FUNCTIONS ######
#############################

# Include Julia files containing all the necessary functions
include("utilities.jl");
include("sdo_sm.jl");

#############################
########### PATHS ###########
#############################
# Absolute path to output folder
absolute_path_to_output = "./tmp/Output" 

#############################
########## MAIN #############
#############################

# Load GEMs
I10_I9_GEMs_dict = get_GEM_dict_from_cdc_gem_txt("./Code/Julia/ICD_GEMs.jl/raw_gems/2018_I10gem.txt", "I10_I9")

# ICD-10 -> ICD-9 translations 
ICD_9_CM_translations_to_exclude = Dict(
                                        # Irrelevant codes to exclude 
                                        "Diseases of the skin and subcutaneous tissue" => execute_applied_mapping(I10_I9_GEMs_dict, ["L00-L99"], "all"),
                                        "Pregnancy, childbirth and the puerperium" => execute_applied_mapping(I10_I9_GEMs_dict, ["O00-O99"], "all"),
                                        "Certain conditions originating in the perinatal period" => execute_applied_mapping(I10_I9_GEMs_dict, ["P00-P96"], "all"),
                                        "Congenital malformations, deformations and chromosomal abnormalities" => execute_applied_mapping(I10_I9_GEMs_dict, ["Q00-Q99"], "all"),
                                        "Injury, poisoning and certain other consequences of external causes" => execute_applied_mapping(I10_I9_GEMs_dict, ["S00-T98"], "all"),
                                        "External causes of morbidity and mortality" => execute_applied_mapping(I10_I9_GEMs_dict, ["V01-Y98"], "all"),
                                        "Codes for special purposes" => execute_applied_mapping(I10_I9_GEMs_dict, ["U00-U99"], "all")
                                     )

# Convert codes to string (padding with zeros so that there are always three digits before the ".", and remove the dot)
all_codes = [string(code) for code in unique(vcat(collect(values(ICD_9_CM_translations_excluded))...))]
# All codes converted to strings ad truncated at the third digit
all_codes_converted_to_strings_censored = convert_ICD9_codes_to_strings(all_codes, 3)

## Save the string codes as an array (by writing it as a string to file  returning every 20 codes to improve readability)
string_variable = nothing
open(joinpath(absolute_path_to_output, "ICD9_codes/ICD9_codes_to_exclude.txt"), "w") do file
    string_variable = string(all_codes_converted_to_strings_censored)
    string_variable_splitted = split(string_variable, ",")
    for (i, code) in enumerate(string_variable_splitted)
        if i % 20 == 0
            insert!(string_variable_splitted, i, "\n")
        end
    end
    string_variable = join(string_variable_splitted, ",")
    string_variable = replace(string_variable, ",\n," => ",\n")
    println(string_variable)
    write(file, string_variable)
end