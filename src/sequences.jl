########################
####### SEQUENCES ######
########################

######## PRIVACY #######

"""
    apply_privacy_threashold_rule!(column::Vector{Int64})

Modify `column` in-place so that every value between 0 (excluded) and 3 (included) is set to -1 in order to comply with the privacy rules.
"""
function apply_privacy_threashold_rule!(column::Vector{Int64})
    sum_of_obscured_intensities   = 0
    sum_of_nonzero_intensities = 0
    number_of_intensities_obscured = 0
    number_of_nonzero_intensities = 0
    @inbounds for i in eachindex(column)
        if 0<column[i]<=3
            sum_of_nonzero_intensities += column[i]
            number_of_nonzero_intensities += 1
            number_of_intensities_obscured += 1
            sum_of_obscured_intensities += column[i]
            column[i] = -1
        elseif column[i]>3
            number_of_nonzero_intensities += 1
            sum_of_nonzero_intensities += column[i]
        end
    end
    return number_of_intensities_obscured, sum_of_obscured_intensities, number_of_nonzero_intensities, sum_of_nonzero_intensities
end

function apply_privacy_policy(incidences::OrderedDict{String, OrderedDict{Int64, DataFrame}})
    incidences_dc = deepcopy(incidences)
    number_of_intensities_obscured = 0
    sum_of_obscured_intensities = 0
    number_of_nonzero_intensities = 0
    sum_of_nonzero_intensities = 0
    println("Implementing privacy policy...")
    @showprogress 1 for ageClass_dataframe_dct in values(incidences_dc)
        for dataframe in values(ageClass_dataframe_dct)
            new_number_of_intensities_obscured, new_sum_of_obscured_intensities, new_number_of_nonzero_intensities, new_sum_of_nonzero_intensities = apply_privacy_threashold_rule!(dataframe[!,"cases"])
            number_of_intensities_obscured += new_number_of_intensities_obscured
            sum_of_obscured_intensities += new_sum_of_obscured_intensities
            number_of_nonzero_intensities += new_number_of_nonzero_intensities
            sum_of_nonzero_intensities += new_sum_of_nonzero_intensities
        end
    end
    return  incidences_dc, Dict{String,Int64}("number_of_intensities_obscured" => number_of_intensities_obscured, "sum_of_obscured_intensities" => sum_of_obscured_intensities, "number_of_nonzero_intensities" => number_of_nonzero_intensities, "sum_of_nonzero_intensities" => sum_of_nonzero_intensities)
end



function apply_privacy_policy(sequence_ageclass_dataframe_dct::OrderedDict{Tuple{Vararg{String}}, OrderedDict{Int64,DataFrame}})

    sequence_ageclass_dataframe_dct_dc = deepcopy(sequence_ageclass_dataframe_dct)
    number_of_intensities_obscured = 0
    sum_of_obscured_intensities = 0
    number_of_nonzero_intensities = 0
    sum_of_nonzero_intensities = 0
    println("Implementing privacy policy... (2/2)")
    @showprogress 1 for (sequence,age_class_dct) in collect(sequence_ageclass_dataframe_dct_dc)
        for dataframe in values(age_class_dct)
            event_sequences = get_events_from_sequence(sequence)
            for event_sequence in event_sequences
                new_number_of_intensities_obscured, new_sum_of_obscured_intensities, new_number_of_nonzero_intensities, new_sum_of_nonzero_intensities = apply_privacy_threashold_rule!(dataframe[!,event_sequence])
                number_of_intensities_obscured += new_number_of_intensities_obscured
                sum_of_obscured_intensities += new_sum_of_obscured_intensities
                number_of_nonzero_intensities += new_number_of_nonzero_intensities
                sum_of_nonzero_intensities += new_sum_of_nonzero_intensities
            end
        end
    end
    return sequence_ageclass_dataframe_dct_dc, Dict{String,Int64}("number_of_intensities_obscured" => number_of_intensities_obscured, "sum_of_obscured_intensities" => sum_of_obscured_intensities, "number_of_nonzero_intensities" => number_of_nonzero_intensities, "sum_of_nonzero_intensities" => sum_of_nonzero_intensities)
