function date_quarantena_no_ricoveri_extended(line::DataFrameRow{DataFrame, DataFrames.Index}, T_quarantena::Day; MVP = missing, is_MVP::F = ismissing) where {F <: Function}

    data_inizio_quarantena_precauzionale = MVP
    data_fine_quarantena_precauzionale   = MVP
    data_inizio_quarantena_ordinaria     = MVP
    data_fine_quarantena_ordinaria       = MVP

    # SE non esiste alcuna data_inizio_quarantena IN {data_inizio_quarantena_i} 
    if is_MVP(line.date_IQ)
        # ALLORA si assegnerà si assegnerà data_inizio_quarantena_ordinaria = data_positività
        data_inizio_quarantena_ordinaria = line.data_P
        # E si procede come segue: 
        # SE non esiste alcuna data_fine_quarantena IN {data_positività < data_fine_quarantena_i} ALLORA si procede come segue: 
            # SE presenta data_guarigione e questa è avvenuta entro 60gg dalla positività, ALLORA data_fine_quarantena_ordinaria = data_guarigione
            # ALTRIMENTI SE non presenta data_guarigione O questa è avvenuta oltre 60gg dalla positività E vi è almeno una data_fine_qurantena in {data_fine_quarantena_i > data_positività}, ALLORA data_fine_quarantena_ordinaria = max({data_positività + T_quarantena ,{data_fine_quarantena_i > data_positività}})
            # ALTRIMENTI SE non presenta data_guarigione O questa è avvenuta oltre 60gg dalla positività E non vi è alcuna data_fine_qurantena in {data_fine_quarantena_i > data_positività}, ALLORA data_fine_quarantena_ordinaria = data_positività + T_quarantena**
        data_fine_quarantena_ordinaria = !is_MVP(line.data_G) && line.data_G-line.data_P < Dates.Day(60) ? line.data_G : (!is_MVP(line.date_FQ) ? check_maximum([date for date in line.date_FQ if line.data_P < date], MVP = line.data_P + T_quarantena) :  line.data_P + T_quarantena) # check_min(line.data_G, line.data_P + T_quarantena; MVP = MVP, is_MVP = is_MVP)

        # ALTRIMENTI SE esiste almeno una data_fine_quarantena IN {data_positività < data_fine_quarantena_i}
        # else
            #  ALLORA si assegnerà data_fine_quarantena_ordinaria = max({data_positività < data_fine_quarantena_i})
            # data_fine_quarantena_ordinaria = maximum([date for date in line.date_FQ if line.data_P < date])
        # end
    # ALTRIMENTI SE esiste almeno una data_inizio_quarantena IN {data_inizio_quarantena_i}
    else
    # si procede come segue: 
        # SE non esiste alcuna data_fine_quarantena IN {data_fine_quarantena_i}
        if is_MVP(line.date_FQ)
            # ALLORA si assegnerà data_inizio_quarantena_ordinaria = data_positività 
            data_inizio_quarantena_ordinaria = line.data_P
            # E si procede come segue
            # SE presenta data_guarigione E questa è avvenuta entro 60 giorni dalla data_positività, ALLORA data_fine_quarantena_ordinaria = data_guarigione;
            # ALTRIMENTI SE non presenta data_guarigione O questa non è avvenuta entro 60 giorni dalla data_positività, ALLORA data_fine_quarantena_ordinaria = data_positività + T_quarantena . **
            data_fine_quarantena_ordinaria = !is_MVP(line.data_G) && line.data_G-line.data_P < Dates.Day(60) ? line.data_G : line.data_P + T_quarantena # line.data_P + T_quarantena
            # E si procede come segue: 
            # SE min({data_inizio_quarantena_i}) < data_positività
            if minimum(line.date_IQ) < line.data_P
            # si procede come segue: 
                # SE max({data_inizio_quarantena_i < data_positività}) < min({data_inizio_quarantena_i}) + T_quarantena
                if maximum([date for date in line.date_IQ if date < line.data_P]) < (minimum(line.date_IQ) + T_quarantena)
                    # ALLORA si assegnerà data_inizio_quarantena_precauzionale = max({data_inizio_quarantena_i < data_positività})***
                    data_inizio_quarantena_precauzionale = maximum([ date for date in line.date_IQ if date < line.data_P])#minimum(line.date_IQ)
                    # E data_fine_quarantena_precauzionale = min({data_positività, data_inizio_quarantena_precauzionale + T_quarantena})
                    data_fine_quarantena_precauzionale = min(line.data_P,data_inizio_quarantena_precauzionale + T_quarantena)
                # ALTRIMENTI SE max({data_inizio_quarantene_i < data_positività}) >= min({data_inizio_quarantena_i}) + T_quarantena
                elseif maximum([ date for date in line.date_IQ if date < line.data_P]) >= minimum(line.date_IQ) + T_quarantena
                    # ALLORA si assegnerà data_inizio_quarantena_precauzionale = max({data_inizio_quarantene_i < data_positività}) 
                    data_inizio_quarantena_precauzionale = maximum([ date for date in line.date_IQ if date < line.data_P ])
                    # E si procede come segue: 
                    # SE data_inizio_quarantena_precauzionale + T_quarantena < data_positività
                    if (data_inizio_quarantena_precauzionale + T_quarantena) < line.data_P
                        #  ALLORA si assegnerà data_fine_quarantena_precauzionale = data_inizio_quarantena_precauzionale + T_quarantena
                        data_fine_quarantena_precauzionale = data_inizio_quarantena_precauzionale + T_quarantena
                    # ALTRIMENTI SE data_inizio_quarantena_precauzionale + T_quarantena >= data_positività #  min({data_inizio_quarantena_i}) >= data_positività
                    else
                        # ALLORA si assegnerà `data_fine_quarantena_precauzionale = data_positività`
                        data_fine_quarantena_precauzionale = line.data_P
                        # # ALLORA si assegnerà data_inizio_quarantena_ordinaria = data_positività
                        # data_inizio_quarantena_ordinaria = line.data_P
                        # # E data_fine_quarantena_ordinaria = data_positività + T_quarantena
                        # data_fine_quarantena_ordinaria = line.data_P + T_quarantena

                    end
                

                end
            # ALTRIMENTI SE  min({data_inizio_quarantena_i}) >= data_positività
            else
                # ALLORA si assegnerà data_inizio_quarantena_ordinaria = data_positività
                data_inizio_quarantena_ordinaria = line.data_P
                # E si procede come segue:
                # SE presenta data_guarigione E questa è avvenuta entro 60 giorni dalla data_positività, ALLORA data_fine_quarantena_ordinaria = data_guarigione;
                # ALTRIMENTI SE non presenta data_guarigione O questa non è avvenuta entro 60 giorni dalla data_positività, ALLORA data_fine_quarantena_ordinaria = data_positività + T_quarantena .**
                data_fine_quarantena_ordinaria = !is_MVP(line.data_G) && line.data_G-line.data_P < Dates.Day(60) ? line.data_G : line.data_P + T_quarantena #line.data_P + T_quarantena
            end
        # ALTRIMENTI SE esiste almeno una data_fine_quarantena IN {data_fine_quarantena_i}
        else
            # si procede come segue:
            # SE max({data_fine_quarantena_i}) <= data_positività
            if maximum(line.date_FQ) <= line.data_P
                # ALLORA si assegnerà data_inizio_quarantena_ordinaria = data_positività
                data_inizio_quarantena_ordinaria = line.data_P
                # E si procede come segue:
                # SE presenta  data_guarigione è avvenuta entro 60 giorni dalla data_positività, ALLORA data_fine_quarantena_ordinaria = data_guarigione;
                # ALTRIMENTI SE non presenta data_guarigione O questa non è avvenuta entro 60 giorni dalla data_positività, ALLORA data_fine_quarantena_ordinaria = data_positività + T_quarantena .**
                data_fine_quarantena_ordinaria = !is_MVP(line.data_G) && line.data_G-line.data_P < Dates.Day(60) ? line.data_G : line.data_P + T_quarantena # check_min(line.data_G, line.data_P + T_quarantena; MVP = MVP, is_MVP = is_MVP)
                # E si procede come segue:
                if maximum([date for date in line.date_IQ if date < line.data_P]) > maximum(line.date_FQ)
                    data_inizio_quarantena_precauzionale = maximum([date for date in line.date_IQ if date < line.data_P])
                    data_fine_quarantena_precauzionale = line.data_P
                elseif maximum([date for date in line.date_IQ if date < line.data_P]) < maximum(line.date_FQ)
                    data_inizio_quarantena_precauzionale = maximum([date for date in line.date_IQ if date < line.data_P])
                    data_fine_quarantena_precauzionale = maximum(line.date_FQ)
                elseif maximum([date for date in line.date_IQ if date < line.data_P]) == maximum(line.date_FQ)
                    error("An element of date_IQ coincides with an element of date_IQ for ID = ", line.ID)
                end


                # # SE esiste almeno una data_inizio_quarantena IN {max({data_fine_quarantena_i}) - T_quarantena <= data_inizio_quarantena_i < max({data_fine_quarantena_i})}
                # if !isempty([date for date in line.date_IQ if (maximum(line.date_FQ) - T_quarantena) <= date < maximum(line.date_FQ) ])
                #     # ALLORA si assegnerà data_fine_quarantena_precauzionale = max({data_fine_quarantena_i})
                #     data_fine_quarantena_precauzionale = maximum(line.date_FQ)
                #     # E data_inizio_quarantena_precauzionale =  min({max({data_fine_quarantena_i}) - T_quarantena <= data_inizio_quarantena_i < max({data_fine_quarantena_i})})
                #     data_inizio_quarantena_precauzionale = minimum([date for date in line.date_IQ if (maximum(line.date_FQ) - T_quarantena) <= date < maximum(line.date_FQ) ])
                # # ALTRIMENTI SE non esiste alcuna data_inizio_quarantena IN {max({data_fine_quarantena_i}) - T_quarantena <= data_inizio_quarantena_i < max({data_fine_quarantena_i})}
                # else
                #     # ALLORA non si assegneranno le date di quarantena_precauzionale
                #     data_inizio_quarantena_precauzionale = MVP
                #     data_fine_quarantena_precauzionale   = MVP
                # end

            # ALTRIMENTI SE max({data_fine_quarantena_i}) > data_positività
            else
                println("extended. ID = ", line.ID, " line.data_P = ", line.data_P, " maximum(line.date_FQ) = ", maximum(line.date_FQ) )
                # ALLORA si assegnerà data_inizio_quarantena_ordinaria = data_positività
                data_inizio_quarantena_ordinaria = line.data_P
                # E si procede come segue:
                    # SE presenta data_guarigione E questa è avvenuta entro 60 giorni dalla data_positività, ALLORA data_fine_quarantena_ordinaria = data_guarigione
                    # ALTRIMENTI SE non presenta data_guarigione O questa non è avvenuta entro 60 giorni dalla data_positività E vi è almeno una data_fine_qurantena in {data_fine_quarantena_i > data_positività}, ALLORA data_fine_quarantena_ordinaria = max({data_positività + T_quarantena ,{data_fine_quarantena_i > data_positività}})
                    # ALTRIMENTI SE non presenta data_guarigione O questa non è avvenuta entro 60 giorni dalla data_positività E non vi è alcuna data_fine_qurantena in {data_fine_quarantena_i > data_positività}, ALLORA data_fine_quarantena_ordinaria = data_positività + T_quarantena **
                data_fine_quarantena_ordinaria = !is_MVP(line.data_G) && line.data_G-line.data_P < Dates.Day(60) ? line.data_G : (!is_MVP(line.date_FQ) ? check_maximum([date for date in line.date_FQ if line.data_P < date], MVP = line.data_P + T_quarantena) :  line.data_P + T_quarantena) 
                # E si procede come segue:
                # SE non esiste alcuna data_fine_quarantena IN  {data_fine_quarantena_i < data_positività}
                if !any(line.date_FQ .< line.data_P)
                    # ALLORA si procede come segue: 
                    # SE min({data_inizio_quarantena_i}) < data_positività  
                    if minimum(line.date_IQ) < line.data_P
                        # si procede come segue: 
                        # SE max({data_inizio_quarantena_i < data_positività}) < min({data_inizio_quarantena_i}) + T_quarantena
                        if maximum([date for date in line.date_IQ if date < line.data_P]) < (minimum(line.date_IQ) + T_quarantena)
                            # ALLORA si assegnerà data_inizio_quarantena_precauzionale = max({data_inizio_quarantena_i})***
                            data_inizio_quarantena_precauzionale = maximum(line.date_IQ) # minimum(line.date_IQ)
                            # E data_fine_quarantena_precauzionale = min({data_positività, data_inizio_quarantena_precauzionale + T_quarantena}) ***
                            data_fine_quarantena_precauzionale = check_min(line.data_P, data_inizio_quarantena_precauzionale + T_quarantena; MVP = MVP, is_MVP = is_MVP)
                        # ALTRIMENTI SE max({data_inizio_quarantene_i < data_positività}) >= min({data_inizio_quarantena_i}) + T_quarantena
                        else
                            # ALLORA si assegnerà data_inizio_quarantena_precauzionale = max({data_inizio_quarantene_i < data_positività})
                            data_inizio_quarantena_precauzionale = maximum([date for date in line.date_IQ if date < data_positività])
                            # E si procede come segue: 
                            # SE data_inizio_quarantena_precauzionale + T_quarantena < data_positività
                            if (data_inizio_quarantena_precauzionale + T_quarantena) < line.data_P
                                # ALLORA si assegnerà data_fine_quarantena_precauzionale = data_inizio_quarantena_precauzionale + T_quarantena
                                data_fine_quarantena_precauzionale = data_inizio_quarantena_precauzionale + T_quarantena
                            # ALTRIMENTI SE data_inizio_quarantena_precauzionale + T_quarantena >= data_positività
                            else
                                # ALLORA si assegnerà data_fine_quarantena_precauzionale = data_positività
                                data_fine_quarantena_precauzionale = line.data_P
                            end
                        end
                    # ALTRIMENTI SE min({data_inizio_quarantena_i}) >= data_positività
                    else
                        # ALLORA non si assegneranno le date di quarantena_precauzionale
                        data_inizio_quarantena_precauzionale = MVP
                        data_fine_quarantena_precauzionale   = MVP
                    end
                # ALTRIMENTI SE esiste almeno una data_fine_quarantena IN  {data_fine_quarantena_i < data_positività}
                else
                    # ALLORA si procede come segue: 
                    # SE esiste almeno una data_inizio_quarantena IN {max({data_fine_quarantena_i < data_positività}) - T_quarantena <= data_inizio_quarantena_i < max({data_fine_quarantena_i < data_positività})}
                    if any((maximum([ date for date in line.date_FQ if date < line.data_P]) - T_quarantena).<line.date_IQ.<maximum([date for date in line.date_FQ if date<line.data_P]))
                        # ALLORA si assegnerà data_fine_quarantena_precauzionale = max({data_fine_quarantena_i < data_positività})
                        data_fine_quarantena_precauzionale = maximum([date for date in line.date_FQ if date < line.data_P])
                        # E data_inizio_quarantena_precauzionale =  min({max({data_fine_quarantena_i < data_positività}) - T_quarantena <= data_inizio_quarantena_i < max({data_fine_quarantena_i < data_positività})}) ***
                        data_inizio_quarantena_precauzionale = maximum(line.date_IQ[(maximum([ date for date in line.date_FQ if date < line.data_P]) - T_quarantena).<line.date_IQ.<maximum([date for date in line.date_FQ if date<line.data_P])]) # minimum
                    # ALTRIMENTI SE esiste almeno una data_inizio_quarantena IN {max({data_fine_quarantena_i < data_positività}) - T_quarantena <= data_inizio_quarantena_i < data_positività}
                    elseif any(maximum([date for date in line.date_FQ if date<line.data_P]) .< line.date_IQ .< line.data_P)
                        data_inizio_quarantena_precauzionale = maximum([date for date in line.date_IQ if date < line.data_P])

                        data_fine_quarantena_precauzionale = min(data_inizio_quarantena_precauzionale+T_quarantena, line.data_P)
                    # ALTRIMENTI SE non esiste alcuna data_inizio_quarantena IN {max({data_fine_quarantena_i}) - T_quarantena <= data_inizio_quarantena_i < max({data_fine_quarantena_i})}
                    else
                        # ALLORA non si assegneranno le date di quarantena_precauzionale
                        data_inizio_quarantena_precauzionale = MVP
                        data_fine_quarantena_precauzionale   = MVP
                    end
                end       

            end
        end
    end

    return data_inizio_quarantena_precauzionale, data_fine_quarantena_precauzionale, data_inizio_quarantena_ordinaria, data_fine_quarantena_ordinaria, MVP, MVP


