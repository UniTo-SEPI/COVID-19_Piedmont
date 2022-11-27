########################
#### DATA PROCESSING ###
########################

####### RICOVERI #######

"""
    process_ricoveri(joined_df::DataFrame, events_dates_names::Dict{Symbol,Symbol}; MVP = missing, is_MVP::F = ismissing) where {F <: Function} 

Process the hospital-related component of the integrated individual-level surveillance dataset `joined_df` according to the "Ricoveri" section in the data model description manual.

# KEY EVENTS
- Admission to ordinary hospital ward (AO: `ammissione_ordinaria`); 
- Discharge from ordinary hospital ward (DO: `dimissione_ordinaria`); 
- Admission to rehabilitative hospital ward (AR: `ammissione_riabilitativa`); 
- Discharge from rehabilitative hospital ward (DR: `dimissione_riabilitativa`); 
- Admission to intensive hospital ward (AI: `ammissione_intensiva`); 
- Discharge from intensive hospital ward (DI: `dimissione_intensiva`).
"""
function process_ricoveri(joined_df::DataFrame, events_dates_names::Dict{Symbol,Symbol}; with_riabilitativo::Bool,  MVP = missing, is_MVP::F = ismissing) where {F <: Function} 
    # Deepcopy the input 
    joined_df_dc = deepcopy(joined_df)

    # Create a dictionary for data quality assessment
    assessments = ("repartos_before_positivity_removed", "ricoveros_before_positivity_removed", "lines_before_positivity_removed", "positivity_date_moved_to_ammission", "ordinary_repartos_between_two_intensive_repartos_removed", "successive_repartos_of_same_nature_merged", "successive_repartos_of_different_nature_juxtaposed", "rehabilitation_repartos_imputed")
    data_quality_IDs = Dict{String, Vector{Int64}}(assessment => Int64[] for assessment in assessments)

    # Pre-allocate temporary dataframe that will contain the ID, data_IQP, data_FQP, data_IQO, data_FQO columns
    line_list_ricoveri = DataFrame(:ID => Int64[], :classe_eta => [], events_dates_names[:data_IS] => Union{typeof(MVP),Date}[],  events_dates_names[:data_P] => Date[], :date_IQ => Union{typeof(MVP),Vector{Date}}[], :date_FQ => Union{typeof(MVP),Vector{Date}}[], events_dates_names[:data_AO] => Union{typeof(MVP),Date}[], events_dates_names[:data_DO] => Union{typeof(MVP),Date}[], events_dates_names[:data_AI] => Union{typeof(MVP),Date}[], events_dates_names[:data_DI] => Union{typeof(MVP),Date}[], events_dates_names[:data_AR] => Union{typeof(MVP),Date}[], events_dates_names[:data_DR] => Union{typeof(MVP),Date}[], events_dates_names[:data_G] => Union{typeof(MVP),Date}[], events_dates_names[:data_D] => Union{typeof(MVP),Date}[])

    # Loop over the deep-copied dataframe
    for line in eachrow(joined_df_dc)
        # Pre-allocate the vector of Reporto objects 
        reparti = Reparto[] 

        # Trascurare i reparti che avvengono interamente prima o la cui `data_dimissione` coincide con la `data_positività`. Trascurare i ricoveri avvenuti dopo la `data_fine_percorso`.
        if !is_MVP(line.ricoveri)
            ricoveros_tbr = Int64[]
            for (i,ricovero) in enumerate(line.ricoveri)
                repartos_tbr = Int64[]
                for (j,reparto) in enumerate(ricovero.reparti)
                    data_FP = !is_MVP(line.data_G) ? line.data_G : line.data_D 
                    if reparto <= line.data_P || (!is_MVP(data_FP) && reparto > data_FP)
                        push!(repartos_tbr,j)
                        # data_quality["repartos_before_positivity_removed"] += 1
                        push!(data_quality_IDs["repartos_before_positivity_removed"], line.ID)
                    end
                end
                deleteat!(ricovero.reparti, repartos_tbr)
                if length(ricovero.reparti) == 0
                    push!(ricoveros_tbr, i)
                    # data_quality["ricoveros_before_positivity_removed"] += 1
                    push!(data_quality_IDs["ricoveros_before_positivity_removed"], line.ID)
                end
            end
            # If the ricovero has no more Repartos, remove the ricovero
            deleteat!(line.ricoveri, ricoveros_tbr)
        end

        # If the line has no more Ricoveros, set the line.ricoveri field to MVP
        if length(line.ricoveri) == 0
            #println("deleted!")
            line.ricoveri = MVP
            # data_quality["lines_before_positivity_removed"] += 1
            push!(data_quality_IDs["lines_before_positivity_removed"], line.ID)
        # Otherwise, process Repartos so that they are organized in :ordinario, :intensivo and :riabilitativo, and the data_dimissione of a Reparto coincides with the data_ammissione of the following. Remove Repartos :ordinario when in between two :intensivos.
        else

            # Collect all Repartos
            reparti = [reparto for ricovero in line.ricoveri for reparto in ricovero.reparti]
            sort!(reparti, by = x -> x.data_ammissione)
            sort!(reparti, by = x -> x.data_dimissione)
            # reparti_unprocessed = deepcopy(reparti)


            # Evaluate useful quantities
            date_ammissione_x = [reparto.data_ammissione for ricovero in line.ricoveri for reparto in ricovero.reparti] 

            # Per ciò che concerne tutti i pazienti che possiedono `min(data_ammissione_x)` (con `x = ordinaria` o `x = intensiva`) precedente alla `data_positività` si dovrà procedere impostando `data_positività = min(data_ammissione_x)`.
            if minimum(date_ammissione_x) < line.data_P
                line.data_P = minimum(date_ammissione_x)
                # data_quality["positivity_date_moved_to_ammission"] += 1
                push!(data_quality_IDs["positivity_date_moved_to_ammission"], line.ID)
            end

            # Combine and move Repartos' dates if they are more than one so that the population will be preserved when calibrating models
            if length(reparti) > 1
                again = true
                while again
                    again = false
                    reparti_new = Reparto[]
                    #println("reparti = $reparti")
                    for i in 1:(length(reparti))
                        # Sono da trascurare reparti ordinari tra coppie di reparti intensivi;
                        if 1<i< length(reparti) &&  (reparti[i].tipo == :ordinario) && reparti[i-1].tipo == :intensivo && reparti[i+1].tipo == :intensivo
                            again = true
                            #println("1")
                            reparti_new = vcat(reparti_new, reparti[i+1:end])
                            # data_quality["ordinary_repartos_between_two_intensive_repartos_removed"] += 1
                            push!(data_quality_IDs["ordinary_repartos_between_two_intensive_repartos_removed"], line.ID)
                            break 
                        end
                        # SE due reparti successivi sono dello stesso tipo allora i due reparti saranno sostituiti da un reparto che avrà come `data_ammissione` la `data_ammissione` del primo e come `data_dimissione` la `data_dimissione` del secondo.
                        if i < length(reparti) && (reparti[i].data_dimissione <= reparti[i+1].data_ammissione) && (reparti[i].tipo == reparti[i+1].tipo) 
                            push!(reparti_new, Reparto(data_ammissione = reparti[i].data_ammissione, data_dimissione =  reparti[i+1].data_dimissione, tipo = reparti[i].tipo))
                            reparti_new = vcat(reparti_new, reparti[i+2:end])
                            again = true
                            # data_quality["successive_repartos_of_same_nature_merged"] += 1
                            push!(data_quality_IDs["successive_repartos_of_same_nature_merged"], line.ID)
                            break
                        # ALTRIMENTI SE due reparti successivi sono di tipo diverso ma la `data_ammissione` del secondo non coincide con la `data_dimissione` del primo, allora si porterà la `data_dimissione` del primo alla `data_ammissione` del secondo.
                        elseif i < length(reparti) &&  (reparti[i].data_dimissione < reparti[i+1].data_ammissione) && !(reparti[i].tipo == reparti[i+1].tipo)
                            push!(reparti_new, Reparto(data_ammissione = reparti[i].data_ammissione, data_dimissione   =  reparti[i+1].data_ammissione, tipo = reparti[i].tipo))
                            push!(reparti_new, Reparto(data_ammissione = reparti[i+1].data_ammissione, data_dimissione =  reparti[i+1].data_dimissione, tipo = reparti[i+1].tipo))
                            reparti_new = vcat(reparti_new, reparti[i+2:end])
                            again = true
                            # data_quality["successive_repartos_of_different_nature_juxtaposed"] +=1
                            push!(data_quality_IDs["successive_repartos_of_different_nature_juxtaposed"], line.ID)
                            break
                        else
                            push!(reparti_new, reparti[i])
                        end

                    end
                    reparti = reparti_new
                end
            end

            # Check that we have at maximum three Repartos, and that they are ordered as (:ordinario, :intensivo, :riabilitativo)
            
            @assert length(reparti) <= 3