end

#### LINE-SPECIFIC SEQUENCES ###

"""
    get_sequences(line::DataFrameRow{DataFrame, DataFrames.Index}; MVP, is_MVP::F) where  {F <: Function}

Get all sequences from a `line` of the processed integrated individual-level surveillance dataset. Usually it only returns one sequence unless there is a detached quarantena precauzionale, in which case two sequences will be returned: the loop sequence and the remainder sequence.
"""
function get_sequences(line::DataFrameRow{DataFrame, DataFrames.Index}; MVP, is_MVP::F) where  {F <: Function}
    # Pre-allocate intermediate result
    events_dates_dct = OrderedDict{String, Date}()

    # Pre-allocate output
    sequences = Vector{String}[]

    # Loop over the columns of the line
    for col in names(line)
        # If the columns is not "classe_eta" and is not missing...
        if col ∉ ["ID", "classe_eta"] && !is_MVP(line[col])
            # ...add its name to the output, after deleting the "data_" part
            push!(events_dates_dct, replace(col, "data_" => "") =>line[col])
        end
    end

    # Sort by date
    sort!(events_dates_dct, byvalue = true)

    whole_sequence = collect(keys(events_dates_dct))
    whole_dates = collect(values(events_dates_dct))

    # Swap FQP and P when they coincide
    if "FQP" in whole_sequence && "P" in whole_sequence && events_dates_dct["FQP"] == events_dates_dct["P"]
        FQP_index = findfirst(x -> cmp(x,"FQP") == 0, collect(keys(events_dates_dct)))
        P_index   = findfirst(x -> cmp(x,"P") == 0, collect(keys(events_dates_dct)))
        if FQP_index == P_index + 1
            # Swap
            whole_sequence[FQP_index-1] = "FQP"
            whole_sequence[FQP_index] = "P"
        elseif FQP_index > P_index + 1
            error("get_sequences. FQP_index = $FQP_index and P_index = $P_index")
        end
    end

    # If there is a detached quarantena precauzionale output a loop sequence to and from quarantena precauzionale, and a sequence with the remainder of the initial sequence
    if length(whole_sequence) >= 2 &&  cmp("FQP", whole_sequence[2]) == 0
        date_FQP = whole_dates[2]
        date_after_FQP = whole_dates[3]
        if  date_FQP < date_after_FQP 
            loop_sequence = whole_sequence[1:2]
            sequences = [loop_sequence, whole_sequence[3:end]]
        elseif date_FQP == date_after_FQP
            sequences = [whole_sequence]
        end
    else
        sequences = [whole_sequence]
    end

    # Return sequence as an (immutable) tuple
    return Tuple(Tuple.(sequences))
end

#### SEQUENCE-SPECIFIC EVENTS ###

"""
    get_events_from_sequence(sequence::Tuple{Vararg{String}})

Get all events (e.g. p_ao_DO_g) from sequence (e.g. ("P", "AO","DO","G").
"""
function get_events_from_sequence(sequence::Tuple{Vararg{String}})
    # Pre-allocate output
    events = String[]

    # Loop over events dates
    for i in 1:length(sequence)
        push!(events, join(vcat(lowercase.(sequence[1:(i-1)])..., sequence[i], lowercase.(sequence[(i+1):end])...), "_"))
    end

    return Tuple(events)
end

is_uppercase(x::String) = x == uppercase(x) 


