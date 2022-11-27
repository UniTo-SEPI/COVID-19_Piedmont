########################
#### DATA PROCESSING ###
########################

####### IS,P,G,D #######
"""
    process_join_all(join_all_df::DataFrame, events_dates_names::Dict{Symbol,Symbol}; MVP = missing, is_MVP::F = ismissing) where {F <: Function}

Process the raw individual-level surveillance dataset `join_all_df`, with events dates names `events_dates_names`, missing values placeholder `MVP` and missing values check function `is_MVP`.

# KEY EVENTS
- Symptoms onset (IS: `inizio_sintomi`); 
- Diagnosis / Positivity (P: `positività`);
- Recovery (G: `guarigione`);
- Death (D: `decesso`).
"""
function process_join_all(join_all_df::DataFrame, events_dates_names::Dict{Symbol,Symbol}, with_is::Bool; MVP = missing, is_MVP::F = ismissing) where {F<:Function}
    # Deepcopy the input
    join_all_df_dc::DataFrame = deepcopy(join_all_df)

    # Substitute "" strings with `MVP` values in columns `dt_sintomi_30`, `dt_sintomi_20` and `dt_sintomi_10` for coherence with the other columns
    transform!(join_all_df_dc, :dt_sintomi_30 => (x -> [is_MVP(el) ? MVP : el for el in x]), :dt_sintomi_20 => (x -> [is_MVP(el) ? MVP : el for el in x]), :dt_sintomi_10 => x -> [is_MVP(el) ? MVP : el for el in x], renamecols = false)

    # Assume that each row has a unique ID (https://github.com/InPhyT/SEPI-SEREMI/issues/2)
    @assert length(unique(join_all_df_dc.ID_SOGGETTO)) == length(join_all_df_dc.ID_SOGGETTO)

    # Pre-allocate processed columns
    ID = Int64[]
    classe_eta = Int64[]
    data_IS_30 = Union{Missing,Date}[]
    data_IS_20 = Union{Missing,Date}[]
    data_IS_10 = Union{Missing,Date}[]
    data_P = Date[]
    data_G = Union{Missing,Date}[]
    data_D = Union{Missing,Date}[]

    # Loop over rows of the raw `join_all_df_dc`, and reorganize their contents
    for line in eachrow(join_all_df_dc)
        # Push ID_SOGGETTO to vector
        push!(ID, line["ID_SOGGETTO"])

        # Push date of positivity / diagnosis to vector 
        push!(data_P, line["dt_positivo"])

        # If the patient has died from COVID-19, push the date of death to vector
        if line["mortocovid"] == 1 && !isnan(line["guarigione"])
            push!(data_D, line["damor"])
            push!(data_G, MVP)
        elseif line["mortocovid"] == 1
            push!(data_D, line["damor"])
            push!(data_G, MVP)
        elseif !isnan(line["guarigione"])
            push!(data_G, line["dt_guarigione"])
            push!(data_D, MVP)
        else
            push!(data_G, MVP)
            push!(data_D, MVP)
        end

        #line["mortocovid"] == 1 ? push!(data_D, line["damor"]) : push!(data_D,MVP)

        # Push age class to vector.
        push!(classe_eta, line["agecl"])

        # Push dates of symptoms onset (depending on the plausibility interval) to vector
        if with_is
            ismissing(line["dt_sintomi_30"]) || line["dt_sintomi_30"] == "" ? push!(data_IS_30, MVP) : push!(data_IS_30, Date(line["dt_sintomi_30"],dateformat"d/m/y")) # line["dt_sintomi_30"] # Date(line["dt_sintomi_30"],dateformat"d/m/y")
            ismissing(line["dt_sintomi_20"]) || line["dt_sintomi_20"] == "" ? push!(data_IS_20, MVP) : push!(data_IS_20, Date(line["dt_sintomi_20"],dateformat"d/m/y")) # line["dt_sintomi_20"] # Date(line["dt_sintomi_20"],dateformat"d/m/y")
            ismissing(line["dt_sintomi_10"]) || line["dt_sintomi_10"] == "" ? push!(data_IS_10, MVP) : push!(data_IS_10, Date(line["dt_sintomi_10"],dateformat"d/m/y")) # line["dt_sintomi_10"] # Date(line["dt_sintomi_10"],dateformat"d/m/y")
        else
            push!(data_IS_30, MVP)
            push!(data_IS_20, MVP)
            push!(data_IS_10, MVP)
        end


        # Push recovery date to vector (from descrizione dati esempio.docx, line["dt_guarigione"] can be 1 or NaN)
        # println("ID = ", line["ID_SOGGETTO"]," line['mortocovid'] = ", line["mortocovid"], "line['guarigione'] = ", line["guarigione"])

        #!isnan(line["guarigione"]) ? push!(data_G, line["dt_guarigione"]) : push!(data_G, MVP)

    end

    # Output a dataset for each plausibility interval

    join_all_df_30 = DataFrame(:ID => ID, :classe_eta => classe_eta, events_dates_names[:data_IS] => data_IS_30, events_dates_names[:data_P] => data_P, events_dates_names[:data_G] => data_G, events_dates_names[:data_D] => data_D)
    join_all_df_20 = DataFrame(:ID => ID, :classe_eta => classe_eta, events_dates_names[:data_IS] => data_IS_20, events_dates_names[:data_P] => data_P, events_dates_names[:data_G] => data_G, events_dates_names[:data_D] => data_D)
    join_all_df_10 = DataFrame(:ID => ID, :classe_eta => classe_eta, events_dates_names[:data_IS] => data_IS_10, events_dates_names[:data_P] => data_P, events_dates_names[:data_G] => data_G, events_dates_names[:data_D] => data_D)

    # Check that every line of every output DataFrame as either a data_G XOR data_D. We should check it later
    # for df in (join_all_df_10, join_all_df_20, join_all_df_30)
    #     for row in eachrow(df)
    #         println(row.data_G, " ", row.data_D)
    #         @assert is_MVP(row.data_G) ⊻ is_MVP(row.data_D)
    #     end
    # end
    return join_all_df_30, join_all_df_20, join_all_df_10
