##################################
####### DATA VISUALIZATION #######
##################################


function get_rich_raw_line_list(raw_line_list::DataFrame, run_name::String)
    rich_raw_line_list = DataFrame()
    if occursin("no_is", run_name)
        rich_raw_line_list = raw_line_list[.!is_MVP.(raw_line_list.date_IQ).&.!is_MVP.(raw_line_list.date_FQ).&.!is_MVP.(raw_line_list.ricoveri).&(.!is_MVP.(raw_line_list.data_G).|.!is_MVP.(raw_line_list.data_D)), :] #.!is_MVP.(raw_line_list.data_IS).&
    else
        rich_raw_line_list = raw_line_list[.!is_MVP.(raw_line_list.data_IS).&.!is_MVP.(raw_line_list.date_IQ).&.!is_MVP.(raw_line_list.date_FQ).&.!is_MVP.(raw_line_list.ricoveri).&(.!is_MVP.(raw_line_list.data_G).|.!is_MVP.(raw_line_list.data_D)), :]
    end

    return rich_raw_line_list
end


function get_rich_processed_line_list(processed_line_list::DataFrame, run_name::String)

    rich_processed_line_list = DataFrame() 
    date_IQP = processed_line_list.data_IQP
    date_FQP = processed_line_list.data_FQP
    if occursin("no_is_no_qp", run_name)
        println("no_is_no_qp")
        rich_processed_line_list = processed_line_list[.!is_MVP.(processed_line_list.data_AO).&.!is_MVP.(processed_line_list.data_AI).&(.!is_MVP.(processed_line_list.data_G).|.!is_MVP.(processed_line_list.data_D)), :] #.!is_MVP.(processed_line_list.data_IS).&.!is_MVP.(processed_line_list.data_IQP).& .&(Dates.value.([ismissing(diff) ? Day(50) : diff for diff in date_FQP .- date_IQP]).<30)
    elseif occursin("no_is", run_name)
        println("no_is")
        rich_processed_line_list = processed_line_list[.!is_MVP.(processed_line_list.data_IQP).&.!is_MVP.(processed_line_list.data_AO).&.!is_MVP.(processed_line_list.data_AI).&(.!is_MVP.(processed_line_list.data_G).|.!is_MVP.(processed_line_list.data_D)).&(Dates.value.([ismissing(diff) ? Day(50) : diff for diff in date_FQP .- date_IQP]).<30), :] #.!is_MVP.(processed_line_list.data_IS).&
    elseif occursin("no_qp", run_name)
        println("no_qp")
        rich_processed_line_list = processed_line_list[.!is_MVP.(processed_line_list.data_IS).&.!is_MVP.(processed_line_list.data_AO).&.!is_MVP.(processed_line_list.data_AI).&(.!is_MVP.(processed_line_list.data_G).|.!is_MVP.(processed_line_list.data_D)), :] #.!is_MVP.(processed_line_list.data_IQP).& .&(Dates.value.([ismissing(diff) ? Day(50) : diff for diff in date_FQP .- date_IQP]).<30)
    else
        println("all")
        rich_processed_line_list = processed_line_list[.!is_MVP.(processed_line_list.data_IS).&.!is_MVP.(processed_line_list.data_IQP).&.!is_MVP.(processed_line_list.data_AO).&.!is_MVP.(processed_line_list.data_AI).&(.!is_MVP.(processed_line_list.data_G).|.!is_MVP.(processed_line_list.data_D)).&(Dates.value.([ismissing(diff) ? Day(50) : diff for diff in date_FQP .- date_IQP]).<30), :]
    end

    return rich_processed_line_list

end