function aggregate_sequences(sequence_ageclass_dataframe_dct::OrderedDict{Tuple{Vararg{String}}, OrderedDict{Int64, DataFrame}}, lower_date_limit::Date, upper_date_limit::Date)
    events = ("IQP", "FQP", "P", "IS", "IQO", "FQO", "AO", "DO", "AI", "DI", "AR", "DR", "G", "D")
    age_classes = [0,40,60,70,80]

    incidences = OrderedDict{String, OrderedDict{Int64, DataFrame}}(event => OrderedDict{Int64, DataFrame}(age_class => DataFrame(:date => lower_date_limit:Day(1):upper_date_limit, :cases => zeros(Int64, Dates.value(upper_date_limit-lower_date_limit)+1 )) for age_class in age_classes ) for event in events)

    for ageClass_dataframe_dct in values(sequence_ageclass_dataframe_dct)
        for (age_class,dataframe) in collect(ageClass_dataframe_dct)
             for event_sequence in names(dataframe)[2:end]

                event = filter(x-> is_uppercase(string(x)), split(event_sequence, "_"))
                @assert length(event) == 1
                incidences[event[1]][age_class][!,"cases"] .+= dataframe[!,event_sequence]
             end
        end
    end

    return incidences
end

#### SEQUENCE-BASED DATA MODEL ###