#=             if length(reparti) > 3
                println(line)
                println("\n\n da processare \n\n")
                for reparto in reparti_unprocessed
                    println(reparto)
                end
                println("\n\n processato \n\n")
                for reparto in reparti
                    println(reparto)
                end
                println("\n\n non processati \n\n")
                for ricovero in line.ricoveri
                    println(ricovero)
                end
            end =#
            # for (tipo, tipo_ammesso) in zip([reparto.tipo for reparto in reparti], (:ordinario, :intensivo, :ordinario))
            #     @assert tipo == tipo_ammesso
            # end

            # Convert repint = 0 Repartos to :riabilitativo if they come after an :intensivo
            for (i,_) in enumerate(reparti)
                if i> 1 && reparti[i].tipo == :ordinario && reparti[i-1].tipo == :intensivo
                    reparti[i].tipo = :riabilitativo
                    # data_quality["rehabilitation_repartos_imputed"] =+ 1
                    push!(data_quality_IDs["rehabilitation_repartos_imputed"], line.ID)
                end
            end
        end

        # Extract data_AO, data_DO, data_AI, data_DI, data_AR, data_DR from the resulting Repartos and organize them to DataFrame
        data_AO = MVP
        data_DO = MVP

        data_AI = MVP
        data_DI = MVP

        data_AR = MVP
        data_DR = MVP

        reparto_ordinario     = filter(r -> r.tipo == :ordinario,     reparti)
        reparto_intensivo     = filter(r -> r.tipo == :intensivo,     reparti)
        reparto_riabilitativo = filter(r -> r.tipo == :riabilitativo, reparti)
        
        if !isempty(reparto_ordinario)
            data_AO = reparto_ordinario[1].data_ammissione
            data_DO = reparto_ordinario[1].data_dimissione
        end

        if !isempty(reparto_intensivo)
            data_AI = reparto_intensivo[1].data_ammissione
            data_DI = reparto_intensivo[1].data_dimissione
        end

        if with_riabilitativo

            if !isempty(reparto_riabilitativo)
                data_AR = reparto_riabilitativo[1].data_ammissione
                data_DR = reparto_riabilitativo[1].data_dimissione
            end

        end