end

###### QUARANTENE ######
"""
    process_positivi_quarantena(positivi_quarantena_df::DataFrame, events_dates_names::Dict{Symbol,Symbol}; MVP = missing, is_MVP::F = ismissing) where {F <: Function}

Process the raw individual-level surveillance dataset `positivi_quarantena_df`, with events dates names `events_dates_names`, missing values placeholder `MVP` and missing values check function `is_MVP`.

# KEY EVENTS
- First day of quarantine / isolation (IQ: `inizio_quarantena`);
- Last day of quarantine / isolation (FQ: `fine_quarantena`).
"""
function process_positivi_quarantena(positivi_quarantena_df::DataFrame, events_dates_names::Dict{Symbol,Symbol}; MVP = missing, is_MVP::F = ismissing) where {F<:Function}
    # Deepcopy the input
    positivi_quarantena_df_dc = deepcopy(positivi_quarantena_df)

    # Remove lines where the ID_SOGGETTO is undefined
    positivi_quarantena_df_dc = positivi_quarantena_df_dc[.!isnan.(positivi_quarantena_df_dc.ID_SOGGETTO), :]

    # Pre-allocate a DefaultDict whose pairs are ID => (date_IQ,date_FQ)
    # ID_dates_dct = DefaultDict{Int64,Tuple{Vector{Date},Vector{Date}}}((Date[],Date[]))
    ID_dates_dct = DefaultOrderedDict{Int64,Dict{String,Vector{Date}}}(Dict("inizi" => Date[], "fini" => Date[]))

    for line in eachrow(positivi_quarantena_df_dc)
        # If the `dt_quarantena` date is labelled as `inizio=1` then treat it as a `data_IQ`, otherwise as a `data_FQ`
        inizi = deepcopy(ID_dates_dct[line["ID_SOGGETTO"]]["inizi"])
        fini = deepcopy(ID_dates_dct[line["ID_SOGGETTO"]]["fini"])
        line["inizio"] == 1 ? push!(inizi, line["dt_quarantena"]) : push!(fini, line["dt_quarantena"])
        ID_dates_dct[line["ID_SOGGETTO"]] = Dict("inizi" => inizi, "fini" => fini)
    end

    # DataFrame that contains elements like `Date[]` when for instance the line has a date_IQ but has no date_FQ (or viceversa)
    positivi_quarantena_processed_df = sort(DataFrame(:ID => collect(keys(ID_dates_dct)), events_dates_names[:date_IQ] => [vals["inizi"] for vals in collect(values(ID_dates_dct))], events_dates_names[:date_FQ] => [vals["fini"] for vals in collect(values(ID_dates_dct))]), [:ID])

    # Substitute elements like Date[] with missing
    positivi_quarantena_processed_df.date_IQ = [dates == Date[] ? MVP : dates for dates in positivi_quarantena_processed_df.date_IQ]
    positivi_quarantena_processed_df.date_FQ = [dates == Date[] ? MVP : dates for dates in positivi_quarantena_processed_df.date_FQ]

    # Return dataframe sorted by ID
    return positivi_quarantena_processed_df