"""
    get_sequences(line_list_ricoveri_quarantene_fp_is_lim::DataFrame; MVP, is_MVP::F) where {F <: Function}

Get sequences-based data model from processed line-list `line_list_ricoveri_quarantene_fp_is_lim`, applying the description manual.
"""
function get_sequences(line_list_ricoveri_quarantene_fp_is_lim::DataFrame; lower_date_limit::Date, upper_date_limit::Date, MVP, is_MVP::F) where {F <: Function} # aggregate::Bool, privacy_policy::Bool
    # Get the array of unique age classes
    # classi_eta = sort(unique(line_list_ricoveri_quarantene_fp_is_lim.classe_eta))

    # Data Model (a dictionary age_class => Dict(sequence => DataFrame)) where `sequence` is a tuple of Strings like ("P", "AO","DO","G") and DataFrame has dates as rows and events as columns (e.g. p_ao_DO_g)
    sequences_dct = OrderedDict{Int64,OrderedDict{Tuple{Vararg{String}},DataFrame}}() 

    # Loop over each line
    println("Processing sequences... (1/2)")
    @showprogress 1 for line in eachrow(line_list_ricoveri_quarantene_fp_is_lim)
        # println("ID = ", line.ID)
        # Get the age class
        classe_eta = line.classe_eta

        # Get the sequence (Tuple of Strings) it belongs to
        sequences = get_sequences(line; MVP = MVP, is_MVP = is_MVP)
        
        # Get all events (e.g. p_ao_DO_g) from sequence (e.g. ("P", "AO","DO","G"))
        # println("process_sequences; sequences = $sequences")
        events_sequences = get_events_from_sequence.(sequences)

        # Loop over sequences and events_sequences, creating (if it doesn't yet exist) and filling the sequence-based data model
        for (sequence, events_sequence) in zip(sequences, events_sequences)
            #println(sequence, events_sequence)
            # If the sequence has not been discovered before (for this age class)...
            if !(classe_eta in keys(sequences_dct)) || !(sequence in keys(sequences_dct[classe_eta]))# size(sequences_dct[classe_eta][sequence]) == (0,0)
                #println("just found")
                # Create DataFrame tailored to discovered sequence
                dates = collect(lower_date_limit:Day(1):upper_date_limit)
                sequence_df = DataFrame( :data => dates , [Symbol(event) => zeros(Int64,length(dates)) for event in events_sequence]...)

                # Loop over events and event_sequences, incrementing the dataset corresponding to the sequence fixed by the above loop
                for (event,event_sequence) in zip("data_".* sequence, events_sequence)
                    # If the date correpsonding to `event` in `line` is not missing and it is within the predetermined limits, increment the corresponding counter in the sequence-based dataset
                    if !is_MVP(line[event]) && (line[event] in sequence_df.data)
                        date_index = findfirst(x-> x == line[event], sequence_df.data)
                        @eval $sequence_df.$event_sequence[$date_index]  += 1
                    # Else if a date does not fit into the dataset, error (it should not happen beacause of `delete_lines_exceeding_date`)
                    elseif !is_MVP(line[event]) && !(line[event] in sequence_df.data)
                        error("missing date ", line[event])
                    end
                end

                # sequences_dct[classe_eta][sequence] = sequence_df
                if !(classe_eta in keys(sequences_dct))
                    push!(sequences_dct, classe_eta => Dict(sequence => sequence_df))
                elseif (classe_eta in keys(sequences_dct)) && !(sequence in keys(sequences_dct[classe_eta]))
                    push!(sequences_dct[classe_eta], sequence => sequence_df)
                else
                    error("contradiction")
                end

            # Else if it has been discovered, just increment the corresponding counter in the sequence-based dataset
            else
                #println("already found")
                sequence_df = sequences_dct[classe_eta][sequence]

                # Loop over events and event_sequences, incrementing the dataset corresponding to the sequence fixed by the above loop
                for (event,event_sequence) in zip("data_".* sequence, events_sequence)
                    # If the date correpsonding to `event` in `line` is not missing and it is within the predetermined limits, increment the corresponding counter in the sequence-based dataset
                    if !is_MVP(line[event]) && (line[event] in sequence_df.data)
                        date_index = findfirst(x-> x == line[event], sequence_df.data)
                        @eval $sequence_df.$event_sequence[$date_index]  += 1
                    # Else if a date does not fit into the dataset, error (it should not happenbeacause of `delete_lines_exceeding_date`)
                    elseif !is_MVP(line[event]) && !(line[event] in sequence_df.data)
                        error("missing date ", line[event])
                    end
                end
            end
        end
    end
    # for 
    # @assert
    # Reshape output dictionary so that it is like Dict(sequence => Dict(age_class => DataFrame))
    sequence_ageclass_dataframe_dct = OrderedDict{Tuple{Vararg{String}}, OrderedDict{Int64,DataFrame}}()
    for (age_class, sequence_dataframe_dct) in collect(sequences_dct)
        for (sequence,dataframe) in collect(sequence_dataframe_dct)
            if sequence in keys(sequence_ageclass_dataframe_dct)
                push!(sequence_ageclass_dataframe_dct[sequence], age_class => sequence_dataframe_dct[sequence])
            else
                sequence_ageclass_dataframe_dct[sequence] = Dict(age_class => sequence_dataframe_dct[sequence])
            end
        end
    end

    # Sort sequences by their length
    sequence_ageclass_dataframe_dct = OrderedDict(sort(collect(sequence_ageclass_dataframe_dct), by=x -> length(x[1]))...)

    # Sort age classes by their value
    for sequence in keys(sequence_ageclass_dataframe_dct)
        sequence_ageclass_dataframe_dct[sequence] = sort(sequence_ageclass_dataframe_dct[sequence], byvalue = false)
    end

    # # Aggregate sequences to incidences, if required
    # incidences =  OrderedDict{String, OrderedDict{Int64, DataFrame}}()
    # if aggregate
    #     incidences = aggregate_sequences(sequence_ageclass_dataframe_dct, lower_date_limit, upper_date_limit)
    # end

    # # Implement privacy policy and record the amount of intensities obscured
    # number_of_intensities_obscured = 0
    # sum_of_obscured_intensities = 0
    # number_of_nonzero_intensities = 0
    # sum_of_nonzero_intensities = 0
    # if privacy_policy && !aggregate
    #     println("Implementing privacy policy... (2/2)")
    #     @showprogress 1 for (sequence,age_class_dct) in collect(sequence_ageclass_dataframe_dct)
    #         for dataframe in values(age_class_dct)
    #             event_sequences = get_events_from_sequence(sequence)
    #             for event_sequence in event_sequences
    #                 new_number_of_intensities_obscured, new_sum_of_obscured_intensities, new_number_of_nonzero_intensities, new_sum_of_nonzero_intensities = apply_privacy_threashold_rule!(dataframe[!,event_sequence])
    #                 number_of_intensities_obscured += new_number_of_intensities_obscured
    #                 sum_of_obscured_intensities += new_sum_of_obscured_intensities
    #                 number_of_nonzero_intensities += new_number_of_nonzero_intensities
    #                 sum_of_nonzero_intensities += new_sum_of_nonzero_intensities
    #             end
    #         end
    #     end
    # elseif privacy_policy && aggregate
    #     println("Implementing privacy policy...")
    #     @showprogress 1 for ageClass_dataframe_dct in values(incidences)
    #         for dataframe in values(ageClass_dataframe_dct)
    #             new_number_of_intensities_obscured, new_sum_of_obscured_intensities, new_number_of_nonzero_intensities, new_sum_of_nonzero_intensities = apply_privacy_threashold_rule!(dataframe[!,"cases"])
    #             number_of_intensities_obscured += new_number_of_intensities_obscured
    #             sum_of_obscured_intensities += new_sum_of_obscured_intensities
    #             number_of_nonzero_intensities += new_number_of_nonzero_intensities
    #             sum_of_nonzero_intensities += new_sum_of_nonzero_intensities
    #         end
    #     end
    # end

    # Return sequences-based data model
    # if privacy_policy && !aggregate
    #     return sequence_ageclass_dataframe_dct, Dict{String,Int64}("number_of_intensities_obscured" => number_of_intensities_obscured, "sum_of_obscured_intensities" => sum_of_obscured_intensities, "number_of_nonzero_intensities" => number_of_nonzero_intensities, "sum_of_nonzero_intensities" => sum_of_nonzero_intensities)
    # elseif privacy_policy && aggregate
    #     return incidences,                      Dict{String,Int64}("number_of_intensities_obscured" => number_of_intensities_obscured, "sum_of_obscured_intensities" => sum_of_obscured_intensities, "number_of_nonzero_intensities" => number_of_nonzero_intensities, "sum_of_nonzero_intensities" => sum_of_nonzero_intensities)
    # elseif !privacy_policy && aggregate
    #     return incidences
    # else
    #     return sequence_ageclass_dataframe_dct
    # end
    return sequence_ageclass_dataframe_dct