#= 
        if is_MVP(line.data_P)
            println(line)
        end
 =#
        push!(line_list_ricoveri, (line.ID, line.classe_eta , line.data_IS, line.data_P, line.date_IQ, line.date_FQ,data_AO, data_DO, data_AI, data_DI, data_AR, data_DR, line.data_G, line.data_D))
    end

    data_quality = Dict{String, Int64}(assessment => length(IDs) for (assessment,IDs) in collect(data_quality_IDs))

    return line_list_ricoveri, data_quality_IDs, data_quality
end

###### QUARANTENE ######

"""
    date_quarantena_no_ricoveri_compact(line::DataFrameRow{DataFrame, DataFrames.Index}, T_quarantena::Day, P_G_uw::Day, P_D_uw::Day; MVP, is_MVP::F) where {F <: Function}

Process a `line` of the quarantine-related component of the integrated individual-level surveillance dataset according to the "Quarentene" section in the data model description manual.

# KEY EVENTS
- First day of precautionary quarantine / isolation (IQP: `inizio_quarantena_precauzionale`);
- Last day of precautionary quarantine / isolation (FQP: `fine_quarantena_precauzionale`);
- First day of ordinary quarantine / isolation (IQO: `inizio_quarantena_ordinaria`);
- Last day of ordinary quarantine / isolation (FQO: `fine_quarantena_ordinaria`);
"""
function date_quarantena_no_ricoveri_compact(line::DataFrameRow{DataFrame, DataFrames.Index}, T_quarantena::Day, P_G_uw::Day, P_D_uw::Day, data_quality_IDs_IDs::Dict{String,Vector{Int64}}, data_quality_counts::Dict{String,Int64}; MVP, is_MVP::F) where {F <: Function}
    # Compute selected_data_inizio_quarantena
    selected_data_inizio_quarantena = Date[]

    # Create a dictionary for data quality assessment
    # assessments = ("date_inizio_quarantena_discarded", "data_fine_quarantena_precauzionale_imputed", "data_inizio_quarantena_ordinaria_imputed", "data_fine_quarantena_ordinaria_imputed")
    # data_quality = Dict{String,Int64}(assessment => 0 for assessment in assessments)

    # Construct {selected_data_inizio_quarantena_i}
    if length(line.date_IQ) != 0
        push!(selected_data_inizio_quarantena, line.date_IQ[1])
        # Loop for as many times as the maximum elements of selected_data_inizio_quarantena (-1). Break when out of elements.
        for i in 1:((maximum(line.date_IQ)-minimum(line.date_IQ))÷T_quarantena)
            next_element = check_minimum([date for date in line.date_IQ if date > (selected_data_inizio_quarantena[end] + T_quarantena)], MVP = MVP, is_MVP = is_MVP)
            !is_MVP(next_element) ? push!(selected_data_inizio_quarantena,next_element) : break
        end
    end

    # Pre-allocate output dates
    data_inizio_quarantena_precauzionale = MVP
    data_fine_quarantena_precauzionale   = MVP
    data_inizio_quarantena_ordinaria     = MVP
    data_fine_quarantena_ordinaria       = MVP

    # data_inizio_quarantena_precauzionale = max({selected_data_inizio_quarantena_i < data_positività})
    data_inizio_quarantena_precauzionale = !is_MVP(selected_data_inizio_quarantena) ? check_maximum([date for date in selected_data_inizio_quarantena if date < line.data_P], MVP = MVP, is_MVP = is_MVP) : MVP
    data_quality_counts["date_inizio_quarantena_discarded"] += length(line.date_IQ) != 0 ?  length([date for date in line.date_IQ if date < line.data_P]) : 0
    length(line.date_IQ) != 0 ? push!(data_quality_IDs_IDs["date_inizio_quarantena_discarded_IDs"],line.ID) : nothing

    # SE presenta `data_fine_quarantena` E si è assegnata `data_inizio_quarantena_precauzionale`,
    if !is_MVP(line.date_FQ) && !is_MVP(data_inizio_quarantena_precauzionale)
        # ALLORA `data_fine_quarantena_precauzionale = min({data_positività, max({data_inizio_quarantena_precauzionale < data_fine_quarantena_i <= data_positività}) })`
        data_fine_quarantena_precauzionale = check_min(line.data_P, check_maximum([ date for date in line.date_FQ if data_inizio_quarantena_precauzionale < date <= line.data_P ]; MVP = MVP, is_MVP = is_MVP); MVP = MVP, is_MVP = is_MVP)
        data_fine_quarantena_precauzionale ==  line.data_P ? push!(data_quality_IDs_IDs["data_fine_quarantena_precauzionale_imputed"], line.ID) : nothing
    # ALTRIMENTI SE non presenta `data_fine_quarantena` E si è assegnata `data_inizio_quarantena_precauzionale`
    elseif is_MVP(line.date_FQ) && !is_MVP(data_inizio_quarantena_precauzionale)
        # ALLORA `data_fine_quarantena_precauzionale = min({data_positività, data_inizio_quarantena_precauzionale + T_quarantena})`
        data_fine_quarantena_precauzionale = check_min(line.data_P, data_inizio_quarantena_precauzionale + T_quarantena; MVP = MVP, is_MVP = is_MVP)
        push!(data_quality_IDs_IDs["data_fine_quarantena_precauzionale_imputed"], line.ID)
    # ALTRIMENTI SE non presenta `data_fine_quarantena` E non si è assegnata `data_inizio_quarantena_precauzionale`
    elseif is_MVP(line.date_FQ) && is_MVP(data_inizio_quarantena_precauzionale)
        # ALLORA non si assegnerà `data_fine_quarantena_precauzionale`
        data_fine_quarantena_precauzionale = MVP
    end

    # data_inizio_quarantena_ordinaria = data_positività
    data_inizio_quarantena_ordinaria = line.data_P
    push!(data_quality_IDs_IDs["data_inizio_quarantena_ordinaria_imputed"], line.ID)


    # Pre-allocate data_fine_quarantena_ordinaria
    data_fine_quarantena_ordinaria = MVP
    # SE presenta `data_guarigione` (oppure `data_decesso`) allora si procede come segue:
    # ...
    # - SE la `data_guarigione` (oppure `data_decesso`) dista dalla `data_positività` MENO del multiplo di 7 giorni più vicino all'upper whisker della distribuzione di tempo di transizione `P_G` (oppure `P_D`) allora `data_fine_quarantena_ordinaria = data_guarigione` (oppure `data_fine_quarantena_ordinaria = data_decesso`);
    # - ALTRIMENTI SE la `data_guarigione` (oppure `data_decesso`) dista dalla `data_positività` PIU' del multiplo di 7 giorni più vicino all'upper whisker della distribuzione di tempo di transizione`P_G` (oppure `P_D`) E vi è almeno una `data_fine_quarantena` allora `data_fine_quarantena_ordinaria = max(data_positività < data_fine_quarantena_i < data_positività + P_G_upper_whisker)` (oppure `data_fine_quarantena` allora `data_fine_quarantena_ordinaria = max(data_positività < data_fine_quarantena_i < data_positività + P_D_upper_whisker)`);
    # - ALTRIMENTI SE la `data_guarigione` (oppure `data_decesso`) dista dalla `data_positività` PIU' del multiplo di 7 giorni più vicino all'upper whisker della distribuzione di tempo di transizione `P_G` (oppure `P_D`) E NON vi è alcuna una `data_fine_quarantena` allora `data_fine_quarantena_ordinaria = data_positività + P_G_upper_whisker` (oppure `data_fine_quarantena_ordinaria = data_positività + P_D_upper_whisker`).
    if !is_MVP(line.data_G)
        P_G_uw_algorithm_imputed = Dates.Day((Dates.value(P_G_uw) ÷ 7)*7)
        data_fine_quarantena_ordinaria = line.data_G - line.data_P < P_G_uw_algorithm_imputed ? line.data_G : (!is_MVP(line.date_FQ) ? check_maximum([date for date in line.date_FQ if line.data_P < date < line.data_P + P_G_uw_algorithm_imputed  ], MVP = line.data_P + P_G_uw_algorithm_imputed, is_MVP = is_MVP) :  line.data_P + P_G_uw_algorithm_imputed)
        #data_quality["data_fine_quarantena_ordinaria_imputed"] += 1
        push!(data_quality_IDs_IDs["data_fine_quarantena_ordinaria_imputed"], line.ID)
    elseif !is_MVP(line.data_D)
        P_D_uw_algorithm_imputed = Dates.Day((Dates.value(P_D_uw) ÷ 7)*7)
        data_fine_quarantena_ordinaria = line.data_D - line.data_P < P_D_uw_algorithm_imputed ? line.data_D : (!is_MVP(line.date_FQ) ? check_maximum([date for date in line.date_FQ if line.data_P < date < line.data_P + P_D_uw_algorithm_imputed], MVP = line.data_P + P_D_uw_algorithm_imputed, is_MVP = is_MVP ) :  line.data_P + P_D_uw_algorithm_imputed)
        #data_quality["data_fine_quarantena_ordinaria_imputed"] += 1
        push!(data_quality_IDs_IDs["data_fine_quarantena_ordinaria_imputed"], line.ID)
    # ALTRIMENTI SE NON presenta `data_guarigione` (oppure `data_decesso`) allora si procede come segue:
        # - SE vi è almeno una `data_fine_quarantena` ALLORA `data_fine_quarantena_ordinaria = max(data_positività < data_fine_quarantena_i < data_positività + P_G_upper_whisker)`;
        # - ALTRIMENTI SE NON vi è alcuna una `data_fine_quarantena` allora `data_fine_quarantena_ordinaria = data_positività + P_G_upper_whisker`.
    else
        P_G_uw_algorithm_imputed = Dates.Day((Dates.value(P_G_uw) ÷ 7)*7)
        data_fine_quarantena_ordinaria =!is_MVP(line.date_FQ) ? check_maximum([date for date in line.date_FQ if line.data_P < date < line.data_P + P_G_uw_algorithm_imputed], MVP = line.data_P + P_G_uw_algorithm_imputed, is_MVP = is_MVP) :  line.data_P + P_G_uw_algorithm_imputed 
        # data_quality["data_fine_quarantena_ordinaria_imputed"] += data_fine_quarantena_ordinaria == line.data_P + P_G_uw_algorithm_imputed  ? 1 : 0
        data_fine_quarantena_ordinaria == line.data_P + P_G_uw_algorithm_imputed ? push!(data_quality_IDs_IDs["data_fine_quarantena_ordinaria_imputed"], line.ID) : nothing
    end

    # Return dates
    return data_inizio_quarantena_precauzionale, data_fine_quarantena_precauzionale, data_inizio_quarantena_ordinaria, data_fine_quarantena_ordinaria, selected_data_inizio_quarantena
