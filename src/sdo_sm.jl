
# """
#     truncate_code(code::String, n_digits::Union{Int64,Nothing}) 

# Tuncate code after n digits, and treat digits beyond the third as decimals. Convert to Float64 before returning.
# """
# function truncate_code(code::String, n_digits::Union{Int64,Nothing})
#     if !occursin("V",code)
#         truncated_code = !isnothing(n_digits) ? code[1:n_digits] : code
#         return parse(Float64,truncated_code[1:3]*"."*truncated_code[4:end])
#     else
#         return Inf
#     end
# end


"""
    process_trasf_trasposti_15_19_and_mort_2015_2018(trasf_trasposti_15_19::DataFrame, mort_2015_2018::DataFrame; ICD_9_CM_aggregations::Union{Nothing,Dict{String, Vector{String}}} = nothing, ICD_10_aggregations::Union{Nothing,Dict{String, Vector{String}}} = nothing,  MVP, is_MVP::F) where {F <: Function}

Processes `trasf_trasposti_15_19`, `mort_2015_2018`-type like files from `Fake_input` to output a tuple (`trasf_trasposti_multiple_ricoveros_per_patient_processed`, `ICD9CM_processedTrasfTraspostiOne_dct`, `ICD9CM_processed_joinAll_dct`, `ICD9CM_processedPositiviQuarantena_dct`, `mort_2015_2018_processed`) where:

- `trasf_trasposti_multiple_ricoveros_per_patient_processed` is a `trasf_trasposti_processed`-like DataFrame from `mail.jl` that results from the direct processing of `trasp_trasposti_15_19` through `process_trasf_traposti` from `raw_line_list.jl`;
- `ICD9CM_processedTrasfTraspostiOne_dct` is a Dict(ICD_9_CM => dataframe) where dataframe is a `trasf_trasposti_processed`-like DataFrame from `mail.jl` made of line sasosciated to th `ICD_9_CM` code;
- `ICD9CM_processed_joinAll_dct` is a Dict(ICD_9_CM => dataframe) where dataframe is a `processed_join_all`-like DataFrame from `main.jl` containing all hospitalized patients with ICD_9_CM code equal to `ICD_9_CM`;
- `ICD9CM_processedPositiviQuarantena_dct` is a mock `processed_positivi_quarantena" from `main.jl` DataFrame whose columns `date_IQ` and `date_FQ` are all MVPs (this dataset is needed to let functions below in the pipeline work);
- `mort_2015_2018_processed` is a `join_all_processed`-like DataFrame from `main.jl` with two extra columns: `ICD_10` (which is valued iff the patient has died and has n `ICD_10` code) and `ICD_9_CM`  (which is valued iff the patient has been hospitalized and has an `ICD_10` code). Date of death is taken from `mort_2015_2018`, so it may be not compatible with the last discharge date from `trasf_trasposti_15_19`;
"""
function process_trasf_trasposti_15_19_and_mort_2015_2018(trasf_trasposti_15_19::DataFrame; ICD_9_CM_aggregations::Union{Nothing, Dict{String, <:Any } } = nothing, MVP, is_MVP::F) where {F <: Function} # ICD_10_aggregations::Union{Nothing, Dict{String, <:Any } } = nothing , mort_2015_2018::DataFrame

    # Deepcopy input datasets
    trasf_trasposti_15_19_dc =  deepcopy(trasf_trasposti_15_19)
    trasf_trasposti_15_19_dc.ALL_DIA_PRIN .= [String[] for i in size(trasf_trasposti_15_19_dc,1)]
    # mort_2015_2018_dc        = deepcopy(mort_2015_2018)

    # Delete trailing lines with NaN ID in mort_2015_2018_dc
    # mort_2015_2018_dc = mort_2015_2018_dc[.!isnan.(mort_2015_2018_dc.ID_ANONIMO_RIC),:]
    trasf_trasposti_15_19_dc = trasf_trasposti_15_19_dc[.!isnan.(trasf_trasposti_15_19_dc.ID_ANONIMO_RIC),:]

    # Substitute various missing values placeholdrs with `missing`
    trasf_trasposti_15_19_dc = ifelse.(is_MVP.(trasf_trasposti_15_19_dc), "", trasf_trasposti_15_19_dc)
    trasf_trasposti_15_19_dc = ifelse.(trasf_trasposti_15_19_dc .== "", MVP, trasf_trasposti_15_19_dc)
    trasf_trasposti_15_19_dc = ifelse.(isnan.(trasf_trasposti_15_19_dc), MVP, trasf_trasposti_15_19_dc)

    # mort_2015_2018_dc = ifelse.(is_MVP.(mort_2015_2018_dc), "", mort_2015_2018_dc)
    # mort_2015_2018_dc = ifelse.(mort_2015_2018_dc .== "", MVP, mort_2015_2018_dc)
    # mort_2015_2018_dc = ifelse.(isnan.(mort_2015_2018_dc), MVP, mort_2015_2018_dc)

    # Convert types to be able to add MVP values later,  add data_G column and add ICD_9_CM column
    # mort_2015_2018_dc.dt_mort = Vector{Union{typeof(MVP),Date}}(mort_2015_2018_dc.dt_mort)
    # mort_2015_2018_dc.data_G = repeat(Union{typeof(MVP),Date}[MVP], size(mort_2015_2018_dc,1))
    # mort_2015_2018_dc.causa_m = Vector{Union{typeof(MVP),String}}(mort_2015_2018_dc.causa_m)
    # mort_2015_2018_dc.ICD_9_CM = repeat(Union{typeof(MVP),String}[MVP], size(mort_2015_2018_dc,1))

    # Get maximum ID found in `trasf_trasposti_15_19_dc`
    max_ID = maximum(trasf_trasposti_15_19_dc.ID_ANONIMO_RIC)

    
    # Aggregate codes
    ## ICD_9_CM
    println("Loop 1/4")
    collected_aggregations = collect(ICD_9_CM_aggregations["aggregations"])
    if !isnothing(ICD_9_CM_aggregations)
        @showprogress 1 for line in eachrow(trasf_trasposti_15_19_dc)
            found_aggregation = false
            all_matching_aggregations_idxs = Int64[]
            if !is_MVP(line.DIA_PRIN)
                all_matching_aggregations_idxs = findall(x -> truncate_code(line.DIA_PRIN, ICD_9_CM_aggregations["n_digits"]) in x[2], collected_aggregations)
            end
            # for (aggregation_name, aggregated_codes) in collect(ICD_9_CM_aggregations["aggregations"])
            #     if ismissing(line.DIA_PRIN)
            #         line.DIA_PRIN = "excluded"
            #         found_aggregation = true
            #         break
            #     elseif length(aggregated_codes) == 2
            #         if aggregated_codes[1] <= truncate_code(line.DIA_PRIN, ICD_9_CM_aggregations["n_digits"]) <= aggregated_codes[2] 
            #             line.DIA_PRIN = aggregation_name
            #             found_aggregation = true
            #             break
            #         end
            #     elseif length(aggregated_codes) > 2
            #         if  truncate_code(line.DIA_PRIN, ICD_9_CM_aggregations["n_digits"]) in aggregated_codes
            #             line.DIA_PRIN = aggregation_name
            #             found_aggregation = true
            #             break
            #         end
            #     end
            # end
            # if !found_aggregation
            #     line.DIA_PRIN = "excluded"
            # end
            if length(all_matching_aggregations_idxs) > 0
                line.ALL_DIA_PRIN = [aggregation[1] for aggregation in collected_aggregations[all_matching_aggregations_idxs]]
            else 
                line.ALL_DIA_PRIN = ["excluded"]
            end
        end
    end

    trasf_trasposti_15_19_dc = rename(select(trasf_trasposti_15_19_dc, Not(:DIA_PRIN)), :ALL_DIA_PRIN => :DIA_PRIN)

    # println(trasf_trasposti_15_19_dc.DIA_PRIN)


    ## ICD_10: keep in mind that later groupbys are taken w.r.t ICD_9_CM code since
    # if !isnothing(ICD_10_aggregations)
    #     @showprogress 1 for line in eachrow(mort_2015_2018_dc)
    #         for (aggregation_name, aggregated_codes) in collect(ICD_10_aggregations)
    #             if line.causa_m in aggregated_codes
    #                 line.causa_m = aggregation_name
    #             end
    #         end
    #     end
    # end


    println("Loop 2/4")

    #trasf_trasposti_15_19_dc.CHIAVE  = trasf_trasposti_15_19_dc.id
    
    # Make sure that every ricovero has an unique CHIAVE (since CHIAVE is anno-specifica, it must be increased some times)
    trasf_trasposti_15_19_gby_ID_ANONIMO_RIC = groupby(trasf_trasposti_15_19_dc, :ID_ANONIMO_RIC )
    # Increase di CHIAVE when repeated over the years. See https://github.com/InPhyT/SEPI-SEREMI/blob/main/Fake_input/descrizione%20dati%20esempio%20SDO.docx
    i = 1
    P = Progress(size(trasf_trasposti_15_19_gby_ID_ANONIMO_RIC,1))
    P_lock = SpinLock()
    Threads.@threads for patient_dataframe in trasf_trasposti_15_19_gby_ID_ANONIMO_RIC #@showprogress 1
        lock(P_lock)
        chiavi_unique = Int64[]
        sizehint!(chiavi_unique, length(patient_dataframe.CHIAVE))
        chiave_non_unique = patient_dataframe.CHIAVE[1]
        chiave_unique = 1
        for chiave in patient_dataframe.CHIAVE
            if chiave == chiave_non_unique
                push!(chiavi_unique, chiave_unique)
            else
                chiave_non_unique = chiave
                chiave_unique += 1
                push!(chiavi_unique, chiave_unique)
            end
        end
        patient_dataframe.CHIAVE = chiavi_unique
        i += 1
        ProgressMeter.update!(P, i)
        unlock(P_lock)
    end

    #Delete unnecessary columns, sort by ID and process the trasf_trasposti_15_19_dc dataset
    trasf_trasposti_multiple_ricoveros_per_patient = combine(trasf_trasposti_15_19_gby_ID_ANONIMO_RIC, :ID_ANONIMO_RIC => :ID_SOGGETTO, :CHIAVE, :dt_ammiss, :dt_uscita, :repint, :trasf, :DIA_PRIN)
    sort!(trasf_trasposti_multiple_ricoveros_per_patient, :ID_SOGGETTO)
    processed_trasf_trasposti_multiple_ricoveros_per_patient = process_trasf_trasposti(trasf_trasposti_multiple_ricoveros_per_patient)




    # Produce a processed dataset like `processed_trasf_trasposti_multiple_ricoveros_per_patient` but since we don't know how to select one Ricovero among many using SDO data (unlike COVID-19 data), this dataset should produce a new patient (thus a new line) for every Ricovero a real patient had beyond the first one.
    ## Initialize the dataset
    trasf_trasposti_one_ricovero_per_patient = DataFrame([col => typeof( trasf_trasposti_15_19_dc[:,col] )() for col in names(trasf_trasposti_15_19_dc)]...)

    ## We'd also like to produce a join_all_processed-like dataset to later fit the pipeline. It will be solely based on the data_G and data_D provided by trasf_trasposti_15_19_dc. All other columns are artificial and made up.
    join_all_SDOs = [DataFrame(:ID => Int64[], :classe_eta => Int64[], :data_IS => Union{typeof(MVP),Date}[], :data_P => Date[], :data_G => Union{typeof(MVP),Date}[], :data_D => Union{typeof(MVP),Date}[], :DIA_PRIN => Vector{String}[]  ) for i in 1:Threads.nthreads()]

    println("Loop 3/4")
    # For every patient (that could have multiple Ricoveros)...
    i = 1
    P = Progress(size(trasf_trasposti_15_19_gby_ID_ANONIMO_RIC,1))
    P_lock = SpinLock()
    @showprogress 1 for (ID,patient_dataframe) in zip(keys(trasf_trasposti_15_19_gby_ID_ANONIMO_RIC), trasf_trasposti_15_19_gby_ID_ANONIMO_RIC)
        lock(P_lock)
        # ...Extract date of death (if present) from SDO
        # println("loop 3 = ", Threads.threadid())
        data_D = MVP
        if !is_MVP(patient_dataframe.mort_intraosp[end]) && patient_dataframe.mort_intraosp[end] == 1
            data_D = patient_dataframe.dt_dim[end]
        elseif !is_MVP(patient_dataframe.mort_intraosp[end]) && !(patient_dataframe.mort_intraosp[end] == 1)
            error("process_trasf_trasposti_15_19_to_join_alls; `mort_intraosp` column is expected to be composed only of '1's  (number, not string) and 'MVPs' (= $MVP). Found $(patient_dataframe.mort_intraosp[end]) for ID = $ID")
        end

  
        # Produce a new patient with a new ID for every Ricovero beyond the first one that this patient had.
        patient_dataframe_gby_CHIAVE = groupby(patient_dataframe, :CHIAVE)
        IDs = vcat(ID.ID_ANONIMO_RIC, (max_ID+1):(max_ID+length(patient_dataframe_gby_CHIAVE)-1) ) 
        max_ID += length((max_ID+1):(max_ID+length(patient_dataframe_gby_CHIAVE)-1))
        # @assert length(IDs) == length(patient_dataframe_gby_CHIAVE)
        for (new_ID, ricovero_dataframe,chiave_gkey) in zip(IDs,patient_dataframe_gby_CHIAVE,keys(patient_dataframe_gby_CHIAVE))
            # Check that the the ricovero has one and only one ICD_9_CM code
            # @assert length(unique(ricovero_dataframe.DIA_PRIN)) == 1

            # Change the ID
            ricovero_dataframe.ID_ANONIMO_RIC .= Int64(new_ID)
            # Add back the CHIAVE
            ricovero_dataframe.CHIAVE = repeat([chiave_gkey.CHIAVE], size(ricovero_dataframe,1))
            append!(trasf_trasposti_one_ricovero_per_patient, DataFrame(ricovero_dataframe))

            # Construct join_all_SDO based on the SDO hospitalizations
            if !is_MVP(data_D)
                push!(join_all_SDOs[Threads.threadid()], (new_ID, ricovero_dataframe.AGECL[1], MVP, Date("2015-01-01"), MVP, ricovero_dataframe.dt_dim[end], ricovero_dataframe.DIA_PRIN[end]))
            else
                push!(join_all_SDOs[Threads.threadid()], (new_ID, ricovero_dataframe.AGECL[1], MVP, Date("2015-01-01"), ricovero_dataframe.dt_dim[end], MVP, ricovero_dataframe.DIA_PRIN[end]))
            end
            

            # Also integrate the ICD_10 dataset with the ICD_9_CM dataset
            # if !is_MVP(data_D) && new_ID ∉ mort_2015_2018_dc.ID_ANONIMO_RIC
            #     push!(mort_2015_2018_dc, (99, new_ID, ricovero_dataframe.AGECL[1], data_D, missing, missing, ricovero_dataframe.DIA_PRIN[end] ))
            # elseif is_MVP(data_D) && new_ID ∉ mort_2015_2018_dc.ID_ANONIMO_RIC
            #     push!(mort_2015_2018_dc, (99, new_ID, ricovero_dataframe.AGECL[1], data_D, missing, ricovero_dataframe.dt_dim[end], ricovero_dataframe.DIA_PRIN[end]))
            # elseif !is_MVP(data_D) && new_ID ∈ mort_2015_2018_dc.ID_ANONIMO_RIC
            #     mort_2015_2018_dc[ findfirst( x -> x == new_ID, mort_2015_2018_dc.ID_ANONIMO_RIC), "ICD_9_CM"] = ricovero_dataframe.DIA_PRIN[end]
                # if !is_MVP(ricovero_dataframe.dt_dim[end])
                #     mort_2015_2018_dc[ findfirst( x -> x == new_ID, mort_2015_2018_dc.ID_ANONIMO_RIC), "dt_mort"] = ricovero_dataframe.dt_dim[end]
                # end
            # end

        end
        i += 1
        ProgressMeter.update!(P, i)
        unlock(P_lock)
    end

    join_all_SDO = reduce(vcat, join_all_SDOs) 

    
    # Select and rename useful columns, and sort by ID
    trasf_trasposti_one_ricovero_per_patient = combine(trasf_trasposti_one_ricovero_per_patient, :ID_ANONIMO_RIC => :ID_SOGGETTO, :CHIAVE, :dt_ammiss, :dt_uscita, :repint, :trasf, :DIA_PRIN)
    sort!(trasf_trasposti_one_ricovero_per_patient, :ID_SOGGETTO)


    # Add positivity and symptoms onset date to the ICD_9_CM-integrated ICD_10 mortality dataset
    # mort_2015_2018_dc.data_P = repeat([Date("2015-01-01")], size(mort_2015_2018_dc,1))
    # mort_2015_2018_dc.data_IS = repeat([MVP], size(mort_2015_2018_dc,1))
    # println(names(mort_2015_2018_dc))
    # Select and rename useful columns from the ICD_9_CM-integrated ICD_10 mortality dataset and sort by ID
    # mort_2015_2018_dc = combine( mort_2015_2018_dc, :ID_ANONIMO_RIC => :ID, :AGECL => :classe_eta,:data_G, :dt_mort => :data_D, :causa_m => :ICD_10, :ICD_9_CM ) #  :data_IS, :data_P, 
    # sort!(mort_2015_2018_dc, :ID)



    # Instantiate the various Dict{ICD_9_CM, DataFRame} that will stratify the tras_trasposti-like and the join_all-like datasets by ICD_9_CM code.
    ICD9CM_processedTrasfTraspostiOne_dct  = OrderedDict{String, DataFrame}()
    ICD9CM_processed_joinAll_dct           = OrderedDict{String, DataFrame}()
    ICD9CM_processedPositiviQuarantena_dct = OrderedDict{String, DataFrame}()

    @showprogress 1 for aggregation_name in vcat(collect(keys(ICD_9_CM_aggregations["aggregations"])),"excluded")
        processed_trasf_trasposti = process_trasf_trasposti(trasf_trasposti_one_ricovero_per_patient[in.(Ref(aggregation_name),trasf_trasposti_one_ricovero_per_patient.DIA_PRIN), :] )
        if size(processed_trasf_trasposti,1) > 0
            push!(ICD9CM_processedTrasfTraspostiOne_dct, aggregation_name => process_trasf_trasposti(trasf_trasposti_one_ricovero_per_patient[in.(Ref(aggregation_name),trasf_trasposti_one_ricovero_per_patient.DIA_PRIN), :] ) )
            push!(ICD9CM_processed_joinAll_dct, aggregation_name => select(join_all_SDO[in.(Ref(aggregation_name),join_all_SDO.DIA_PRIN), :], Not(:DIA_PRIN)) )
            IDs = ICD9CM_processedTrasfTraspostiOne_dct[aggregation_name].ID
            push!(ICD9CM_processedPositiviQuarantena_dct, aggregation_name => DataFrame( ID = IDs, date_IQ = repeat([MVP], length(IDs)), date_FQ = repeat([MVP], length(IDs))  ) )
        end
    end


    # # Group tras_trasposti-like and the join_all-like datasets by ICD_9_CM code
    # trasf_trasposti_one_ricovero_per_patient_gby_DIA_PRIN = groupby(trasf_trasposti_one_ricovero_per_patient, :DIA_PRIN)
    # join_all_SDO_gby_DIA_PRIN = groupby(join_all_SDO, :DIA_PRIN)

    # # Check that the  tras_trasposti-like and the the join_all-like datasets have the same codes
    # @assert length(setdiff(collect(keys(trasf_trasposti_one_ricovero_per_patient_gby_DIA_PRIN)),collect(keys(join_all_SDO_gby_DIA_PRIN)))) == 0 #collect(keys(trasf_trasposti_one_ricovero_per_patient_gby_DIA_PRIN)) == collect(keys(join_all_SDO_gby_DIA_PRIN)) # 
    # println("Loop 4/4")
    # # The ordering of the keys is identical to the ordering of the groups of gd under iteration and integer indexing. See https://dataframes.juliadata.org/stable/lib/functions/#Base.keys
    # @showprogress 1 for (tt_ICD_9_CM_gkey,ja_ICD_9_CM_gkey) in zip(keys(trasf_trasposti_one_ricovero_per_patient_gby_DIA_PRIN),keys(join_all_SDO_gby_DIA_PRIN)) 
    #     push!(ICD9CM_processedTrasfTraspostiOne_dct, tt_ICD_9_CM_gkey.DIA_PRIN => process_trasf_trasposti(DataFrame(trasf_trasposti_one_ricovero_per_patient_gby_DIA_PRIN[tt_ICD_9_CM_gkey])) )
    #     push!(ICD9CM_processed_joinAll_dct, ja_ICD_9_CM_gkey.DIA_PRIN => select(join_all_SDO_gby_DIA_PRIN[ja_ICD_9_CM_gkey], Not(:DIA_PRIN)) )
    #     IDs = ICD9CM_processedTrasfTraspostiOne_dct[tt_ICD_9_CM_gkey.DIA_PRIN].ID
    #     push!(ICD9CM_processedPositiviQuarantena_dct, tt_ICD_9_CM_gkey.DIA_PRIN => DataFrame( ID = IDs, date_IQ = repeat([MVP], length(IDs)), date_FQ = repeat([MVP], length(IDs))  ) )
    # end

    sort!(ICD9CM_processedTrasfTraspostiOne_dct, byvalue = false)
    sort!(ICD9CM_processed_joinAll_dct, byvalue = false)

    

    # Return
    return processed_trasf_trasposti_multiple_ricoveros_per_patient, ICD9CM_processedTrasfTraspostiOne_dct, ICD9CM_processed_joinAll_dct, ICD9CM_processedPositiviQuarantena_dct #, mort_2015_2018_dc

end

function pad_with_zeroes(str::String, n_zeroes::Int64)
    output = deepcopy(str)
    if n_zeroes == 1
        output = "0"*output
    elseif n_zeroes == 2
        output = "00"*output
    end
    return output
end


function convert_ICD9_codes_to_strings(ICD9_codes::Vector{String}, keep_digits::Union{Int64,Nothing})
    #all_codes = [string(code) for code in  unique(vcat(collect(values(ICD_9_CM_translations))...))]
    splits_pre_dot = [split(code,".")[1] for code in ICD9_codes]
    ICD9_codes_strings = [pad_with_zeroes(code, 3-length(split_pre_dot)) for (code,split_pre_dot) in zip(ICD9_codes, splits_pre_dot)]
    if typeof(keep_digits) == Int64
        return unique([code[1:keep_digits] for code in replace.(ICD9_codes_strings, Ref("." => "")) if cmp(code,"Inf") != 0])
    elseif typeof(keep_digits) == Nothing
        unique([code for code in replace.(ICD9_codes_strings, Ref("." => "")) if cmp(code,"Inf") != 0])
    end
end