"""
    plot_line_list(line_list::DataFrame, MVP, is_MVP::F; size = (1000,1000), limit = Day(30), mode = :hlines_annotations, title = "", dpi = 300) where {F <: Function}

Plots the line associated to `ID` in the raw individual-level surveillance dataset `line_list`. Argument `limit` controls the outliers.
"""
function plot_line_list(line_list::DataFrame, MVP, is_MVP::F; size = (1000,1000), limit = Day(30), mode = :hlines_annotations, title = "", dpi = 300) where {F <: Function}    
    # Associations between events and descriptions
    annotations_legend_dict = OrderedDict("P" => "Positività", 
                                         "IS" => "Inizio Sintomi", 
                                         "IQ" => "Inizio Quarantena", 
                                         "FQ" => "Fine Quarantena", 
                                         "AO" => "Ammissione Ordinaria", 
                                         "DO" => "Dimissione Ordinaria", 
                                         "AI" => "Ammissione Intensiva", 
                                         "DI" => "Dimissione Intensiva", 
                                         "G"  => "Guarigione", 
                                         "D"  => "Decesso")
    # Color palette
    colors = vcat(palette(:tab20)...)

    # Associations between events and colors
    colors_events = Dict(event => color for (event,color) in zip(unique(keys(annotations_legend_dict)), colors))

    # Associations between compartments and the key event defining their lower bound 
    compartments = OrderedDict("IQP" => "Quarantena Precauzionale", 
                               "IQO" => "Quarantena Ordinaria", 
                               "AO"  => "Ospedalizzazione Ordinaria", 
                               "AI"  => "Ospedalizzazione Intensiva", 
                               "AR" => "Ospedalizzazione Riabilitativa"
                              )
    # Associations between compartments and colors
    colors_compartments = OrderedDict(compartment => color for (compartment,color) in zip(values(compartments), colors))

    # Pre-allocate set of all dates
    all_dates = Set{Date}()

    # Initialize plot
    p = plot(seriestype = :scatter, size = size, title = title, xlabel = "Date of key event", ylabel = "Case ID", legendfontsize=10, dpi = dpi ) 

    # Declare xticks
    xticks = (Date("2020-01-01"), Date("2020-02-01"), Date("2020-03-01"), Date("2020-04-01"), Date("2020-05-01"), Date("2020-06-01"), Date("2020-07-01"), Date("2020-08-01"), Date("2020-09-01"), Date("2020-10-01"), Date("2020-11-01"), Date("2020-12-01"), Date("2020-12-31"))
    # Format dates for plotting
    DateTick = Dates.format.(xticks, "dd-mm")
    
    # Loop over IDs
    for ID in line_list.ID
        # Extract line from line-list
        line = line_list[line_list.ID .== ID,:][1,:]

        # Extract events
        P  = line.data_P
        IS = line.data_IS

        IQ = !is_MVP(line.date_IQ) ? [date for date in line.date_IQ if date - P < limit] : MVP
        FQ = !is_MVP(line.date_FQ) ? [date for date in line.date_FQ if date - P < limit] : MVP

        AO = !is_MVP(line.ricoveri) ? [reparto.data_ammissione for ricovero in line.ricoveri for reparto in ricovero.reparti if reparto.tipo == :ordinario] : MVP
        DO = !is_MVP(line.ricoveri) ? [reparto.data_dimissione for ricovero in line.ricoveri for reparto in ricovero.reparti if reparto.tipo == :ordinario] : MVP
        AI = !is_MVP(line.ricoveri) ? [reparto.data_ammissione for ricovero in line.ricoveri for reparto in ricovero.reparti if reparto.tipo == :intensivo] : MVP
        DI = !is_MVP(line.ricoveri) ? [reparto.data_dimissione for ricovero in line.ricoveri for reparto in ricovero.reparti if reparto.tipo == :intensivo] : MVP


        G  = !is_MVP(line.data_G) ? (line.data_G - P < limit ? line.data_G : P + limit) : MVP
        D  = !is_MVP(line.data_D) ? (line.data_D - P < limit ? line.data_D : P + limit) : MVP

        # Collect dates in a Dict, remove MVPs
        dates = OrderedDict("P" => P,"IS" => IS,"IQ" => IQ,"FQ" => FQ,"AO" => AO,"DO" => DO,"AI" => AI,"DI" => DI,"G" => G, "D" => D)
        dates_no_MVP_dct = OrderedDict(key => val for (key,val) in collect(dates) if !is_MVP(val))

        # Collect dates in an array, remove MVPs and flatten
        dates_no_MVP = collect([el for el in values(dates) if !is_MVP(el)])
        dates_no_MVP_flatten = vcat(dates_no_MVP...)

        # Repeat each label n times, where n is the number of dates it is associated to 
        events = [typeof(val) <: Vector || typeof(val) <: Tuple ? repeat([key],length(val)) : key  for (key,val) in collect(dates) if !is_MVP(val) && length(vcat(val)) > 0]
        events = vcat(events...)

        # Add every date-event couple individually
        ## Annotations
        if mode == :annotations
            positions = [:bottom, :top, :right, :left]
            taken_positions = Dict(date => :left for date in unique(dates_no_MVP_flatten))
            for (date,annotation) in zip(dates_no_MVP_flatten, events)
                push!(all_dates, date)
                pos_cyclic_idx = findfirst(x -> x == taken_positions[date], positions)

                plot!([date], [ID], series_annotations = text(annotation,positions[pos_cyclic_idx%4 + 1], color = colors_events[annotation]), label = "")
                taken_positions[date] = positions[pos_cyclic_idx%4 + 1]

            end
        elseif mode == :scatter
            # Scatter
            for (date, annotation) in zip(dates_no_MVP_flatten, events)
                push!(all_dates, date)

                plot!([date], [ID], label = "", seriestype = :scatter, markerstrokewidth = 0.5, markersize  = 7, color = colors_events[annotation])

            end
        elseif mode == :hlines
        ## hlines
            for (i,annotation) in zip(1:(length(dates_no_MVP_flatten)-1), events)
                push!(all_dates, dates_no_MVP_flatten[i])

                plot!([dates_no_MVP_flatten[i]; dates_no_MVP_flatten[i+1]], [[ID]; [ID]], label = "", lc = colors_events[annotation], lw = 3)
            end
            push!(all_dates, dates_no_MVP_flatten[end])
        end
    end

    # Add legend
    if mode == :scatter
        # for (event,explanation) in collect(annotations_legend_dict)
        #     plot!([NaN],[NaN], label = "$event = $explanation ", color = colors_events[event], legend=:topleft)
        # end
        for (event,explanation) in collect(annotations_legend_dict)
            plot!([Date("2020-01-01"), Date("2020-12-31") ],[0,0], label = "$explanation", color = colors_events[event], legend=:topleft, seriestype = :scatter, markersize = floatmin()) #lw = 7 # label =  "$event = 
        end
    elseif mode == :hlines || mode == :hlines_annotations 
        for (event,explanation) in collect(compartments)
            compartment = compartments[event]
            plot!([NaN],[NaN], label = "$explanation", color = colors_compartments[compartment], legend=:topleft)
        end
    end
    # for (event,explanation) in collect(annotations_legend_dict)
    #     plot!([NaN],[NaN], label = "$event = $explanation ", color = colors_events[event], legend=:topleft)
    # end

    # Return the plot
    # DateTick = Dates.format.(collect(all_dates), "dd\n-\nmm")
    # plot!(xticks = (collect(all_dates), DateTick), yticks = 1:nrow(line_list), xtickfontsize=4)
    plot!( xticks = (collect(xticks), DateTick), yticks = 1:nrow(line_list))

    return p
end