end

"""
    process_quarantene_compact(line_list::DataFrame, events_dates_names::Dict{Symbol,Symbol}, T_quarantena::Day,  P_G_uw::Day, P_D_uw::Day,line_lists_quarantene_columns::Vector{Symbol}; MVP = missing, is_MVP::F = ismissing) where {F <: Function}

Process the quarantine-related component of the integrated individual-level surveillance dataset `line_list` according to the "Quarentene" section in the data model description manual.

# KEY EVENTS
- First day of precautionary quarantine / isolation (IQP: `inizio_quarantena_precauzionale`);
- Last day of precautionary quarantine / isolation (FQP: `fine_quarantena_precauzionale`);
- First day of ordinary quarantine / isolation (IQO: `inizio_quarantena_ordinaria`);
- Last day of ordinary quarantine / isolation (FQO: `fine_quarantena_ordinaria`);
"""
function process_quarantene_compact(line_list_ricoveri::DataFrame, events_dates_names::Dict{Symbol,Symbol}, T_quarantena::Day,  P_G_uw::Day, P_D_uw::Day,line_lists_quarantene_columns::Vector{Symbol}, with_quarantena_precauzionale::Bool; MVP = missing, is_MVP::F = ismissing) where {F <: Function}
    # Deepcopy the input
    line_list_ricoveri_dc = deepcopy(line_list_ricoveri)

    # Create a dictionary for data quality assessment
    assessments_IDs = ("date_inizio_quarantena_discarded_IDs", "data_fine_quarantena_precauzionale_imputed", "data_inizio_quarantena_ordinaria_imputed", "data_fine_quarantena_ordinaria_imputed", "date_fine_quarantena_after_last_dimission_discarded_IDs")
    data_quality_IDs_IDs = Dict{String,Vector{Int64}}(assessment => Int64[] for assessment in assessments_IDs)

    assessments_counts = ("date_inizio_quarantena_discarded", "date_fine_quarantena_after_last_dimission_discarded")
    data_quality_counts = Dict{String,Int64}(assessment => 0 for assessment in assessments_counts)

    # Pre-allocate temporary dataframe that will contain the ID, data_IQP, data_FQP, data_IQO, data_FQO columns
    line_list_quarantene = DataFrame(:ID => Int64[],  events_dates_names[:data_IQP] => Union{typeof(MVP),Date}[], events_dates_names[:data_FQP] => Union{typeof(MVP),Date}[], events_dates_names[:data_IQO] => Union{typeof(MVP),Date}[], events_dates_names[:data_FQO] => Union{typeof(MVP),Date}[])

    # Loop over rows
    for line in eachrow(line_list_ricoveri_dc)
        # Initialize event dates to MVP
        data_inizio_quarantena_precauzionale         = MVP
        data_fine_quarantena_precauzionale           = MVP
        data_inizio_quarantena_ordinaria             = MVP
        data_fine_quarantena_ordinaria               = MVP

        date_ammissione_x                            = MVP 

        # Apply the guidelines prescribed in the manual
        # Se non presenta `data_ammissione_ordinaria` E non presenta `data_ammissione_intensiva`:
        if all(is_MVP.([line.data_AO, line.data_DO, line.data_AI, line.data_DI, line.data_AR, line.data_DR]))
            
            data_inizio_quarantena_precauzionale, data_fine_quarantena_precauzionale, data_inizio_quarantena_ordinaria, data_fine_quarantena_ordinaria,selected_data_inizio_quarantena = date_quarantena_no_ricoveri_compact(line, T_quarantena, P_G_uw, P_D_uw, data_quality_IDs_IDs, data_quality_counts, MVP = MVP, is_MVP = is_MVP)

        # SE presenta `data_ammissione_ordinaria` O presenta `data_ammissione_intensiva`:
        else
            # Evaluate useful quantities
            date_dimissione_x = skipmissing([line.data_DO, line.data_DI, line.data_DR])
            max_data_dimissione_x = maximum(date_dimissione_x)
            date_ammissione_x = skipmissing([line.data_AO, line.data_AI, line.data_AR])

            # Le date di fine quarantena che occorrono dopo `max(data_dimissione_x)` sono da trascurare
            if !is_MVP(line.date_FQ)
                # data_quality["date_fine_quarantena_after_last_dimission_discarded"] += length([date for date in line.date_FQ if date >= max_data_dimissione_x])
                push!(data_quality_IDs_IDs["date_fine_quarantena_after_last_dimission_discarded_IDs"], line.ID )
                data_quality_counts["date_fine_quarantena_after_last_dimission_discarded"] += length([date for date in line.date_FQ if date >= max_data_dimissione_x])

                if line.ID == 63
                    println("ID = $(line.ID), \tline.date_FQ before = $(line.date_FQ)")
                end
                line.date_FQ = [ date for date in line.date_FQ if date < max_data_dimissione_x]

                if line.ID == 63
                    println("ID = $(line.ID), \tline.date_FQ after = $(line.date_FQ)")
                end
            end

            # - `data_inizio_quarantena_precauzionale = max({selected_data_inizio_quarantena_i < data_positività})` ;
            # - `data_fine_quarantena_precauzionale = min( {data_positività, max({ data_inizio_quarantena_precauzionale < data_fine_quarantena_i <= data_positività})})`;

            if line.ID == 63
                println("ID = $(line.ID), \tline before date_quarantena_no_ricoveri_compact = $(line)")
            end

            data_inizio_quarantena_precauzionale, data_fine_quarantena_precauzionale, data_inizio_quarantena_ordinaria, data_fine_quarantena_ordinaria, selected_data_inizio_quarantena  = date_quarantena_no_ricoveri_compact(line, T_quarantena, P_G_uw, P_D_uw, data_quality_IDs_IDs, data_quality_counts, MVP = MVP, is_MVP = is_MVP)

            if line.ID == 63
                println("ID = $(line.ID), \tdata_fine_quarantena_ordinaria after date_quarantena_no_ricoveri_compact = $(data_fine_quarantena_ordinaria)")
                # println("ID = $(line.ID), \t!is_MVP(line.date_FQ) = $(!is_MVP(line.date_FQ)) \t length(line.date_FQ) > 0 = $(length(line.date_FQ) > 0) \t maximum(line.date_FQ) > max_data_dimissione_x = $( maximum(line.date_FQ) > max_data_dimissione_x) \t length(line.date_FQ) > 0 = $( length(line.date_FQ) > 0) \t maximum(line.date_FQ) > max_data_dimissione_x = $(maximum(line.date_FQ) > max_data_dimissione_x)")
            end
            