end

####### RICOVERI #######
"""
    process_trasf_trasposti(trasf_trasposti_df::DataFrame, events_dates_names::Dict{Symbol,Symbol}; MVP = missing, is_MVP::F = ismissing) where {F <: Function}

Process the raw individual-level surveillance dataset `trasf_trasposti_df`, with events dates names `events_dates_names`, missing values placeholder `MVP` and missing values check function `is_MVP`.

# KEY EVENTS
- Admission to ordinary hospital ward (AO: `ammissione_ordinaria`); 
- Discharge from ordinary hospital ward (DO: `dimissione_ordinaria`); 
- Admission to intensive hospital ward (AI: `ammissione_intensiva`); 
- Discharge from intensive hospital ward (DI: `dimissione_intensiva`).
"""
function process_trasf_trasposti(trasf_trasposti_df::DataFrame)
    # Deepcopy the input
    trasf_trasposti_df_dc::DataFrame = deepcopy(trasf_trasposti_df)

    # Pre-allocate a Dict whose pairs are ID => (Ricovero_1, Ricovero_2,...)
    ID_ricoveri_dct = OrderedDict{Int64,Vector{Ricovero}}() #Tuple{Vararg{Ricovero}}

    # Group `trasf_trasposti_df_dc` by ID_SOGGETTO
    trasf_trasposti_by_ID_gd = groupby(trasf_trasposti_df_dc, :ID_SOGGETTO)

    # Loop over groups and their corresponding keys    
    for (trasf_trasposti_by_ID, groupkey) in zip(trasf_trasposti_by_ID_gd, keys(trasf_trasposti_by_ID_gd))
        # Pre-allocate the vector that will contain all the `Recovero`s for this ID_SOGGETTO
        ricoveri = Ricovero[]

        # Group by Chiave (which identifies an hospitalization event)
        trasf_trasposti_by_ID_by_CHIAVE_gd = groupby(trasf_trasposti_by_ID, :CHIAVE)

        # Loop over groups identified by ID_SOGGETTO and CHIAVE (thus by a patient and an hospitalization event), construct the `Ricovero`s and push them to `ricoveri`. 
        for trasf_trasposti_by_ID_by_CHIAVE in trasf_trasposti_by_ID_by_CHIAVE_gd

            reparti = Reparto[]
            for trasferimento in eachrow(trasf_trasposti_by_ID_by_CHIAVE)
                push!(reparti, Reparto(data_ammissione = trasferimento.dt_ammiss, data_dimissione = trasferimento.dt_uscita, tipo = Bool(trasferimento.repint) ? :intensivo : :ordinario))
            end

            push!(ricoveri, Ricovero(reparti))
        end

        # Create the corresponding ID => ricoveri pair in the dict
        ID_ricoveri_dct[groupkey.ID_SOGGETTO] = ricoveri
    end

    # Return the DataFrame sorted by ID
    return sort(DataFrame(:ID => collect(keys(ID_ricoveri_dct)), :ricoveri => collect(values(ID_ricoveri_dct))), [:ID])
end