end

function process_quarantene_extended(line_list::DataFrame, events_dates_names::Dict{Symbol,Symbol}, T_quarantena::Day, line_lists_quarantene_columns::Vector{Symbol}; MVP = missing, is_MVP::F = ismissing) where {F <: Function}

    # Deepcopy the line list
    line_list_dc = deepcopy(line_list)

    # Preallocate temporary dataframe that will contain the ID, data_IQP, data_FQP, data_IQO, data_FQO columns
    line_list_quarantene = DataFrame(:ID => Int64[], events_dates_names[:data_IQP] => Union{typeof(MVP),Date}[], events_dates_names[:data_FQP] => Union{typeof(MVP),Date}[], events_dates_names[:data_IQO] => Union{typeof(MVP),Date}[], events_dates_names[:data_FQO] => Union{typeof(MVP),Date}[], events_dates_names[:data_IQPO] => Union{typeof(MVP),Date}[], events_dates_names[:data_FQPO] => Union{typeof(MVP),Date}[])

    # Set threashold for delays between data_gaurgione and the last but one date ***
    T_max_G = Dates.Day(30)


    # Loop over rows
    for line in eachrow(line_list_dc)

        data_inizio_quarantena_precauzionale         = MVP
        data_fine_quarantena_precauzionale           = MVP
        data_inizio_quarantena_ordinaria             = MVP
        data_fine_quarantena_ordinaria               = MVP
        data_inizio_quarantena_post_ospedalizzazione = MVP
        data_fine_quarantena_post_ospedalizzazione   = MVP
        date_ammissione_x                            = MVP

        # Per ciò che concerne tutti i pazienti che possiedono `data_ammissione_x` (con `x = ordinaria`  o  `x = intensiva`) precente alla `data_positività` si dovrà procedere impostando `data_positività = data_ammissione_x` .
        if !is_MVP(line.ricoveri)
            date_ammissione_x = collect(Iterators.flatten(vcat([ricovero.date_AO for ricovero in line.ricoveri],[ricovero.date_AI for ricovero in line.ricoveri])))
            if minimum(date_ammissione_x) < line.data_P
                line.data_P = minimum(date_ammissione_x)
            end
        end
            
        # Per ciascun paziente NON ospedalizzato si procede come segue...
        if is_MVP(line.ricoveri) 

            # ***
            dates_before_recovery = remove_MVP_splat([line.data_P], line.date_IQ,line.date_FQ; is_MVP = is_MVP)
            max_date = check_maximum(collect(Iterators.flatten(vcat(dates_before_recovery))); MVP = MVP, is_MVP = is_MVP)+ Dates.Day(T_max_G)
            if !is_MVP(line.data_G) && line.data_G > max_date
                line.data_G = max_date
            end

            data_inizio_quarantena_precauzionale, data_fine_quarantena_precauzionale, data_inizio_quarantena_ordinaria, data_fine_quarantena_ordinaria, data_inizio_quarantena_post_ospedalizzazione, data_fine_quarantena_post_ospedalizzazione  = date_quarantena_no_ricoveri_extended(line, T_quarantena, MVP = MVP, is_MVP = is_MVP)
                        
        else
            # ***
            # date_dimissione_x = vcat([ricovero.date_DO for ricovero in line.ricoveri]...,[ricovero.date_DI for ricovero in line.ricoveri]...)
            # max_data_dimissione_x = maximum(collect(Iterators.flatten(date_dimissione_x)))
            # dates_before_recovery = remove_MVP_splat([line.data_P], line.date_IQ,line.date_FQ, date_dimissione_x ; is_MVP = is_MVP)
            # max_date = check_maximum(collect(Iterators.flatten(vcat(dates_before_recovery))); MVP = MVP, is_MVP = is_MVP) + Dates.Day(T_quarantena)
            date_dimissione_x = vcat([ricovero.date_DO for ricovero in line.ricoveri]...,[ricovero.date_DI for ricovero in line.ricoveri]...)
            max_data_dimissione_x = maximum(collect(Iterators.flatten(date_dimissione_x)))
            dates_before_recovery = vcat(remove_MVP_splat(line.date_IQ,line.date_FQ ; is_MVP = is_MVP)...)
            #println("dates_before_recovery = $dates_before_recovery \n", "vcat(line.data_P, dates_before_recovery, max_data_dimissione_x ) = ", vcat(line.data_P, dates_before_recovery, max_data_dimissione_x ))
            max_date = check_maximum(vcat(line.data_P, dates_before_recovery, max_data_dimissione_x ); MVP = MVP, is_MVP = is_MVP) + Dates.Day(T_max_G)
            println("max_date = $max_date")
            if !is_MVP(line.data_G) && line.data_G > max_date
                line.data_G = max_date
            end
            # Per ciascun paziente ospedalizzato si assegnano data_inizio_quarantena_precauzionale e data_fine_quarantena_precauzionale come riportato al punto 2.
            data_inizio_quarantena_precauzionale, data_fine_quarantena_precauzionale, data_inizio_quarantena_ordinaria, data_fine_quarantena_ordinaria, data_inizio_quarantena_post_ospedalizzazione, data_fine_quarantena_post_ospedalizzazione = date_quarantena_no_ricoveri_extended(line, T_quarantena, MVP = MVP, is_MVP = is_MVP)
            # e si procede come segue: 
            # SE max({fine_quarantena_i}) > max({data_dimissione_x_i})
            date_dimissione_x = vcat([ricovero.date_DO for ricovero in line.ricoveri]...,[ricovero.date_DI for ricovero in line.ricoveri]...)
            max_data_dimissione_x = maximum(collect(Iterators.flatten(date_dimissione_x)))
            # max_data_dimissione_x = maximum(vcat([ricovero.date_DO for ricovero in line.ricoveri]...,[ricovero.date_DI for ricovero in line.ricoveri]...))
            if !is_MVP(line.date_FQ) && maximum(line.date_FQ) > max_data_dimissione_x
                # ALLORA si assegnerà `data_inizio_quarantena_ordinaria = data_positività
                data_inizio_quarantena_ordinaria = line.data_P
                # E si procede come segue:
                    # SE presenta data_guarigione E questa è avvenuta entro 60 giorni dalla data_positività, ALLORA data_fine_quarantena_ordinaria = data_guarigione
                    # ALTRIMENTI SE non presenta data_guarigione O questa non è avvenuta entro 60 giorni dalla data_positività E vi è almeno una data_fine_qurantena in {data_fine_quarantena_i > data_positività}, ALLORA data_fine_quarantena_ordinaria = max({data_positività + T_quarantena ,{data_fine_quarantena_i > data_positività}})
                    # ALTRIMENTI SE non presenta data_guarigione O questa non è avvenuta entro 60 giorni dalla data_positività E non vi è alcuna data_fine_qurantena in {data_fine_quarantena_i > data_positività}, ALLORA data_fine_quarantena_ordinaria = data_positività + T_quarantena ***
                data_fine_quarantena_ordinaria = minimum(date_ammissione_x) #!is_MVP(line.data_G) && line.data_G-line.data_P < Dates.Day(60) ? line.data_G : (!is_MVP(line.date_FQ) ? check_maximum([date for date in line.date_FQ if line.data_P < date], MVP = line.data_P + T_quarantena) :  line.data_P + T_quarantena)     
            # ALTRIMENTI SE max({fine_quarantena_i}) <= max({data_dimissione_x_i})
            elseif !is_MVP(line.date_FQ) && maximum(line.date_FQ) <= max_data_dimissione_x
                # si procede come segue: 
                # SE data_positività < min({data_ammissione_x_i})
                if line.data_P < minimum(date_ammissione_x)
                    # ALLORA si assegnerà data_inizio_quarantena_ordinaria = data_positività
                    data_inizio_quarantena_ordinaria = line.data_P
                    # E data_fine_quarantena_ordinaria = min({date_ammissione_x_i}) **
                    data_fine_quarantena_ordinaria = minimum(date_ammissione_x) # min(data_inizio_quarantena_ordinaria + T_quarantena, minimum(date_ammissione_x))
                # ALTRIMENTI SE data_positività = min({data_ammissione_x_i})
                elseif minimum(date_ammissione_x) == line.data_P
                    # ALLORA non si assegneranno le date di quarantena_ordinaria
                    data_inizio_quarantena_ordinaria     = MVP
                    data_fine_quarantena_ordinaria       = MVP
                end
            # Non consideriamo il caso in cui data_positività > min({data_ammissione_x_i}) in quanto questa eventualità è esclusa dall punto 2. .
            # SE non presenta data_fine_quarantena, 
            elseif is_MVP(line.date_FQ)
                # *** distinguished the cases 1. line.data_P == minimum(date_ammissione_x) and 2. minimum(date_ammissione_x) >= line.data_P
                # SE min({data_ammissione_x_i}) ==  data_positività
                if line.data_P == minimum(date_ammissione_x)
                    # ALLORA non si assegneranno le date di quarantena_ordinaria
                    data_inizio_quarantena_ordinaria     = MVP
                    data_fine_quarantena_ordinaria       = MVP
                # ALTRIMENTI SE min({data_ammissione_x_i}) > data_positività ***
                elseif minimum(date_ammissione_x) >= line.data_P # !isempty(date_ammissione_x) && !is_MVP(line.date_FQ) &&
                    # data_inizio_quarantena_ordinaria = data_positività
                    data_inizio_quarantena_ordinaria = line.data_P
                    # data_fine_quarantena_ordinaria = max({data_fine_quarantena_i}) ***
                    data_fine_quarantena_ordinaria = minimum(date_ammissione_x) #max(line.date_FQ)
                # Non consideriamo il caso in cui data_positività > min({data_ammissione_x_i}) in quanto questa eventualità è esclusa dalla necessità di risolvere il problema relativo alle data_positività > min({data_ammissione_x_i}) trattate al punto 2...
                end
            end

            if !is_MVP(line.data_G) && line.data_G > max_data_dimissione_x
                data_inizio_quarantena_post_ospedalizzazione = max_data_dimissione_x
                data_fine_quarantena_post_ospedalizzazione = line.data_G
            end

        end

        
        push!(line_list_quarantene, (line.ID, data_inizio_quarantena_precauzionale, data_fine_quarantena_precauzionale, data_inizio_quarantena_ordinaria,data_fine_quarantena_ordinaria, data_inizio_quarantena_post_ospedalizzazione, data_fine_quarantena_post_ospedalizzazione  ))

        #println( "data_inizio_quarantena_precauzionale = $data_inizio_quarantena_precauzionale \ndata_fine_quarantena_precauzionale = $data_fine_quarantena_precauzionale \ndata_inizio_quarantena_ordinaria = $data_inizio_quarantena_ordinaria \ndata_fine_quarantena_ordinaria = $data_fine_quarantena_ordinaria")

    end

    # Check that the IDs in the line_list_quarantene dataframe are the same as the IDs in the line_list dataframe, and that the outptu e'd get from joining the two is symmetric (this is a redundant check)
    @assert isequal(leftjoin(line_list_dc, line_list_quarantene, on = [:ID]), rightjoin(line_list_dc, line_list_quarantene, on = [:ID]))

    # Return dataframes with data_IQP, data_FQP, data_IQO, data_FQO, and remove date_IQ and date_FQ
    return select(leftjoin(line_list_dc, line_list_quarantene, on = [:ID]), line_lists_quarantene_columns)