function plot_multiple_samples_raw_line_list(rich_raw_line_list::DataFrame, n_lines_per_plot::Int64, title::String, mode::Symbol)

    output_plots = Plots.Plot[]
    n_plots = size(rich_raw_line_list,1) ÷ n_lines_per_plot
    randomized_ids = shuffle(1:size(rich_raw_line_list,1))
    for i in 1:(length(randomized_ids) ÷ n_lines_per_plot )
        rich_sample = rich_raw_line_list[randomized_ids[((i-1)*n_lines_per_plot +1):(i*n_lines_per_plot)],:]
        rich_sample.ID = collect(1:size(rich_sample,1))
        push!(output_plots, plot_line_list(rich_sample, MVP, is_MVP,
        mode = mode,
        title = title,
        size = (1000,900)
       ))
    end

    return output_plots
end

"""
    plot_line_processed(line_list::DataFrame, ID::Int64; MVP, is_MVP::F, size = (1000,100)) where {F <: Function}

Plots the line associated to `ID` in the individual-level surveillance dataset `line_list`.
"""
function plot_line_processed(line_list::DataFrame, ID::Int64; MVP, is_MVP::F, size = (1000,100)) where {F <: Function}
    # Extract line from line-list
    line = line_list[line_list.ID .== ID,:][1,:]
    # Associations between labels and explanations
    annotations_legend_dict = Dict("P" => "positività", "IS" => "inizio_sintomi", "IQ" => "inizio_quarantena", "FQ" => "fine_quarantena", "AO" => "ammissione_ordinaria", "DO" => "dimissione_ordinaria", "AI" => "ammissione_intensiva", "DI" => "dimissione_intensiva", "G" => "guarigione", "D" => "decesso")
    # Extract relevant dates
    P  = line.data_P
    IS = line.data_IS

    IQ = line.date_IQ
    FQ = line.date_FQ

    AO = !is_MVP(line.ricoveri) ? [reparto.data_ammissione for ricovero in line.ricoveri for reparto in ricovero.reparti if reparto.tipo == :ordinario] : MVP
    DO = !is_MVP(line.ricoveri) ? [reparto.data_dimissione for ricovero in line.ricoveri for reparto in ricovero.reparti if reparto.tipo == :ordinario] : MVP
    AI = !is_MVP(line.ricoveri) ? [reparto.data_ammissione for ricovero in line.ricoveri for reparto in ricovero.reparti if reparto.tipo == :intensivo] : MVP
    DI = !is_MVP(line.ricoveri) ? [reparto.data_dimissione for ricovero in line.ricoveri for reparto in ricovero.reparti if reparto.tipo == :intensivo] : MVP

    G  = line.data_G
    D  = line.data_D

    # Collect dates in a Dict, remove MVPs
    dates = OrderedDict("P" => P,"IS" => IS,"IQ" => IQ,"FQ" => FQ,"AO" => AO,"DO" => DO,"AI" => AI,"DI" => DI,"G" => G, "D" => D)
    dates_no_MVP_dct = OrderedDict(key => val for (key,val) in collect(dates) if !is_MVP(val))

    # Collect dates in an array, remove MVPs and flatten
    dates_no_MVP = collect([el for el in values(dates) if !is_MVP(el)])
    dates_no_MVP_flatten = vcat(dates_no_MVP...)

    # Repeat each label n times, where n is the number of dates it is associated to 
    events = [typeof(val) <: Vector || typeof(val) <: Tuple ? repeat([key],length(val)) : key  for (key,val) in collect(dates) if !is_MVP(val) && length(vcat(val)) > 0]
    events = vcat(events...)

    # Format dates for plotting
    # DateTick = Dates.format.(dates_no_MVP_flatten, "dd\n-\nmm")
    xticks = (Date("2020-01-01"), Date("2020-02-01"), Date("2020-03-01"), Date("2020-04-01"), Date("2020-05-01"), Date("2020-06-01"), Date("2020-07-01"), Date("2020-08-01"), Date("2020-09-01"), Date("2020-10-01"), Date("2020-11-01"), Date("2020-12-01"), Date("2020-12-31"))
    DateTick = Dates.format.(xticks, "dd-mm")
    # Initialize plot, possible annotations positions and colors
    p = plot( seriestype = :scatter, ylim = (-0.02,0.2), xticks = (xticks, DateTick), title = "ID = $ID", legendfontsize = 40) #dates_no_MVP_flatten
    positions = [:bottom, :top, :right, :left]
    taken_positions = Dict(date => :left for date in unique(dates_no_MVP_flatten))
    colors = vcat(palette(:tab10)...,palette(:tab10)...)
    colors_dates = Dict(date => col for (date,col) in zip(unique(dates_no_MVP_flatten),colors))

    # Add every date-event couple individually
    for (date,annotation) in zip(dates_no_MVP_flatten, events)
        pos_cyclic_idx = findfirst(x -> x == taken_positions[date], positions)

        plot!([date], [0], series_annotations = text(annotation,positions[pos_cyclic_idx%4 + 1], color = colors_dates[date]), label = "")
        taken_positions[date] = positions[pos_cyclic_idx%4 + 1]

    end

    # Add legend
    for annotation in unique(events)
        plot!([missing],[missing], label = "$annotation = "*annotations_legend_dict[annotation], color = :white)
    end

    

    # Return the plot
    return p
end