#=             # SE presenta `data_fine_quarantena` E max({data_fine_quarantena_i}) <= max({data_dimissione_x_i})
            if !is_MVP(data_fine_quarantena_ordinaria) && data_fine_quarantena_ordinaria <= max_data_dimissione_x   #!is_MVP(line.date_FQ) && length(line.date_FQ) > 0 && maximum(line.date_FQ) <= max_data_dimissione_x =#
                # SE data_positività = min({data_ammissione_x_i})
            if line.data_P == minimum(date_ammissione_x)
                # ALLORA non si assegneranno le date di quarantena_ordinaria
                data_inizio_quarantena_ordinaria     = MVP
                data_fine_quarantena_ordinaria       = MVP
                # data_inizio_quarantena_ordinaria and data_fine_quarantena_ordinaria are otherwise always imputed (see function `date_quarantena_no_ricoveri_compact` )
                deleteat!(data_quality_IDs_IDs["data_inizio_quarantena_ordinaria_imputed"], findall(x->x==line.ID, data_quality_IDs_IDs["data_inizio_quarantena_ordinaria_imputed"]) )
                deleteat!(data_quality_IDs_IDs["data_fine_quarantena_ordinaria_imputed"], findall(x->x==line.ID, data_quality_IDs_IDs["data_fine_quarantena_ordinaria_imputed"]) ) 
                # SE min({data_ammissione_x_i}) > data_positività
            elseif minimum(date_ammissione_x) > line.data_P
                # data_inizio_quarantena_ordinaria = data_positività
                data_inizio_quarantena_ordinaria = line.data_P
                # data_fine_quarantena_ordinaria = min({date_ammissione_x_i})
                data_fine_quarantena_ordinaria = minimum(date_ammissione_x) # We don't increment data_quality["data_fine_quarantena_ordinaria_imputed"] since data_fine_quarantena_ordinaria has already been imputed once in function date_quarantena_no_ricoveri_compact
                # Non consideriamo il caso in cui data_positività > min({data_ammissione_x_i}) in quanto questa eventualità è esclusa dal punto [2.1](#2.1-Ricoveri-pre-tempone-positivo).
            end
