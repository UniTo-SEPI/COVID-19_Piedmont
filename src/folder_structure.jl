########################
### FOLDER STRUCTURE ###
########################

"""
    make_intermediate_output_folder_structure(absolute_path_to_intermediate_output::String)

Create folder structure inside `absolute_path_to_intermediate_output` analogous to the one found in `Fake_intermediate_output`.
"""
function make_intermediate_output_folder_structure(absolute_path_to_intermediate_output::String,  run_name::String)
    # Create folder structure inside `absolute_path_to_intermediate_output`
    intermediate_output_folders = ("1-pre_processing", "2-raw_line_list", "3-hospitalization_period", "4-quarantine_isolation", "5-end_of_clinical_progression", "6-symptoms_onset", "7-processed_line_lists", "plots_variables")

    # for path, in joinpath.(Ref(absolute_path_to_intermediate_output), intermediate_output_folders)
    for intermediate_output_folder in intermediate_output_folders
        #if !isdir(path)

        #mkdir(path)

        if any(occursin.(("3-hospitalization_period", "5-end_of_clinical_progression", "7-processed_line_lists"),Ref(intermediate_output_folder))) #"1-pre_processing", 
            mkpath(joinpath(absolute_path_to_intermediate_output, run_name, intermediate_output_folder,  "COVID-19"))
            mkpath(joinpath(absolute_path_to_intermediate_output, run_name, intermediate_output_folder, "SDO", "data_quality"))
        end

        if occursin("1-pre_processing",intermediate_output_folder)
            mkpath(joinpath(absolute_path_to_intermediate_output, run_name, intermediate_output_folder, "COVID-19"))
            # mkpath(joinpath(absolute_path_to_intermediate_output, run_name, intermediate_output_folder, "SDO", "data_quality"))
            mkpath(joinpath(absolute_path_to_intermediate_output, run_name, intermediate_output_folder, "SDO", "mort_SDO_OneRicoveroPerPatient_groupedby_ICD_9_CM"))
            mkpath(joinpath(absolute_path_to_intermediate_output, run_name, intermediate_output_folder, "SDO", "trasf_trasposti_SDO_OneRicoveroPerPatient_groupedby_ICD_9_CM"))
            mkpath(joinpath(absolute_path_to_intermediate_output, run_name, intermediate_output_folder, "SDO", "positivi_quarantena_SDO_groupedby_ICD_9_CM"))

            mkpath(joinpath(absolute_path_to_intermediate_output,run_name, intermediate_output_folder, "SDO", "skip_sdo_pre_processing", "trasf_trasposti_15_19_mul_ric_pat_proc"))
            mkpath(joinpath(absolute_path_to_intermediate_output,run_name, intermediate_output_folder, "SDO", "skip_sdo_pre_processing", "ICD9CM_processedTrasfTraspostiOne_dct"))
            mkpath(joinpath(absolute_path_to_intermediate_output,run_name, intermediate_output_folder, "SDO", "skip_sdo_pre_processing", "ICD9CM_processed_joinAll_dct"))
            mkpath(joinpath(absolute_path_to_intermediate_output,run_name, intermediate_output_folder, "SDO", "skip_sdo_pre_processing", "ICD9CM_processedPositiviQuarantena_dct"))
        end

        if occursin("2-raw_line_list",intermediate_output_folder)
            mkpath(joinpath(absolute_path_to_intermediate_output, run_name,  intermediate_output_folder,"COVID-19","pi_30"))
            mkpath(joinpath(absolute_path_to_intermediate_output, run_name,  intermediate_output_folder,"COVID-19","pi_20"))
            mkpath(joinpath(absolute_path_to_intermediate_output, run_name,  intermediate_output_folder,"COVID-19","pi_10"))
        end


        if any(occursin.(("3-hospitalization_period", "4-quarantine_isolation", "5-end_of_clinical_progression", "6-symptoms_onset"),Ref(intermediate_output_folder)))
            mkpath(joinpath(absolute_path_to_intermediate_output, run_name, intermediate_output_folder, "COVID-19","pi_30", "data_quality"))
            mkpath(joinpath(absolute_path_to_intermediate_output, run_name, intermediate_output_folder, "COVID-19","pi_20", "data_quality"))
            mkpath(joinpath(absolute_path_to_intermediate_output, run_name, intermediate_output_folder, "COVID-19","pi_10", "data_quality"))
        end
        

        if any(occursin.(("plots_variables"),Ref(intermediate_output_folder)))
            mkpath(joinpath(absolute_path_to_intermediate_output, run_name, intermediate_output_folder, "raw_line_list", "pi_30"))
            mkpath(joinpath(absolute_path_to_intermediate_output, run_name, intermediate_output_folder, "raw_line_list", "pi_20"))
            mkpath(joinpath(absolute_path_to_intermediate_output, run_name, intermediate_output_folder, "raw_line_list", "pi_10"))

            mkpath(joinpath(absolute_path_to_intermediate_output, run_name, intermediate_output_folder, "processed_line_list", "pi_30"))
            mkpath(joinpath(absolute_path_to_intermediate_output, run_name, intermediate_output_folder, "processed_line_list", "pi_20"))
            mkpath(joinpath(absolute_path_to_intermediate_output, run_name, intermediate_output_folder, "processed_line_list", "pi_10"))

            mkpath(joinpath(absolute_path_to_intermediate_output, run_name, intermediate_output_folder, "sequences", "pi_30"))
            mkpath(joinpath(absolute_path_to_intermediate_output, run_name, intermediate_output_folder, "sequences", "pi_20"))
            mkpath(joinpath(absolute_path_to_intermediate_output, run_name, intermediate_output_folder, "sequences", "pi_10"))
            mkpath(joinpath(absolute_path_to_intermediate_output, run_name, intermediate_output_folder, "sequences", "SDO"))

            mkpath(joinpath(absolute_path_to_intermediate_output, run_name, intermediate_output_folder, "incidences", "pi_30"))
            mkpath(joinpath(absolute_path_to_intermediate_output, run_name, intermediate_output_folder, "incidences", "pi_20"))
            mkpath(joinpath(absolute_path_to_intermediate_output, run_name, intermediate_output_folder, "incidences", "pi_10"))
            mkpath(joinpath(absolute_path_to_intermediate_output, run_name, intermediate_output_folder, "incidences", "SDO"))


        end
    end