"""
    plot_line_list_processed(line_list::DataFrame, MVP, is_MVP::F; size = (1000,1000), limit = Day(30), mode = :hlines, title = "") where {F <: Function}

Function that plots the line associated to `ID` in the individual-level surveillance dataset `line_list`. Argument `limit` controls the outliers.
"""
function plot_line_list_processed(line_list::DataFrame, MVP, is_MVP::F; size = (1000,1000), limit = Day(30), mode = :hlines, title = "", dpi = 300, lw = 11) where {F <: Function}
    # Associations between labels and explanations
    annotations_legend_dict = OrderedDict("P" => "Positività", "IS" => "Inizio Sintomi", "IQP" => "Inizio Quarantena Precauzionale", "FQP" => "Fine Quarantena Precauzionale", "IQO" => "Inizio Quarantena Ordinaria", "FQO" => "Fine Quarantena Ordinaria", "AO" => "Ammissione Ordinaria", "DO" => "Dimissione Ordinaria", "AI" => "Ammissione Intensiva", "DI" => "Dimissione Intensiva", "AR" => "Ammissione Riabilitativa", "DR" => "Dimissione Riabilitativa", "G" => "Guarigione", "D" => "Decesso")
    # Color palette
    colors = palette(:tab20)
    # Associations between events and colors
    colors_events = Dict(event => color for (event,color) in zip(unique(keys(annotations_legend_dict)), colors))
    # Associations between compartments and the event that introduces them
    compartments = OrderedDict("IQP" => "Quarantena Precauzionale", "IQO" => "Quarantena Ordinaria", "AO" => "Ospedalizzazione Ordinaria", "AI" => "Ospedalizzazione Intensiva", "AR" => "Ospedalizzazione Riabilitativa")
    # Associations between compartments and colors
    colors_compartments = OrderedDict(compartment => color for (compartment,color) in zip(values(compartments), colors))
    # Pre-allocate set of all dates
    all_dates = Set{Date}()

    # Initialize plot
    p = plot(seriestype = :scatter, size = size, title = title, xlabel = "Date of key event", ylabel = "Case ID",  dpi = dpi, xrotation = 0) 

    # Loop over IDs
    for ID in line_list.ID
        # Extract line from line-list data
        line = line_list[line_list.ID .== ID,:][1,:]

        # Extract key events
        P  = line.data_P
        IS = line.data_IS

        IQP = line.data_IQP
        FQP = line.data_FQP

        IQO = line.data_IQO
        FQO = line.data_FQO

        AO = line.data_AO
        DO = line.data_DO
        AI = line.data_AI
        DI = line.data_DI
        AR = line.data_AR
        DR = line.data_DR

        G = line.data_G
        D = line.data_D

        # Collect dates in a Dict, remove MVPs
        dates = OrderedDict("P" => P,"IS" => IS,"IQP" => IQP,"FQP" => FQP, "IQO" => IQO,"FQO" => FQO, "AO" => AO,"DO" => DO,"AI" => AI,"DI" => DI, "AR" => AR,"DR" => DR, "G" => G, "D" => D)
        dates_no_MVP_dct = OrderedDict(key => val for (key,val) in collect(dates) if !is_MVP(val))

        # Collect dates in an array, remove MVPs and flatten
        dates_no_MVP = collect([el for el in values(dates) if !is_MVP(el)])
        dates_no_MVP_flatten = vcat(dates_no_MVP...)

        # Repeat each label n times, where n is the number of dates it is associated to 
        events = [typeof(val) <: Vector || typeof(val) <: Tuple ? repeat([key],length(val)) : key  for (key,val) in collect(dates) if !is_MVP(val) && length(vcat(val)) > 0]
        events = vcat(events...)

        # Add every date-event couple individually
        ## Annotations
        if mode == :annotations
            positions = [:bottom, :top, :right, :left]
            taken_positions = Dict(date => :left for date in unique(dates_no_MVP_flatten))
            for (date,annotation) in zip(dates_no_MVP_flatten, events)
                push!(all_dates, date)
                pos_cyclic_idx = findfirst(x -> x == taken_positions[date], positions)

                plot!([date], [ID], series_annotations = text(annotation,positions[pos_cyclic_idx%4 + 1], color = colors_events[annotation]), label = "")
                taken_positions[date] = positions[pos_cyclic_idx%4 + 1]
            end
        elseif mode == :scatter
            # Scatter
            for (date, annotation) in zip(dates_no_MVP_flatten, events)
                push!(all_dates, date)

                plot!([date], [ID], label = "", seriestype = :scatter, markerstrokewidth = 0.5, markersize  = 7, color = colors_events[annotation]) 

            end
        elseif mode == :hlines_annotations
        ## hlines
            positions = [:bottom, :top, :right, :left]
            taken_positions = Dict(date => :left for date in unique(dates_no_MVP_flatten))
            for i in 1:(length(dates_no_MVP_flatten))
                push!(all_dates, dates_no_MVP_flatten[i])
                compartment = ""
                if events[i] in ["FQP","FQO", "DO", "DI", "DR"]
                    continue
                elseif  events[i] in ["P", "IS", "G", "D" ]
                    pos_cyclic_idx = findfirst(x -> x == taken_positions[dates_no_MVP_flatten[i]], positions)

                    plot!([dates_no_MVP_flatten[i]], [ID], series_annotations = text(events[i], positions[pos_cyclic_idx%4 + 1],20, color = colors_events[events[i]], family = "New Century Schoolbook Bold"), label = "")
                    taken_positions[dates_no_MVP_flatten[i]] = positions[pos_cyclic_idx%4 + 1]

                elseif i < length(dates_no_MVP_flatten) && events[i] ∉ ["P","FQP","FQO", "DO", "DI", "DR", "IS", "G", "D"]
                    compartment  = compartments[events[i]]
                    plot!([dates_no_MVP_flatten[i]; dates_no_MVP_flatten[i+1]], [[ID]; [ID]], label = "", lc = colors_compartments[compartment], lw = 25)
                end
            end
            push!(all_dates, dates_no_MVP_flatten[end])
        elseif mode == :hlines
            ## Hline
            for i in 1:(length(dates_no_MVP_flatten))
                push!(all_dates, dates_no_MVP_flatten[i])
                compartment = ""
                if events[i] in ["P","FQP","FQO", "DO", "DI", "DR", "IS", "G", "D"]
                    continue
                elseif i < length(dates_no_MVP_flatten) && events[i] ∉ ["P","FQP","FQO", "DO", "DI", "DR", "IS", "G", "D"  ]
                    compartment  = compartments[events[i]]
                    plot!([dates_no_MVP_flatten[i]; dates_no_MVP_flatten[i+1]], [[ID]; [ID]], label = "", lc = colors_compartments[compartment], lw = 7)
                end
            end
            push!(all_dates, dates_no_MVP_flatten[end])
        end
    end

    # Add legend
    xticks = (Date("2020-01-01"), Date("2020-02-01"), Date("2020-03-01"), Date("2020-04-01"), Date("2020-05-01"), Date("2020-06-01"), Date("2020-07-01"), Date("2020-08-01"), Date("2020-09-01"), Date("2020-10-01"), Date("2020-11-01"), Date("2020-12-01"), Date("2020-12-31"))
    DateTick = Dates.format.(collect(xticks), "dd-mm")
    if mode == :scatter
        for (event,explanation) in collect(annotations_legend_dict)
            plot!([Date("2020-01-01"), Date("2020-12-31")],[0,0], label = "$explanation", color = colors_events[event], legend=:topleft, seriestype = :scatter, markersize = floatmin()) #lw = 7 label = "$event = 
        end
        plot!( xticks = (collect(xticks), DateTick), yticks = 1:nrow(line_list), legendfontsize = 8)
    elseif mode == :hlines || mode == :hlines_annotations
        for (event,explanation) in collect(compartments)
            compartment = compartments[event]
            plot!([Date("2020-01-01"), Date("2020-12-31")],[NaN,NaN], label = "$explanation", color = colors_compartments[compartment], legend=:topleft) # , lw = 7 # [NaN],[NaN]
        end
        plot!( xticks = (collect(xticks), DateTick), yticks = 1:nrow(line_list), legendfontsize = 20, xtickfontsize = 15, ytickfontsize = 15, xguidefontsize = 25, yguidefontsize = 25, titlefontsize = 35, left_margin = 8mm)
    end
    # Return the plot

     # xticks = (collect(all_dates), DateTick), xtickfontsize=4
    #plot!( yticks = 1:nrow(line_list))
    return p