#=             # ALTRIMENTI SE presenta `data_fine_quarantena` E max({data_fine_quarantena_i}) > max({data_dimissione_x_i})
            elseif !is_MVP(data_fine_quarantena_ordinaria) && data_fine_quarantena_ordinaria > max_data_dimissione_x #!is_MVP(line.date_FQ) && length(line.date_FQ) > 0 && maximum(line.date_FQ) > max_data_dimissione_x
                # SE min({data_ammissione_x_i}) =  data_positività
                if line.data_P == minimum(date_ammissione_x)
                    # ALLORA non si assegneranno le date di quarantena_ordinaria
                    data_inizio_quarantena_ordinaria     = MVP
                    data_fine_quarantena_ordinaria       = MVP
                    # data_inizio_quarantena_ordinaria and data_fine_quarantena_ordinaria are otherwise always imputed (see function `date_quarantena_no_ricoveri_compact` )
                    deleteat!(data_quality_IDs_IDs["data_inizio_quarantena_ordinaria_imputed"], findall(x->x==line.ID, data_quality_IDs_IDs["data_inizio_quarantena_ordinaria_imputed"]) )
                    deleteat!(data_quality_IDs_IDs["data_fine_quarantena_ordinaria_imputed"], findall(x->x==line.ID, data_quality_IDs_IDs["data_fine_quarantena_ordinaria_imputed"]) ) 
                # ALTRIMENTI SE min({data_ammissione_x_i}) > data_positività ***
                elseif minimum(date_ammissione_x) > line.data_P
                    # data_inizio_quarantena_ordinaria = data_positività
                    data_inizio_quarantena_ordinaria = line.data_P
                    # data_fine_quarantena_ordinaria = min({date_ammissione_x}) ***
                    data_fine_quarantena_ordinaria = minimum(date_ammissione_x) #max(line.date_FQ)  # We don't increment data_quality["data_fine_quarantena_ordinaria_imputed"] since data_fine_quarantena_ordinaria has already been imputed once in function date_quarantena_no_ricoveri_compact
                # Non consideriamo il caso in cui `data_positività > min({data_ammissione_x_i})` in quanto questa eventualità è esclusa dal punto [2.1](#2.1-Ricoveri-pre-tempone-positivo).
                end
            # SE non presenta data_fine_quarantena 
            elseif is_MVP(line.date_FQ)
                # SE min({data_ammissione_x_i}) = data_positività
                if line.data_P == minimum(date_ammissione_x)
                    # ALLORA non si assegneranno le date di quarantena_ordinaria
                    data_inizio_quarantena_ordinaria     = MVP
                    data_fine_quarantena_ordinaria       = MVP
                    # data_inizio_quarantena_ordinaria and data_fine_quarantena_ordinaria are otherwise always imputed (see function `date_quarantena_no_ricoveri_compact` )
                    deleteat!(data_quality_IDs_IDs["data_inizio_quarantena_ordinaria_imputed"], findall(x->x==line.ID, data_quality_IDs_IDs["data_inizio_quarantena_ordinaria_imputed"]) )
                    deleteat!(data_quality_IDs_IDs["data_fine_quarantena_ordinaria_imputed"], findall(x->x==line.ID, data_quality_IDs_IDs["data_fine_quarantena_ordinaria_imputed"]) ) 
                # ALTRIMENTI SE min({data_ammissione_x_i}) > data_positività
                elseif minimum(date_ammissione_x) > line.data_P 
                    # data_inizio_quarantena_ordinaria = data_positività
                    data_inizio_quarantena_ordinaria = line.data_P
                    # data_fine_quarantena_ordinaria = min({data_fine_quarantena_i})
                    data_fine_quarantena_ordinaria = minimum(date_ammissione_x) # We don't increment data_quality["data_fine_quarantena_ordinaria_imputed"] since data_fine_quarantena_ordinaria has already been imputed once in function date_quarantena_no_ricoveri_compact
                # Non consideriamo il caso in cui `data_positività > min({data_ammissione_x_i})` in quanto questa eventualità è esclusa dal punto [2.1](#2.1-Ricoveri-pre-tempone-positivo).
                end
            end =#
        end
        if line.ID == 63
            println("ID = $(line.ID), \tdata_fine_quarantena_ordinaria before pushing = $(data_fine_quarantena_ordinaria)")
        end

        if !with_quarantena_precauzionale
            data_inizio_quarantena_precauzionale = MVP
            data_fine_quarantena_precauzionale = MVP
        end


        push!(line_list_quarantene, (line.ID, data_inizio_quarantena_precauzionale, data_fine_quarantena_precauzionale, data_inizio_quarantena_ordinaria,data_fine_quarantena_ordinaria))
    end

    # Check that the IDs in the line_list_quarantene dataframe are the same as the IDs in the line_list dataframe, and that the output we'd get from joining the two is symmetric (this is a redundant check)
    @assert isequal(leftjoin(line_list_ricoveri_dc, line_list_quarantene, on = [:ID]), rightjoin(line_list_ricoveri_dc, line_list_quarantene, on = [:ID]))

    data_quality_IDs = merge(data_quality_IDs_IDs, data_quality_counts)
    data_quality = merge(data_quality_counts, Dict(assessment => length(IDs) for (assessment, IDs) in collect(data_quality_IDs_IDs)))

    # Return dataframes with data_IQP, data_FQP, data_IQO, data_FQO, and remove date_IQ and date_FQ
    return select(leftjoin(line_list_ricoveri_dc, line_list_quarantene, on = [:ID]), line_lists_quarantene_columns),data_quality_IDs, data_quality