end

"""
    make_output_folder_structure(absolute_path_to_output::String)

Create folder structure inside `absolute_path_to_output` analogous to the one found in `Fake_output`.
"""
function make_output_folder_structure(absolute_path_to_output::String, run_name::String)

    # Create folder structure inside `absolute_path_to_output`
    output_folders = ("ICD9_codes","upper_whiskers", "3-hospitalization_period", "4-quarantine_isolation", "5-end_of_clinical_progression", "6-symptoms_onset", "sequences", "incidences", "time_delays")

    # for path in joinpath.(Ref(absolute_path_to_output), output_folders)
    for output_folder in output_folders
        #if !isdir(path)

        #mkdir(path)

        if cmp(output_folder, "ICD9_codes") == 0
            mkpath(joinpath(absolute_path_to_output, output_folder) )
        end

        if occursin("upper_whiskers",output_folder)
            mkpath(joinpath(absolute_path_to_output, run_name, output_folder,"COVID-19"))
        end

        if any(occursin.(("3-hospitalization_period", "4-quarantine_isolation", "5-end_of_clinical_progression", "6-symptoms_onset"),Ref(output_folder)))
            mkpath(joinpath(absolute_path_to_output, run_name, output_folder, "COVID-19", "pi_30", "data_quality"))
            mkpath(joinpath(absolute_path_to_output, run_name,output_folder,"COVID-19", "pi_20", "data_quality"))
            mkpath(joinpath(absolute_path_to_output, run_name,output_folder,"COVID-19", "pi_10", "data_quality"))
            
        end

        if any(occursin.(("3-hospitalization_period", "5-end_of_clinical_progression"),Ref(output_folder)))
            mkpath(joinpath(absolute_path_to_output, run_name, output_folder, "SDO", "data_quality"))
        end

        if occursin("sequences",output_folder)
            mkpath(joinpath(absolute_path_to_output, run_name,output_folder, "COVID-19", "pi_30", "data_quality"))
            mkpath(joinpath(absolute_path_to_output, run_name,output_folder, "COVID-19", "pi_20", "data_quality"))
            mkpath(joinpath(absolute_path_to_output, run_name,output_folder, "COVID-19", "pi_10", "data_quality"))
            mkpath(joinpath(absolute_path_to_output, run_name,output_folder, "SDO", "data_quality"))
        end

        if occursin("incidences",output_folder)
            mkpath(joinpath(absolute_path_to_output, run_name,output_folder, "COVID-19", "pi_30", "data_quality"))
            mkpath(joinpath(absolute_path_to_output, run_name,output_folder, "COVID-19", "pi_20", "data_quality"))
            mkpath(joinpath(absolute_path_to_output, run_name,output_folder, "COVID-19", "pi_10", "data_quality"))
            mkpath(joinpath(absolute_path_to_output, run_name,output_folder, "SDO", "data_quality"))
        end

        if occursin("time_delays",output_folder)
            mkpath(joinpath(absolute_path_to_output, run_name,output_folder, "empirical_frequencies_distributions", "COVID-19", "pi_10"))
            mkpath(joinpath(absolute_path_to_output, run_name,output_folder, "empirical_frequencies_distributions", "COVID-19", "pi_20"))
            mkpath(joinpath(absolute_path_to_output, run_name,output_folder, "empirical_frequencies_distributions", "COVID-19", "pi_30"))
            mkpath(joinpath(absolute_path_to_output, run_name,output_folder, "empirical_frequencies_distributions", "SDO"))
        end 
        #end
    end
