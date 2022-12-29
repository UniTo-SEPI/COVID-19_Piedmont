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
using CSV                               # Data loading and saving
using Dates                             # Data types
using DataStructures, DataFrames        # Data wrangling
using Plots,Plots.PlotMeasures          # Data visualization
using ProgressMeter                     # Progress bar
using Random                            # Randomizing 

#############################
##### CUSTOM FUNCTIONS ######
#############################

include("utilities.jl")
include("folder_structure.jl");
include("plotting.jl")

#############################
####### INSTRUCTIONS ########
#############################

# It must be absolute since these data cannot be part of the repository
#const absolute_path_to_input_data = "./Fake_input" #raw"C:\Progetti\True_input" # "/Users/pietro/GitHub/SEPI/Fake_input" 

# Path to folder that will contain intermediate outputs
# It must be absolute since these data cannot be part of the repository
const absolute_path_to_intermediate_output = "C:\\fisici\\tenere\\Intermediate_Output" #raw".\\Fake_intermediate_output" #raw"C:\Progetti\Intermediate_Output" 

# Absolute path to output folder
# const absolute_path_to_output = ".\\Fake_output" #".\\Output" #".\\Fake_output"

# Absolute path to folder where to store output
const absolute_path_to_output_plots = "C:\\fisici\\work2022_19_05\\Output_plots_covid19"#".\\Fake_output_plots" #".\\Fake_output_plots" #".\\Output_Plots" 

# Define missing values representations and check function
const MVP = missing
const is_MVP = ismissing

#############################
###### DATA LOADING #########
#############################


const processed_line_list_pi_30 = read_csv_execute_columns(joinpath(absolute_path_to_intermediate_output, "riabilitativo_is_qp",raw"7-processed_line_lists\COVID-19\line_list_ricoveri_quarantene_fp_is_lim_pi_30.csv")) 
const nrow_pi_30 = size(processed_line_list_pi_30,1)
const processed_line_list_pi_20 = read_csv_execute_columns(joinpath(absolute_path_to_intermediate_output, "riabilitativo_is_qp",raw"7-processed_line_lists\COVID-19\line_list_ricoveri_quarantene_fp_is_lim_pi_20.csv")) 
const nrow_pi_20 = size(processed_line_list_pi_20,1)
const processed_line_list_pi_10 = read_csv_execute_columns(joinpath(absolute_path_to_intermediate_output, "riabilitativo_is_qp",raw"7-processed_line_lists\COVID-19\line_list_ricoveri_quarantene_fp_is_lim_pi_10.csv")) 
const nrow_pi_10 = size(processed_line_list_pi_10,1)

# Load processed line lists from .csv files. This requires evaluating the columns.
# run_name = "riabilitativo_is_no_qp"
for (run_name,columns_to_be_missing) in (["riabilitativo_is_no_qp", [:data_IQP, :data_FQP ] ], ["riabilitativo_no_is_no_qp", [:data_IS, :data_IQP, :data_FQP ] ], ["without_riabilitativo_is_no_qp", [:data_IQP, :data_FQP, :data_AR, :data_DR ] ],["without_riabilitativo_no_is_no_qp", [:data_IS, :data_IQP, :data_FQP, :data_AR, :data_DR ] ])
#=      line_list_ricoveri_quarantene_fp_is_lim_pi_10 = read_csv_execute_columns(joinpath(absolute_path_to_intermediate_output, run_name,raw"7-processed_line_lists\COVID-19\line_list_ricoveri_quarantene_fp_is_lim_pi_10.csv")) 
     line_list_ricoveri_quarantene_fp_is_lim_pi_20 = read_csv_execute_columns(joinpath(absolute_path_to_intermediate_output, run_name,raw"7-processed_line_lists\COVID-19\line_list_ricoveri_quarantene_fp_is_lim_pi_20.csv")) 
     line_list_ricoveri_quarantene_fp_is_lim_pi_30 = read_csv_execute_columns(joinpath(absolute_path_to_intermediate_output, run_name,raw"7-processed_line_lists\COVID-19\line_list_ricoveri_quarantene_fp_is_lim_pi_30.csv"))  =#

     make_output_plots_folder_structure(absolute_path_to_output_plots, run_name)


     processed_line_list_pi_30_dc = deepcopy(processed_line_list_pi_30)
     processed_line_list_pi_20_dc = deepcopy(processed_line_list_pi_20)
     processed_line_list_pi_10_dc = deepcopy(processed_line_list_pi_10)
     for column_to_be_missing in columns_to_be_missing
        for (processed_line_list_dc, nrow_pi) in ((processed_line_list_pi_30_dc, nrow_pi_30)  , (processed_line_list_pi_20_dc, nrow_pi_20), (processed_line_list_pi_10_dc, nrow_pi_10))
            processed_line_list_dc[!, column_to_be_missing] .= repeat([missing], nrow_pi)
        end
     end