end

### SEQUENCE DATA SAVING ###

"""
    save_sequences_as_csv(sequence_ageclass_dataframe_dct::OrderedDict{Tuple{Vararg{String}}, OrderedDict{Int64,DataFrame}}, folder::String, age_classes_representations::Dict{Int64,String})

Dave all sequences DataFrames contained in `sequence_ageclass_dataframe_dct` (as outputted by `get_sequences`) in `folder`. Use `age_classes_representations` to convert age classes Int64 representations to String representations.
"""
function save_sequences_as_csv(sequence_ageclass_dataframe_dct::OrderedDict{Tuple{Vararg{String}}, OrderedDict{Int64,DataFrame}}, folder::String, age_classes_representations::Dict{Int64,String}; extra_identifier = "")
    for (sequence,age_class_dct) in collect(sequence_ageclass_dataframe_dct)
        for (age_class, dataframe) in collect(age_class_dct)
            sequence_name = join(sequence,"_")
            CSV.write(joinpath(folder, sequence_name*"_"*age_classes_representations[age_class]*extra_identifier*".csv"),dataframe)
        end
    end
end


### INCIDENCE DATA SAVING ###

function save_incidences_as_csv(event_ageClass_dataframe_dct::OrderedDict{String, OrderedDict{Int64, DataFrame}}, folder::String; extra_infix::String = "" )
    for (event,ageClass_dataframe_dct) in collect(event_ageClass_dataframe_dct)
        for (ageClass,dataframe) in collect(ageClass_dataframe_dct)
            CSV.write(joinpath(folder, "$(event)_$(string(ageClass))_incidences$extra_infix.csv"), dataframe )
        end
    end
end