"""
    outerjoin_and_replace_missing(join_all_processed::DataFrame, positivi_quarantena_processed::DataFrame, trasf_trasposti_processed::DataFrame, line_lists_columns::Vector{Symbol}; on = [:ID])

Perform `outerjoin(join_all_processed, positivi_quarantena_processed, trasf_trasposti_processed, on = [:ID])`, sort by ID and select only columns `line_lists_columns`. Also compute the upper whiskers for the time delays of P_FP, P_G and P_D.
"""
function outerjoin_and_replace_missing(join_all_processed::DataFrame, positivi_quarantena_processed::DataFrame, trasf_trasposti_processed::DataFrame, line_lists_columns::Vector{Symbol}; on = [:ID], MVP, is_MVP::F) where {F<:Function}
    # Outerjoin, sort by ID and reorder columns

    joined_df = select(sort(outerjoin(join_all_processed, positivi_quarantena_processed, trasf_trasposti_processed; on = [:ID]), [:ID]), line_lists_columns) # select(sort(outerjoin(leftjoin(join_all_processed, positivi_quarantena_processed; on = [:ID]), leftjoin(join_all_processed, trasf_trasposti_processed; on = [:ID]) ;on = [:ID]),[:ID, :classe_eta, :data_IS, :data_P, :data_G , :data_D]), line_lists_columns)#

    joined_df = joined_df[.!(is_MVP.(joined_df.data_P)), :]

    # Evaluate upper and lower whisker statistics (https://towardsdatascience.com/5-ways-to-detect-outliers-that-every-data-scientist-should-know-python-code-70a54335a623)
    # We need these quantities to later set an upper bound to the difference between data_G (or data_D) and data_P for the former to be meaningful
    P_FP_delay_distribution = Int64[]
    P_G_delay_distribution = Int64[]
    P_D_delay_distribution = Int64[]

    for line in eachrow(joined_df)
        data_FP = !is_MVP(line.data_G) ? line.data_G : line.data_D
        if !is_MVP(data_FP)
            push!(P_FP_delay_distribution, Dates.value(data_FP - line.data_P))
        end

        if !is_MVP(line.data_G)
            push!(P_G_delay_distribution, Dates.value(line.data_G - line.data_P))
        end

        if !is_MVP(line.data_D)
            push!(P_D_delay_distribution, Dates.value(line.data_D - line.data_P))
        end
    end

    upper_whiskers = Day[]
    sizehint!(upper_whiskers, 3)

    # Compute upper whiskers for P_FP, P_G and P_D
    for empirical_distribution in (P_FP_delay_distribution, P_G_delay_distribution, P_D_delay_distribution)
        if !isempty(empirical_distribution)
            q3 = quantile(empirical_distribution, 0.75)
            iqr = quantile(empirical_distribution, 0.25)
            uw = Dates.Day(ceil(q3 + 1.5 * iqr))
            push!(upper_whiskers, uw)
        else
            push!(upper_whiskers, Day(0))
        end
    end

    # # Compute the quantile for P_FP, P_G and P_D
    # q3_FP = !isempty(P_FP_delay_distribution) ? quantile(P_FP_delay_distribution, 0.75) : NaN
    # q3_G  = !isempty(P_G_delay_distribution)  ? quantile(P_G_delay_distribution, 0.75)  : NaN
    # q3_D  = !isempty(P_D_delay_distribution)  ? quantile(P_D_delay_distribution, 0.75)  : NaN

    # # Compute inter-quantile range for P_FP, P_G and P_D
    # iqr_FP = !isempty(P_FP_delay_distribution) ? q3_FP - quantile(P_FP_delay_distribution, 0.25) : NaN
    # iqr_G  = !isempty(P_G_delay_distribution)  ? q3_G  - quantile(P_G_delay_distribution, 0.25)  : NaN
    # iqr_D  = !isempty(P_D_delay_distribution)  ? q3_D  - quantile(P_D_delay_distribution, 0.25)  : NaN

    # # Compute upper whiskers for P_FP, P_G and P_D
    # P_FP_uw = Dates.Day(ceil(q3_FP + 1.5*iqr_FP))
    # P_G_uw  = Dates.Day(ceil(q3_G + 1.5*iqr_G))
    # P_D_uw  = Dates.Day(ceil(q3_D + 1.5*iqr_D))

    return joined_df, upper_whiskers... # P_FP_uw, P_G_uw, P_D_uw
end