#=      display(println(run_name))
     display(first(processed_line_list_pi_30_dc))
     display(first(processed_line_list_pi_20_dc))
     display(first(processed_line_list_pi_10_dc)) =#


    # Get rich datasets
     rich_processed_line_list_pi_10 = get_rich_processed_line_list(processed_line_list_pi_10_dc, run_name)
     rich_processed_line_list_pi_20 = get_rich_processed_line_list(processed_line_list_pi_20_dc, run_name)
     rich_processed_line_list_pi_30 = get_rich_processed_line_list(processed_line_list_pi_30_dc, run_name)

    # Plots parameters
     n_lines = 30
     scatter_size = (1000, 900)
     hlines_size = (2200, 2000)

    #############################
    ##### DATA VISUALIZATION ####
    #############################

    # Create and save the plots
    ## pi_30
     rich_processed_line_list_pi_30_hlines_plots = plot_multiple_samples_processed_line_list(rich_processed_line_list_pi_30, n_lines, "Processed COVID-19 individual-level surveillance data in Piedmont (PI = 30)", :hlines_annotations, hlines_size)
     rich_processed_line_list_pi_30_scatter_plots = plot_multiple_samples_processed_line_list(rich_processed_line_list_pi_30, n_lines, "Processed COVID-19 individual-level surveillance data in Piedmont (PI = 30)", :scatter, scatter_size)
    for (i, plt) in enumerate(rich_processed_line_list_pi_30_hlines_plots)
        savefig(plt, joinpath(absolute_path_to_output_plots, run_name, "2-processed_line_list/COVID-19/processed_line_list_pi_30_hlines_plot_$(i).png"))
    end
    for (i, plt) in enumerate(rich_processed_line_list_pi_30_scatter_plots)
        savefig(plt, joinpath(absolute_path_to_output_plots, run_name, "2-processed_line_list/COVID-19/processed_line_list_pi_30_scatter_plot_$(i).png"))
    end

    ## pi_20
    rich_processed_line_list_pi_20_hlines_plots = plot_multiple_samples_processed_line_list(rich_processed_line_list_pi_20, n_lines, "Processed COVID-19 individual-level surveillance data in Piedmont (PI = 20)", :hlines_annotations, hlines_size)
    rich_processed_line_list_pi_20_scatter_plots = plot_multiple_samples_processed_line_list(rich_processed_line_list_pi_20, n_lines, "Processed COVID-19 individual-level surveillance data in Piedmont (PI = 20)", :scatter, scatter_size)
    for (i, plt) in enumerate(rich_processed_line_list_pi_20_hlines_plots)
        savefig(plt, joinpath(absolute_path_to_output_plots, run_name, "2-processed_line_list/COVID-19/processed_line_list_pi_20_hlines_plot_$(i).png"))
    end
    for (i, plt) in enumerate(rich_processed_line_list_pi_20_scatter_plots)
        savefig(plt, joinpath(absolute_path_to_output_plots, run_name, "2-processed_line_list/COVID-19/processed_line_list_pi_20_scatter_plot_$(i).png"))
    end

    ## pi_10
    rich_processed_line_list_pi_10_hlines_plots = plot_multiple_samples_processed_line_list(rich_processed_line_list_pi_10, n_lines, "Processed COVID-19 individual-level surveillance data in Piedmont (PI = 10)", :hlines_annotations, hlines_size)
    rich_processed_line_list_pi_10_scatter_plots = plot_multiple_samples_processed_line_list(rich_processed_line_list_pi_10, n_lines, "Processed COVID-19 individual-level surveillance data in Piedmont (PI = 10)", :scatter, scatter_size)
    for (i, plt) in enumerate(rich_processed_line_list_pi_10_hlines_plots)
        savefig(plt, joinpath(absolute_path_to_output_plots, run_name, "2-processed_line_list/COVID-19/processed_line_list_pi_10_hlines_plot_$(i).png"))
    end
    for (i, plt) in enumerate(rich_processed_line_list_pi_10_scatter_plots)
        savefig(plt, joinpath(absolute_path_to_output_plots, run_name, "2-processed_line_list/COVID-19/processed_line_list_pi_10_scatter_plot_$(i).png"))
    end
end