end


"""
    process_trasf_trasposti(trasf_trasposti_df::DataFrame, events_dates_names::Dict{Symbol,Symbol}; MVP = missing, is_MVP::F = ismissing) where {F <: Function}

Process `trasf_trasposti_df` from main.py, with events dates names `events_dates_names`, missing values placeholder `MVP` and missing values check function `is_MVP`.
"""
function process_trasf_trasposti(trasf_trasposti_df::DataFrame, events_dates_names::Dict{Symbol,Symbol}; MVP = missing, is_MVP::F = ismissing) where {F <: Function}

    # Deepcopy the input
    trasf_trasposti_df_dc::DataFrame = deepcopy(trasf_trasposti_df)

    # Preallocate a Dict whose pairs are ID => (Ricovero_1, Ricovero_2,... )
    ID_ricoveri_dct = Dict{Int64,Vector{Ricovero}}() #Tuple{Vararg{Ricovero}}

    # Group `trasf_trasposti_df_dc` by ID_SOGGETTO
    trasf_trasposti_by_ID_gd = groupby(trasf_trasposti_df_dc, :ID_SOGGETTO)

    # Loop over groups and their correpsonding keys    
    for (trasf_trasposti_by_ID,groupkey) in zip(trasf_trasposti_by_ID_gd,keys(trasf_trasposti_by_ID_gd))
        # Preallocate the vector that will contain all the `Recovero`s for this ID_SOGGETTO
        ricoveri = Ricovero[]
        # Group by Chiave (which identifies an hospitalization)
        trasf_trasposti_by_ID_by_CHIAVE_gd = groupby(trasf_trasposti_by_ID, :CHIAVE)

        # Loop over groups ientified by ID_SOGGETTO and CHIAVE (thus by a patient and an hospitalization), construct the `Ricovero`s and push them to `ricoveri`
        for trasf_trasposti_by_ID_by_CHIAVE in trasf_trasposti_by_ID_by_CHIAVE_gd

            date_AO = Tuple([date for (date,icu) in zip(trasf_trasposti_by_ID_by_CHIAVE.dt_ammiss,trasf_trasposti_by_ID_by_CHIAVE.repint) if icu==0])

            date_DO = Tuple([date for (date,icu) in zip(trasf_trasposti_by_ID_by_CHIAVE.dt_uscita,trasf_trasposti_by_ID_by_CHIAVE.repint) if icu==0])

            date_AI = Tuple([date for (date,icu) in zip(trasf_trasposti_by_ID_by_CHIAVE.dt_ammiss,trasf_trasposti_by_ID_by_CHIAVE.repint) if icu==1])

            date_DI = Tuple([date for (date,icu) in zip(trasf_trasposti_by_ID_by_CHIAVE.dt_uscita,trasf_trasposti_by_ID_by_CHIAVE.repint) if icu==1])

            push!(ricoveri, Ricovero(;date_AO = date_AO, date_DO = date_DO,date_AI = date_AI,date_DI = date_DI) )
            
        end

        # Create the correpsonding ID => ricoveri pair in the dict
        ID_ricoveri_dct[groupkey.ID_SOGGETTO] = ricoveri #Tuple(ricoveri)

    end

    # Return the DataFrame sorted by ID
    return sort( DataFrame(:ID => collect(keys(ID_ricoveri_dct)), :ricoveri => collect(values(ID_ricoveri_dct))), [:ID] )

end


"""
    get_event_column_from_event_and_sequence(event::String, sequence::Tuple{Vararg{String}})

E.g. `get_event_column_from_event_and_sequence("P", ("P","IQO","FQO","G"))` returns `"P_iqo_fqo_g"`
"""
function get_event_column_from_event_and_sequence(event::String, sequence::Tuple{Vararg{String}})
    event_sequences = get_events_from_sequence(sequence)
    index = [event_sequence for event_sequence in event_sequences if (event in split(event_sequence, "_") )]
    if length(index) == 1

        return index[1]
    else
        error("get_event_column_from_event_and_sequence($event, $sequence) did not return one and only one event sequence")
    end
        
end