end

"""
    make_intermediate_output_folder_structure(absolute_path_to_intermediate_output::String)

Create folder structure inside `absolute_path_to_intermediate_output` analogous to the one found in `Fake_intermediate_output`.
"""
function make_intermediate_plots_folder_structure(absolute_path_to_intermediate_plots::String)
    # Create folder structure inside `absolute_path_to_intermediate_output`
    intermediate_plots_folders = ("1-raw_line_list", "2-processed_line_list") #("1-raw_line_list", "2-processed_line_lists", "3-sequences", "4-delays")

    for path in joinpath.(Ref(absolute_path_to_intermediate_plots), intermediate_plots_folders)
        if !isdir(path)
            mkdir(path)

            # if occursin("1-raw_line_list",path) || occursin("2-processed_line_lists",path)
            mkpath(joinpath(path, "COVID-19"))
            # end

            # if occursin("1-raw_line_list",path) || occursin("2-processed_line_lists",path)
            #     mkpath(joinpath(path, "COVID-19"))
            # end

            # if occursin("3-sequences",path)
            #     mkpath(joinpath(path, "COVID-19", "pi_10"))
            #     mkpath(joinpath(path, "COVID-19", "pi_20"))
            #     mkpath(joinpath(path, "COVID-19", "pi_30"))
            # end

            # if occursin("4-delays",path)
            #     mkpath(joinpath(path, "COVID-19", "pi_10"))
            #     mkpath(joinpath(path, "COVID-19", "pi_20"))
            #     mkpath(joinpath(path, "COVID-19", "pi_30"))
            # end
        end
    end
end


"""
make_output_plots_folder_structure(absolute_path_to_intermediate_output::String, run_name::String)

Create folder structure inside `absolute_path_to_intermediate_output` analogous to the one found in `Fake_intermediate_output`.
"""
function make_output_plots_folder_structure(absolute_path_to_output_plots::String, run_name::String)
    # Create folder structure inside `absolute_path_to_intermediate_output`
    output_plots_folders = ("1-raw_line_list", "2-processed_line_list", "sequences", "time_delays", "incidences") #("1-raw_line_list", "2-processed_line_lists", "3-sequences", "4-delays")

    # for path in joinpath.(Ref(absolute_path_to_intermediate_plots), intermediate_plots_folders)
    for output_folder in output_plots_folders
        #if !isdir(path)

        if cmp(output_folder, "1-raw_line_list") == 0 || cmp(output_folder, "2-processed_line_list") == 0
            mkpath(joinpath(absolute_path_to_output_plots, run_name, output_folder, "COVID-19"))
        end

        # if occursin("1-raw_line_list",path) || occursin("2-processed_line_lists",path)
        #@ mkpath(joinpath(path, "COVID-19"))
        # end

        # if occursin("1-raw_line_list",path) || occursin("2-processed_line_lists",path)
        #     mkpath(joinpath(path, "COVID-19"))
        # end

        if occursin("sequences",output_folder)
            mkpath(joinpath(absolute_path_to_output_plots, run_name, output_folder, "COVID-19", "pi_10"))
            mkpath(joinpath(absolute_path_to_output_plots, run_name, output_folder,"COVID-19", "pi_20" ))
            mkpath(joinpath(absolute_path_to_output_plots, run_name, output_folder,"COVID-19", "pi_30" ))

            mkpath(joinpath(absolute_path_to_output_plots, run_name, output_folder, "SDO","variables"))
        end

        if cmp(output_folder, "incidences") == 0
            mkpath(joinpath(absolute_path_to_output_plots, run_name, output_folder, "COVID-19", "pi_10"))
            mkpath(joinpath(absolute_path_to_output_plots, run_name, output_folder,"COVID-19", "pi_20" ))
            mkpath(joinpath(absolute_path_to_output_plots, run_name, output_folder,"COVID-19", "pi_30" ))

            mkpath(joinpath(absolute_path_to_output_plots, run_name, output_folder, "SDO"))
        end

        # if occursin("4-delays",path)
        #     mkpath(joinpath(path, "COVID-19", "pi_10"))
        #     mkpath(joinpath(path, "COVID-19", "pi_20"))
        #     mkpath(joinpath(path, "COVID-19", "pi_30"))
        # end
        #end
    end
end