end

#### FINE PERCORSO ####

"""
    process_date_FP(line_list_ricoveri_quarantene::DataFrame; MVP, is_MVP::F) where {F <: Function}

Process the integrated individual-level surveillance dataset `line_list_ricoveri_quarantene` according to the data model description manual to assign the end date of the clinical pathway.

# KEY EVENTS
- Recovery (G: `guarigione`);
- Death (D: `decesso`).
"""
function process_date_FP(line_list_ricoveri_quarantene::DataFrame; MVP, is_MVP::F) where {F <: Function}
    # Deepcopy source dataset
    line_list_ricoveri_quarantene_dc = deepcopy(line_list_ricoveri_quarantene)

    # Create a dictionary for data quality assessment
    assessments_IDs = ("data_G_moved_to_data_FQO", "data_D_moved_to_data_FQO", "data_G_imputed_to_data_FQO", "data_G_moved_to_max_data_dimissione", "data_D_moved_to_max_data_dimissione", "data_G_imputed_to_max_data_dimissisone")
    data_quality_IDs_IDs = Dict{String,Vector{Int64}}(assessment => Int64[] for assessment in assessments_IDs)

    assessments_counts = ()
    data_quality_counts = Dict{String,Int64}(assessment => 0 for assessment in assessments_counts)

    # Loop over rows
    for line in eachrow(line_list_ricoveri_quarantene_dc)
        # SE NON presenta alcuna `data_ammissione_x` allora si procede come segue:
        if all(is_MVP.([line.data_AO, line.data_DO, line.data_AI, line.data_DI, line.data_AR, line.data_DR]))
            # SE presenta `data_guarigione` (oppure `data_decesso`) E `data_guarigione > data_fine_quarantena_ordinaria` (oppure `data_decesso > data_fine_quarantena_ordinaria`) ALLORA si correggerà `data_guarigione = data_fine_quarantena_ordinaria` (oppure `data_decesso = data_fine_quarantena_ordinaria`)
            if !is_MVP(line.data_G) && line.data_G > line.data_FQO
                line.data_G = line.data_FQO
                push!(data_quality_IDs_IDs["data_G_moved_to_data_FQO"], line.ID)
            elseif !is_MVP(line.data_D) && line.data_D > line.data_FQO
                line.data_D = line.data_FQO
                push!(data_quality_IDs_IDs["data_D_moved_to_data_FQO"], line.ID)
            # ALTRIMENTI SE NON presenta `data_guarigione` nè `data_decesso`, ALLORA si porrà `data_guarigione = data_fine_quarantena_ordinaria`
            elseif is_MVP(line.data_G) && is_MVP(line.data_D)
                line.data_G = line.data_FQO
                push!(data_quality_IDs_IDs["data_G_imputed_to_data_FQO"], line.ID)
            end
        # ALTRIMENTI SE presenta almeno una `data_ammissione_x`, si procede come segue:
        else
            max_data_dimissione_x = check_max(line.data_DO, line.data_DI, line.data_DR; MVP = MVP, is_MVP = is_MVP)

            # SE presenta `data_guarigione` (oppure `data_decesso`) E `data_guarigione != max({data_dimissione_x_i})` (oppure `data_decesso != max({data_dimissione_x_i})`) ALLORA si correggerà `data_guarigione = max({data_dimissione_x_i})` (oppure `data_decesso  = max({data_dimissione_x_i})`)
            if !is_MVP(line.data_G) && line.data_G != max_data_dimissione_x
                line.data_G = max_data_dimissione_x
                push!(data_quality_IDs_IDs["data_G_moved_to_max_data_dimissione"], line.ID)
            elseif !is_MVP(line.data_D) && line.data_D != max_data_dimissione_x
                line.data_D = max_data_dimissione_x
                push!(data_quality_IDs_IDs["data_D_moved_to_max_data_dimissione"], line.ID)
            # ALTRIMENTI SE NON presenta `data_guarigione` nè `data_decesso`, ALLORA si porrà `data_guarigione = max({data_dimissione_x_i})`
            elseif is_MVP(line.data_G) && is_MVP(line.data_D)
                line.data_G = max_data_dimissione_x
                push!(data_quality_IDs_IDs["data_G_imputed_to_max_data_dimissisone"], line.ID)
            end

        end
    end
    
    data_quality_IDs = merge(data_quality_IDs_IDs, data_quality_counts)
    data_quality     =  merge(data_quality_counts, Dict(assessment => length(IDs) for (assessment, IDs) in collect(data_quality_IDs_IDs)))

    # Return processed DataFrame
    return line_list_ricoveri_quarantene_dc, data_quality_IDs_IDs, data_quality