end


function plot_multiple_samples_processed_line_list(rich_processed_line_list::DataFrame, n_lines_per_plot::Int64, title::String, mode::Symbol, plot_size::Tuple{Int64, Int64})

    output_plots = Plots.Plot[]
    n_plots = size(rich_processed_line_list,1) ÷ n_lines_per_plot
    randomized_ids = shuffle(1:size(rich_processed_line_list,1))
    for i in 1:(length(randomized_ids) ÷ n_lines_per_plot )
        rich_sample = rich_processed_line_list[randomized_ids[((i-1)*n_lines_per_plot +1):(i*n_lines_per_plot)],:]
        rich_sample.ID = collect(1:size(rich_sample,1))
        push!(output_plots, plot_line_list_processed(rich_sample, MVP, is_MVP,
        mode = mode,
        title = title,
        size = plot_size,
        lw = 15
       ))
    end

    return output_plots
end

"""
    plot_sequences(sequences::OrderedDict{Tuple{Vararg{String, N} where N}, OrderedDict{Int64, DataFrame}}; plot_size = (1000,900), paltt = :Paired9)

Returns a vector of plots of `sequences`. The size of each plot is `size`, and the palette is `pallt`.
"""
function plot_sequences(sequences::OrderedDict{Tuple{Vararg{String, N} where N}, OrderedDict{Int64, DataFrame}}, age_classes_dct::Dict{Int64,String}; plot_size = (1000,900), paltt = :Paired_9)
    # Pre-allocate output
    sequences_plots = Dict{String, Plots.Plot}()
    # Color palette
    colors = vcat(palette(paltt)...,palette(paltt)...)
    # Loop over sequences
    for sequence in keys(sequences)
        # Vector that will contain the plots for each age class
        age_classes_plots = Plots.Plot[]
        # Maximum y among all age age_classes_dct
        y_max = maximum(vcat(vcat([[col for col in eachcol(dataframe)[2:end]] for dataframe in values(sequences[sequence])]...)...))
        yticks = 0:ceil(y_max/8):y_max
        # Plot single age class
        for (age_class,dataframe) in collect(sequences[sequence])
            age_class_complete = age_classes_dct[age_class]
            start_idx = findfirst(x -> x >= Date("2015-01-01"), dataframe.data)
            x = dataframe.data[start_idx:end]
            ys = [col[start_idx:end] for col in eachcol(dataframe)[2:end] ]
            age_class_plot = plot(x, ys, label = "", xlabel = "Date", ylabel ="Cases", title = age_class_complete , lc = reshape(colors[1:(size(dataframe,2) - 1)], (1,size(dataframe,2) - 1)), yticks = yticks, ylim = (0,y_max), lw = 2)
            push!(age_classes_plots, age_class_plot)
        end

        # Add legend as a separate invisible plot
        labels = reshape(collect(get_events_from_sequence(sequence)), (1,length(get_events_from_sequence(sequence))))
        legend_plot = plot((1:length(labels))', legend = true, framestyle = :none, label = labels, color = reshape(colors[1:length(labels)], (1,length(labels))))
        sequence_plot = plot(vcat(age_classes_plots, legend_plot)..., layout = @layout[grid(length(age_classes_plots),1) a{0.3w}] , plot_title = join(sequence,"_"), size = plot_size)

        push!(sequences_plots, join(sequence, "_") =>  sequence_plot)
    end

    # Return 
    return sequences_plots
end

"""
    function plot_delays(delays::Dict{String, OrderedDict{Int64, OrderedDict{Int64, Dict{String,DataFrame}}}}, T::Int64, age_classes_dct::Dict{Int64,String}; plot_size = (1000,900))

Returns a dictionary of time delays distributions. The size of each plot is `size`.
"""
function plot_delays(delays::Dict{String, OrderedDict{Int64, OrderedDict{Int64, Dict{String,DataFrame}}}}, T::Int64, age_classes_dct::Dict{Int64,String}; plot_size = (1000,900))
    # Pre-allocate dict delay_name => Plot
    delays_plots = Dict{String, Plots.Plot}()

    ## Set plot colors
    bars_color = palette(:tab20)[2]

    for (delay_name, T_ageclass_status_dct) in collect(delays)
        asymptomatic_plots = Plots.Plot[]
        symptomatic_plots  = Plots.Plot[]
        age_class_plots    = Plots.Plot[]

        # Get max bin position taken from data
        data_driven_max_bin = maximum(vcat([vcat([line.delay for line in eachrow(status_dct[status])]...) for status_dct in values(T_ageclass_status_dct[T]) for status in ["Sintomatici", "Asintomatici"] if status in keys(status_dct) ]...))+1
        # If max bin is less than 30, set ito to 30 (for aesthetichs) else keep that
        max_bin = data_driven_max_bin < 30 ? 30 : data_driven_max_bin

        bins = 0:1:max_bin

        # Get all observations
        observations = vcat([ [line.frequenza_delay for line in eachrow(status_dct[status])] for status_dct in values(T_ageclass_status_dct[T]) for status in ["Sintomatici", "Asintomatici"] if status in keys(status_dct)  ]...)

        # Get xticks and yticks
        max_obs = maximum(observations)
        yticks  = 0:ceil(max_obs/8):max_obs
        xticks  = max_bin < 5 ? range(0,max_bin,step = 1) : 0:(max_bin ÷ 5):max_bin

        # Plot each age_class and status delay distribution
        for (i, (age_class,status_dct)) in enumerate(collect(T_ageclass_status_dct[T]))
            if "Sintomatici" in keys(status_dct)
                dataframe = status_dct["Sintomatici"]
                sorted_df = sort(dataframe, [:delay])
                delays = sorted_df.delay[1]:sorted_df.delay[end]
                tot = sum(sorted_df.frequenza_delay)
                observations = Float64[]
                sizehint!(observations, length(delays) )
                for delay in delays
                    idxs = findall(x -> x == delay, sorted_df.delay)
                    !isnothing(idxs) ? push!(observations, sum(sorted_df.frequenza_delay[idxs])  ) : push!(observations, 0 )
                end
                p =  bar(delays, observations , color = bars_color , size = (1000, 900), legendfontsize = 30, xticks = xticks, xlim = (0, max_bin ), legend = false) #  label = "Empirical",
                # dataframe = status_dct["Sintomatici"]
                # occurrencies = vcat([vcat(repeat([line.delay], line.frequenza_delay)...) for line in eachrow(dataframe)]...)
                # p = histogram(occurrencies, legend = false, bins = bins, yticks = yticks, xticks = xticks, ylim = (0, maximum(yticks)))
                i == length(collect(T_ageclass_status_dct[T])) ? plot!(xlabel = "Days") : plot!()
                push!(symptomatic_plots, p) #  title = age_classes_dct[age_class], # maximum(collect(values(counter(occurrencies))))
            else
                p = plot(xticks,repeat([missing], length(xticks)), legend = false,  yticks = yticks, xticks = xticks, ylim = (0,maximum(yticks))) #framestyle = :none
                i == length(collect(T_ageclass_status_dct[T])) ? plot!(xlabel = "Days") : plot!()
                push!(symptomatic_plots, p) # framestyle = :none
            end

            if "Asintomatici" in keys(status_dct)
                dataframe = status_dct["Asintomatici"]
                sorted_df = sort(dataframe, [:delay])
                delays = sorted_df.delay[1]:sorted_df.delay[end]
                tot = sum(sorted_df.frequenza_delay)
                observations = Float64[]
                sizehint!(observations, length(delays))
                for delay in delays
                    idxs = findall(x -> x == delay, sorted_df.delay)
                    !isnothing(idxs) ? push!(observations, sum(sorted_df.frequenza_delay[idxs]) ) : push!(observations, 0)
                end
                p =  bar(delays, observations , ylabel = "Frequencies", color = bars_color , size = (1000, 900), legendfontsize = 30, xticks = xticks, xlim = (0, max_bin ), legend = false) # label = "Empirical",
                # dataframe = status_dct["Asintomatici"]
                # occurrencies = vcat([vcat(repeat([line.delay], line.frequenza_delay)...) for line in eachrow(dataframe)]...)
                # p = histogram(occurrencies, legend = false, bins = bins, yticks = yticks, xticks = xticks, ylim = (0, maximum(yticks)))
                i == length(collect(T_ageclass_status_dct[T])) ? plot!(xlabel = "Days") : plot!()
                push!(asymptomatic_plots,  p) # title = age_classes_dct[age_class] # maximum(collect(values(counter(occurrencies))))
            else
                p = plot(xticks,repeat([missing], length(xticks)), legend = false, yticks = yticks, xticks = xticks, ylim = (0,maximum(yticks))) # framestyle = :none
                i == length(collect(T_ageclass_status_dct[T])) ? plot!(xlabel = "Days") : plot!()
                push!(asymptomatic_plots, p)
            end

            push!(age_class_plots, plot( title = age_classes_dct[age_class], framestyle = :none))
        end

        # Combine plots in one plot
        asymptomatic_plot = !isempty(asymptomatic_plots) ? plot(asymptomatic_plots..., plot_title = "Asymptomatic", layout = (length(asymptomatic_plots),1)) : plot(plot_title = "Asintomatici", framestyle = :none)
        symptomatic_plot =  !isempty(symptomatic_plots) ? plot(symptomatic_plots..., plot_title = "Symptomatic", layout = (length(symptomatic_plots),1)) : plot(plot_title = "Sintomatici", framestyle = :none)
        age_class_plot = plot(age_class_plots..., layout = (length(age_class_plots),1), plot_title = "\n"^round(Int64, 10/length(age_class_plots)) )#"\n"^round(Int64, 10/length(age_class_plots)))
        delay_name_split = split(delay_name, "_")
        push!(delays_plots, delay_name => plot(plot(title = "Empirical time delay distribution from $(delay_name_split[2]) to $(delay_name_split[3])", framestyle = :none ),age_class_plot, asymptomatic_plot, symptomatic_plot, size = plot_size , layout = @layout [d{0.001h}
        [a{0.1w} b{0.45w} c{0.45w}] 
        ])) #plot_title = "Empirical time delay distribution from $(delay_name_split[2]) to $(delay_name_split[3])" 
    end

    # Return the dictionary of time delays 
    return delays_plots 
end


"""
    plot_fitted_time_delay_distributions(empirical_time_delays::Dict{String, OrderedDict{Int64, OrderedDict{Int64, Dict{String,DataFrame}}}}, estimated_time_delays_distributions::Dict{String, OrderedDict{Int64, OrderedDict{Int64, Dict{String,Vector{Tuple{Any, Float64}} }}}},  T::Int64, age_classes_dct::Dict{Int64,String}; plot_size = (1000,900))

Return a dictionary of plots (one per delay) together with the estimated empirical distributions.
"""
function plot_fitted_time_delay_distributions(empirical_time_delays::Dict{String, OrderedDict{Int64, OrderedDict{Int64, Dict{String,DataFrame}}}}, estimated_time_delays_distributions::Dict{String, OrderedDict{Int64, OrderedDict{Int64, Dict{String,Vector{Tuple{Any, Float64}} }}}},  T::Int64, age_classes_dct::Dict{Int64,String}; plot_size = (1000,900))



    # Preallocate outputs
    delays_plots = Dict{String, Plots.Plot}()

    ## Set plot colors
    bars_color = palette(:tab20)[2]
    line_color = palette(:tab20)[7]
    for (estimated_T_ageclass_status_dct, (delay_name, T_ageclass_status_dct)) in zip(values(estimated_time_delays_distributions), collect(empirical_time_delays))
        asymptomatic_plots = Plots.Plot[]
        symptomatic_plots  = Plots.Plot[]
        age_class_plots    = Plots.Plot[]

        # Get max bin position taken from data
        data_driven_max_bin = maximum(vcat([vcat([line.delay for line in eachrow(status_dct[status])]...) for status_dct in values(T_ageclass_status_dct[T]) for status in ["Sintomatici", "Asintomatici"] if status in keys(status_dct) ]...))+1
        # If max bin is less than 30, set ito to 30 (for aesthetichs) else keep that
        max_bin = data_driven_max_bin < 30 ? 30 : data_driven_max_bin

        bins = 0:1:max_bin

        # Get all observations
        observations = vcat([ [line.frequenza_delay for line in eachrow(status_dct[status])] for status_dct in values(T_ageclass_status_dct[T]) for status in ["Sintomatici", "Asintomatici"] if status in keys(status_dct)  ]...)

        # Get xticks and yticks
        max_obs = maximum(observations)
        yticks  = 0:ceil(max_obs/8):max_obs
        xticks  = 0:ceil(max_bin/8):max_bin #max_bin < 5 ? range(0,max_bin,step = 1) : 0:(max_bin ÷ 5):max_bin

        # Get plot title
        delay_name_splits = split(delay_name, "_")
        # title = "Time delay distribution from $(delay_name_splits[2]) to $(delay_name_splits[3])"

        # Plot each age_class and status delay distribution
        for (i,(estimated_status_dct, (age_class,status_dct))) in enumerate(zip(values(estimated_T_ageclass_status_dct[T]),collect(T_ageclass_status_dct[T])))
 

            if "Sintomatici" in keys(status_dct)
                dataframe = status_dct["Sintomatici"]
                sorted_df = sort(dataframe, [:delay])
                delays = sorted_df.delay[1]:sorted_df.delay[end]
                tot = sum(sorted_df.frequenza_delay)
                observations = Int64[]
                sizehint!(observations, length(delays) )
                for delay in delays
                    idxs = findall(x -> x == delay, sorted_df.delay)
                    !isnothing(idxs) ? push!(observations, sum(sorted_df.frequenza_delay[idxs])  ) : push!(observations, 0 )
                end
                # occurrencies = vcat([vcat(repeat([line.delay], line.frequenza_delay)...) for line in eachrow(dataframe)]...)
                p =  bar(delays, observations ./ tot , label = "Empirical", color = bars_color , size = (1000, 900), legendfontsize = 30, xticks = xticks, xlim = (0, max_bin ), legend = true) #histogram(occurrencies, legend = false, bins = bins, yticks = yticks, xticks = xticks, ylim = (0, maximum(yticks)))
                println(estimated_status_dct)
                if haskey(estimated_status_dct,"Sintomatici")
                    for (i,(fitted_distrib,loss)) in enumerate(estimated_status_dct["Sintomatici"])
                        distribution_name = split(string(typeof(fitted_distrib)), "{")[1]
                        plot!(0:max_bin, Distributions.pdf.(Ref(fitted_distrib), 0:max_bin), lw = 5, label = "Estimated $distribution_name", color = palette(:tab20)[i])
                    end
                end
                i == length(collect(T_ageclass_status_dct[T])) ? plot!(xlabel = "Days") : plot!()
                push!(symptomatic_plots, p) #  title = age_classes_dct[age_class], # maximum(collect(values(counter(occurrencies))))
            else
                
                p = plot(xticks,repeat([missing], length(xticks)), legend = false,  yticks = yticks, xticks = xticks) #framestyle = :none
                i == length(collect(T_ageclass_status_dct[T])) ? plot!(xlabel = "Days") : plot!()
                push!(symptomatic_plots, p) # framestyle = :none
            end

            if "Asintomatici" in keys(status_dct)
                dataframe = status_dct["Asintomatici"]
                sorted_df = sort(dataframe, [:delay])
                delays = sorted_df.delay[1]:sorted_df.delay[end]
                tot = sum(sorted_df.frequenza_delay)
                observations = Int64[]
                sizehint!(observations, length(delays))
                for delay in delays
                    idxs = findall(x -> x == delay, sorted_df.delay)
                    !isnothing(idxs) ? push!(observations, sum(sorted_df.frequenza_delay[idxs]) ) : push!(observations, 0)
                end
                #dataframe = status_dct["Asintomatici"]
                #occurrencies = vcat([vcat(repeat([line.delay], line.frequenza_delay)...) for line in eachrow(dataframe)]...)
                #p = histogram(occurrencies, legend = false, bins = bins, yticks = yticks, xticks = xticks, ylim = (0, maximum(yticks)))
                p =  bar(delays, observations ./ tot , ylabel = "Frequencies", label = "Empirical", color = bars_color , size = (1000, 900), legendfontsize = 30, xticks = xticks, xlim = (0, max_bin ), legend = true) #histogram(occurrencies, legend = false, bins = bins, yticks = yticks, xticks = xticks, ylim = (0, maximum(yticks))) ylabel = "Frequency"
                if haskey(estimated_status_dct,"Asintomatici")
                    for (i,(fitted_distrib,loss)) in enumerate(estimated_status_dct["Asintomatici"])
                        distribution_name = split(string(typeof(fitted_distrib)), "{")[1]
                        plot!(0:max_bin, Distributions.pdf.(Ref(fitted_distrib), 0:max_bin), lw = 5, label = "Estimated $distribution_name", color = palette(:tab20)[i])
                    end
                end
                i == length(collect(T_ageclass_status_dct[T])) ? plot!(xlabel = "Days") : plot!()
                push!(asymptomatic_plots,  p) # title = age_classes_dct[age_class] # maximum(collect(values(counter(occurrencies))))
            else
                p = plot(xticks,repeat([missing], length(xticks)), legend = false, xticks = xticks) # framestyle = :none
                i == length(collect(T_ageclass_status_dct[T])) ? plot!(xlabel = "Days") : plot!()
                push!(asymptomatic_plots, p)
            end

            push!(age_class_plots, plot( title = age_classes_dct[age_class], framestyle = :none))
        end

        # Combine plots in one plot
        asymptomatic_plot = !isempty(asymptomatic_plots) ? plot(asymptomatic_plots..., plot_title = "Asymptomatic", layout = (length(asymptomatic_plots),1)) : plot(plot_title = "Asintomatici", framestyle = :none)
        symptomatic_plot =  !isempty(symptomatic_plots) ? plot(symptomatic_plots..., plot_title = "Symptomatic", layout = (length(symptomatic_plots),1)) : plot(plot_title = "Sintomatici", framestyle = :none)
        age_class_plot = plot(age_class_plots..., layout = (length(age_class_plots),1), plot_title = "\n"^round(Int64, 10/length(age_class_plots))) #"\n"^round(Int64, 10/length(age_class_plots))
        delay_name_split = split(delay_name, "_")
        push!(delays_plots, delay_name => plot([age_class_plot, asymptomatic_plot, symptomatic_plot]..., size = plot_size, plot_title = "Empirical time delay distribution from $(delay_name_split[2]) to $(delay_name_split[3])"  , layout = @layout [a{0.1w} b{0.45w} c{0.45w}] )) #"Empirical time delay distribution from $(delay_name_split[2]) to $(delay_name_split[3])" size = plot_size @layout [a{0.1w} b{0.45w} c{0.45w}] age_class_plot, a{0.9w} 
    end 

        # Return the dictionary of time delays 
        return delays_plots 


end


function plot_incidences(incidences::OrderedDict{String, OrderedDict{Int64, DataFrame}}, age_classes_dct::Dict{Int64,String};event_title_associations::Dict{String,Dict{String,String}}, disease::String ,plot_size = (1000,900))
    plots = Dict{String,Plots.Plot}()
    for (event,age_incidence_dct) in collect(incidences)
        age_plots = Plots.Plot[]

        max_y = maximum([maximum(incidence_dataframe.cases) for incidence_dataframe in values(age_incidence_dct)])
        # step = max_y ÷ 8 > 0 ? 8 : 1 
        y_ticks = 0:ceil(max_y/8 + 1):max_y


        for (i,(age,incidence_dataframe)) in enumerate(collect(age_incidence_dct))
            start_idx = findfirst(x -> x >= Date("2015-01-01"), incidence_dataframe.date)
            if i == length(values(age_classes_dct))
                push!(age_plots, plot(incidence_dataframe.date[start_idx:end], incidence_dataframe.cases[start_idx:end], legend = false, xlabel = "Date", ylabel = "Cases", title = age_classes_dct[age], ylim = (0, max_y), yticks = y_ticks, lw = 3))
            else
                push!(age_plots, plot(incidence_dataframe.date[start_idx:end], incidence_dataframe.cases[start_idx:end], legend = false, ylabel = "Cases", title = age_classes_dct[age], ylim = (0, max_y), yticks = y_ticks, lw = 3))
            end
        end

        push!(plots, event => plot(age_plots..., layout = (5,1), plot_title = event_title_associations[event]["prefix"]*" $disease "*event_title_associations[event]["suffix"], size = plot_size)) #plot_title = event
    end

    return plots
end