end

#### INIZO SINTOMI ####

"""
    process_inizi_sintomi(line_list_ricoveri_quarantene_fp::DataFrame; MVP, is_MVP::F) where {F <: Function}

Process the symptoms-related component of the integrated individual-level surveillance dataset `line_list_ricoveri_quarantene_fp` according to the data model description manual.

# KEY EVENTS
- Symptoms onset (IS: `inizio_sintomi`); 
"""
function process_inizi_sintomi(line_list_ricoveri_quarantene_fp::DataFrame; MVP, is_MVP::F) where {F <: Function}
    # Deepcopy the input 
    line_list_ricoveri_quarantene_fp_dc = deepcopy(line_list_ricoveri_quarantene_fp)

    # Create a dictionary for data quality assessment
    assessments_IDs = ("inizi_sintomi_after_data_FP", "inizi_sintomi_after_min_data_ammissione_x")
    data_quality_IDs_IDs = Dict{String,Vector{Int64}}(assessment => Int64[] for assessment in assessments_IDs)

    assessments_counts = ()
    data_quality_counts = Dict{String,Int64}(assessment => 0 for assessment in assessments_counts)

    # Trascurare inizi sintomi post guarigione.
    for line in eachrow(line_list_ricoveri_quarantene_fp_dc)
        data_FP = !is_MVP(line.data_G) ? line.data_G : line.data_D
        if !is_MVP(line.data_IS) && !is_MVP(data_FP) && line.data_IS > data_FP
            line.data_IS = MVP
            push!(data_quality_IDs_IDs["inizi_sintomi_after_data_FP"], line.ID )
        end
    end

    # Trascurare inizi sintomi post ospedalizzazione (ordinaria e/o intensiva)
    for line in eachrow(line_list_ricoveri_quarantene_fp_dc)
        min_data_ammissione_x = check_min(line.data_AO, line.data_AO; MVP = MVP, is_MVP = is_MVP)
        if !is_MVP(line.data_IS) && !is_MVP(min_data_ammissione_x) && line.data_IS > min_data_ammissione_x
            line.data_IS = MVP
            push!(data_quality_IDs_IDs["inizi_sintomi_after_min_data_ammissione_x"], line.ID )
        end
    end

    data_quality_IDs = merge(data_quality_IDs_IDs, data_quality_counts)
    data_quality     =  merge(data_quality_counts, Dict(assessment => length(IDs) for (assessment, IDs) in collect(data_quality_IDs_IDs)))

    return line_list_ricoveri_quarantene_fp_dc, data_quality_IDs, data_quality
end

#### DATE LIMIT ####
"""
    delete_lines_exceeding_date(line_list_ricoveri_quarantene_fp_is::DataFrame, limit_date::Date)

Returns a DataFrame whose rows are the only rows in `line_list_ricoveri_quarantene_fp_is` whose maximum element of type `Date` is less than `limit_date`.
"""
delete_lines_exceeding_date(line_list_ricoveri_quarantene_fp_is::DataFrame, limit_date::Date) = filter(line -> maximum([date for date in line if typeof(date) == Date]) <= limit_date ,  line_list_ricoveri_quarantene_fp_is)