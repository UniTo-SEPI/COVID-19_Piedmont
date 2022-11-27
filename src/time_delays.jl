########################
##### TIME DELAYS ######
########################

function get_row(date_1::Date, date_2::Date, date_inizio::Vector{Date},date_fine::Vector{Date})
    row = []
    for (i,date_range) in enumerate(zip(date_inizio,date_fine))
        if date_range[1] <= date_1 <= date_range[2]
            row = [date_range[1], date_range[2], Dates.value(date_2 - date_1), 1]
            break
        end
    end
    return row
end

function join_dicts(dict_1, dict_2)
    output_dict = deepcopy(dict_1)
    for (key_2,value_2) in collect(dict_2)
        if !haskey(output_dict,key_2)
            push!(output_dict, key_2 => value_2)
        elseif haskey(output_dict,key_2) && typeof(value_2) <: Dict || typeof(value_2) <: OrderedDict
            push!(output_dict, key_2 => join_dicts(output_dict[key_2], value_2) )
        end
    end
    return output_dict
end

function get_α_gamma(obs::Vector{Int64})
    sk = skewness(obs)
    if sk < Inf && !isnan(sk) && sk != 0
        return (2/sk)^2
    else
        return 1.0
    end
end

function get_θ_gamma(obs::Vector{Int64})
    sk = skewness(obs)
    m = mean(obs)
    if sk < Inf && !isnan(sk) && sk != 0  && m > 0
        return mean(obs)/((2/skewness(obs))^2)
    else
        return 1.0
    end
end

function get_σ_lognormal(obs::Vector{Int64})
    σ² = 2*log(mean(obs)/median(obs))
    if  σ² > 0
        return sqrt(σ²)
    else 
        return 1.0
    end
end

function get_r_negativebinomial(obs::Vector{Int64})
    cand = (mean(obs)^2)/( var(obs) - mean(obs) )
    if !isnan(cand) && cand > 0
        return cand
    else
        return 1.0
    end

end

function get_p_negativebinomial(obs::Vector{Int64})
    cand = mean(obs)/var(obs)

    if !isnan(cand) && 0<=cand<=1
        return cand
    else
        return 0.5
    end

end

const upper_lower_bounds = Dict(Gamma            => ([0.0,0.0] .+ eps(), [Inf, Inf]), 
                                LogNormal        => ([0.0,0.0] .+ eps(), [Inf, Inf]), 
                                NegativeBinomial => ([0.0,0.0] .+ eps(), [Inf,1.0]),
                                Weibull          => ([0.0,0.0] .+ eps(), [Inf, Inf])
)

"""
    get_delays(line_list::DataFrame; max_T::Int64, privacy_policy::Bool, distributions_types = (Distribution{Univariate,Continuous}, Distribution{Univariate,Discrete}), optim_algorithm = BFGS(), loss = :pdf, MVP, is_MVP::F) where {F <: Function}

Compute:
- Empirical absolute time delays distributions from processed integrated individual-level surveillance dataset `line_list` according to the data model description manual; 
- Empirical frequency time delay distributions;
- Estimated distributions (using all kernels contained in `distributions_types`) if !isempty(`distributions_types`) using Optim.jl's algorithm `optim_algorithm` and loss strategy `loss` (one of (:pdf, :quantiles, :both)).
- 
"""
function get_delays(line_list::DataFrame; Ts::Tuple{Vararg{Int64}}, date_start::Date, date_end::Date, privacy_policy::Bool, distributions_types = (Distribution{Univariate,Continuous}, Distribution{Univariate,Discrete}), optim_algorithm = BFGS(), loss = :pdf, get_frequencies::Bool = true, time_limit = 10,  MVP, is_MVP::F) where {F <: Function}
    # Check that if !isempty(distributions_types), then `loss` is in (:pdf, :quantile, :both) # max_T::Int64
    if !isempty(distributions_types) && loss ∉ (:pdf, :quantile, :both)
        error("`loss` argument may only be one of (:pdf, :quantile, :both)")
    end
    # Pre-allocate output. They are:
    #A Dict(delay_name => OrderedDict(T=>OrderedDict(age_class => Dict(status => DataFrame)))) where delay_name could e.g. bt T_P_G, T could e.g. be 1, age_class could e.g. be 70, status couldr e.g. be "Sintomatico".
    delays_T_ageclass_status_dct = Dict{String, OrderedDict{Int64, OrderedDict{Int64, Dict{String,DataFrame}}}}()
    # A Dict(delay_name => OrderedDict(T=>OrderedDict(age_class => Dict(status => vector_of_fitted_distributions)))) where delay_name could e.g. bt T_P_G, T could e.g. be 1, age_class could e.g. be 70, status couldr e.g. be "Sintomatico".
    name_distributions_dct  =  Dict{String, OrderedDict{Int64, OrderedDict{Int64, Dict{String, Vector{Tuple{Any,Float64}}}}}}() # @threads  for i in 1:nthreads()]
    # Preallocate empirical frequencies distributions output
    delays_T_ageclass_status_freq_dct = Dict{String, OrderedDict{Int64, OrderedDict{Int64, Dict{String,DataFrame}}}}()

    # Set formulae to initialize distribution parameters
    distributions_parameters_formula = Dict(Gamma            => OrderedDict( "α" => obs -> get_α_gamma(obs) ,                              "θ" => obs -> get_θ_gamma(obs)    ),
                                            LogNormal        => OrderedDict( "μ" => obs -> max(log(median(obs)),eps()),                        "σ" => obs -> get_σ_lognormal(obs)  ),
                                            NegativeBinomial => OrderedDict( "r" => obs -> get_r_negativebinomial(obs),                    "p" => obs -> get_p_negativebinomial(obs)                ),
                                            Weibull          => OrderedDict( "α" => obs -> 1,                                              "θ" => obs -> 1  ) # Default values since momentsd are not invertible w.r.t. parameters
                                            ) 

    # Calculate overall time period
    period = date_end - date_start
    #OrderedDict{String, Vector{Any}}()
    # Loop for T from 1 to a maximum value given by the user. A maximum value is needed since the privacy policy could be insourmantable for some delays with low frequencies
    for T in Ts # 1:max_T
        # Compute date_inizio and date_fine
        date_inizio = Date[]
        date_fine = Date[]
        if T != 0
            T_days = Dates.Day(T)
            increments  = ceil(period / T_days)
            date_inizio = [date_start + (i-1)*T_days + Day(i-1) for i in 1:(increments+1)]
            date_fine   = [date_start + i*T_days + Day(i-1) for i in 1:(increments+1)]
            date_fine[end] = date_fine[end] <=  date_end ? date_fine[end] : date_end
        else
            date_inizio = collect(date_start:Day(1):date_end)
            date_fine   = collect(date_start:Day(1):date_end)
        end
        # println("T = $T \n\ndate_inizio = $date_inizio \n\ndate_fine = $date_fine ")

        # Loop over lines
        @showprogress 1 for line in eachrow(line_list)
            # Convert the line in a OrderedDict like col_name=>date and sort it by date
            dates_dct = sort(OrderedDict(replace(col_name, "data_" => "") => date for (col_name,date) in zip(names(line), line) if !is_MVP(date) && col_name ∉ ["ID", "classe_eta"]), byvalue = true)
            # Extract age_class and status
            age_class = line.classe_eta
            status = is_MVP(line.data_IS) && is_MVP(line.data_AO) && is_MVP(line.data_AI) ? "Asintomatici" : "Sintomatici"
            # Loop over successive pairs of dates
            for (i,(event_1, date_1)) in enumerate(collect(dates_dct)[1:(end-1)])
                for (event_2, date_2) in collect(dates_dct)[(i+1):end]
                    # Construct the name of the delay
                    delay_name = "T_$(event_1)_$event_2"
                    # If the dataframe relative to this delay is already in delays_T_ageclass_status_dct, update it...
                    if delay_name in keys(delays_T_ageclass_status_dct) && T in keys(delays_T_ageclass_status_dct[delay_name]) && age_class in keys(delays_T_ageclass_status_dct[delay_name][T]) && status in keys(delays_T_ageclass_status_dct[delay_name][T][age_class])
                        delay_df = delays_T_ageclass_status_dct[delay_name][T][age_class][status]
                        # Get indexes of all rows in delay_df s.t. date_1 is between data_inizio and date_fine
                        idxs = findall(x -> x[1] <= date_1 <= x[2] , collect(zip(delay_df.data_inizio, delay_df.data_fine)))
                        # Get index of row (among the ones selected by idxs) so that date_2-date_1 == delay_df.delay
                        idx = findfirst(x -> x == Dates.value(date_2-date_1), delay_df.delay)
                        # println("idxs = $idxs, \tidx = $idx")

                        # If idx exists, increment frequenza_delay value of such row by 1...
                        if !isnothing(idx)
                            delays_T_ageclass_status_dct[delay_name][T][age_class][status][idx, "frequenza_delay"] += 1
                        # Else add a row
                        else
                            push!(delays_T_ageclass_status_dct[delay_name][T][age_class][status], get_row(date_1, date_2, date_inizio, date_fine))
                        end
                        # if date_1 in delay_df.data_inizio && Dates.value(date_2 - date_1) in delay_df.delay
                        #     delay_df[(delay_df.data_inizio .== date_1) .& (delay_df.delay .== Dates.value(date_2 - date_1)), "frequenza_delay" ] .+= 1
                        # else
                        # push!(delay_df, (date_1, date_1 + Day(T - 1), Dates.value(date_2 - date_1), 1))
                        # end
                    # ...otherwise, create the Dicts and OrderedDicts as needed
                    elseif delay_name in keys(delays_T_ageclass_status_dct) && T in keys(delays_T_ageclass_status_dct[delay_name]) && age_class in keys(delays_T_ageclass_status_dct[delay_name][T])
                        push!(delays_T_ageclass_status_dct[delay_name][T][age_class], status => DataFrame(data_inizio = Date[] , data_fine = Date[],  delay = Int64[], frequenza_delay = Int64[]))

                        delay_df = delays_T_ageclass_status_dct[delay_name][T][age_class][status]
                        # Get indexes of all rows in delay_df s.t. date_1 is between data_inizio and date_fine
                        idxs = findall(x -> x[1] <= date_1 <= x[2] , collect(zip(delay_df.data_inizio, delay_df.data_fine)))
                        # Get index of row (among the ones selected by idxs) so that date_2-date_1 == delay_df.delay
                        idx = findfirst(x -> x == Dates.value(date_2-date_1), delay_df.delay)

                        # If idx exists, increment frequenza_delay value of such row by 1...
                        if !isnothing(idx)
                            delays_T_ageclass_status_dct[delay_name][T][age_class][status][idx, "frequenza_delay"] += 1
                        # Else add a row
                        else
                            push!(delays_T_ageclass_status_dct[delay_name][T][age_class][status], get_row(date_1, date_2, date_inizio, date_fine))
                        end
                        #push!(delays_T_ageclass_status_dct[delay_name][T][age_class][status], (date_1, date_1 + Day(T - 1), Dates.value(date_2 - date_1), 1))
                    
                    elseif delay_name in keys(delays_T_ageclass_status_dct) && T in keys(delays_T_ageclass_status_dct[delay_name])
                        status_dct = Dict(status => DataFrame(data_inizio = Date[] , data_fine = Date[],  delay = Int64[], frequenza_delay = Int64[]))

                        push!(delays_T_ageclass_status_dct[delay_name][T], age_class => status_dct)
                        # push!(delays_T_ageclass_status_dct[delay_name][T][age_class][status], (date_1, date_1 + Day(T - 1), Dates.value(date_2 - date_1), 1))

                        delay_df = delays_T_ageclass_status_dct[delay_name][T][age_class][status]
                        # Get indexes of all rows in delay_df s.t. date_1 is between data_inizio and date_fine
                        idxs = findall(x -> x[1] <= date_1 <= x[2] , collect(zip(delay_df.data_inizio, delay_df.data_fine)))
                        # Get index of row (among the ones selected by idxs) so that date_2-date_1 == delay_df.delay
                        idx = findfirst(x -> x == Dates.value(date_2-date_1), delay_df.delay)

                        # If idx exists, increment frequenza_delay value of such row by 1...
                        if !isnothing(idx)
                            delays_T_ageclass_status_dct[delay_name][T][age_class][status][idx, "frequenza_delay"] += 1
                        # Else add a row
                        else
                            push!(delays_T_ageclass_status_dct[delay_name][T][age_class][status], get_row(date_1, date_2, date_inizio, date_fine))
                        end

                    elseif delay_name in keys(delays_T_ageclass_status_dct)
                        
                        ageclass_status_dct = OrderedDict(age_class => Dict(status => DataFrame(data_inizio = Date[] , data_fine = Date[],  delay = Int64[], frequenza_delay = Int64[])) )

                        push!(delays_T_ageclass_status_dct[delay_name], T => ageclass_status_dct)

                        delay_df = delays_T_ageclass_status_dct[delay_name][T][age_class][status]
                        # Get indexes of all rows in delay_df s.t. date_1 is between data_inizio and data_fine
                        idxs = findall(x -> x[1] <= date_1 <= x[2] , collect(zip(delay_df.data_inizio, delay_df.data_fine)))
                        # Get index of row (among the ones selected by idxs) so that date_2-date_1 == delay_df.delay
                        idx = findfirst(x -> x == Dates.value(date_2-date_1), delay_df.delay)

                        # If idx exists, increment frequenza_delay value of such row by 1...
                        if !isnothing(idx)
                            delays_T_ageclass_status_dct[delay_name][T][age_class][status][idx, "frequenza_delay"] += 1
                        # Else add a row
                        else
                            push!(delays_T_ageclass_status_dct[delay_name][T][age_class][status], get_row(date_1, date_2, date_inizio, date_fine))
                        end
                    
                    elseif !(delay_name in keys(delays_T_ageclass_status_dct))
                        # data_inizio = [date_start + ]
                        T_ageclass_status_dct = OrderedDict( T => OrderedDict(age_class => Dict(status => DataFrame(data_inizio = Date[] , data_fine = Date[],  delay = Int64[], frequenza_delay = Int64[]))))
                        push!(delays_T_ageclass_status_dct, delay_name => T_ageclass_status_dct)

                        push!(delays_T_ageclass_status_dct[delay_name][T][age_class][status], get_row(date_1, date_2, date_inizio, date_fine) )
                        # push!(delays_T_ageclass_status_dct[delay_name][T][age_class][status], (date_1, date_1 + Day(T - 1), Dates.value(date_2 - date_1), 1))
                    else
                        error("The hypothesized structure of the output dictionary is wrong. Please check it.")
                    end
                end
            end
        end

        # Check for NA
        # for delay_name in keys(delays_T_ageclass_status_dct)
        #     for T in keys(delays_T_ageclass_status_dct[delay_name])
        #         for age_class in keys(delays_T_ageclass_status_dct[delay_name][T])
        #             for status in keys(delays_T_ageclass_status_dct[delay_name][T][age_class])
        #                 if !isnothing(findfirst( x -> 0 <x<=3, delays_T_ageclass_status_dct[delay_name][T][age_class][status].frequenza_delay))
        #                     again = true
        #                 end
        #             end
        #         end
        #     end
        # end    
    end

    # Sort T OrderedDict by T, sort age_class OrderedDict by age_class sort dataframes by date
    for delay_name in keys(delays_T_ageclass_status_dct)
        sort!(delays_T_ageclass_status_dct[delay_name], byvalue = false)
        for T in keys(delays_T_ageclass_status_dct[delay_name])
            sort!(delays_T_ageclass_status_dct[delay_name][T], byvalue = false)
            for age_class in keys(delays_T_ageclass_status_dct[delay_name][T])
                for status in keys(delays_T_ageclass_status_dct[delay_name][T][age_class])
                    sort!(delays_T_ageclass_status_dct[delay_name][T][age_class][status],[:data_inizio])
                end
            end
        end
    end

    # Fit parametric distributions
    if !isempty(`distributions_types`)
        for delay_name in keys(delays_T_ageclass_status_dct) #@threads
            for T in keys(delays_T_ageclass_status_dct[delay_name]) 
                for age_class in keys(delays_T_ageclass_status_dct[delay_name][T])
                    for (status,dataframe) in collect(delays_T_ageclass_status_dct[delay_name][T][age_class])
                        # Preallocate array of estimated distributions over given time delay
                        fitted_distributions = []
                        sorted_df = sort(dataframe, [:delay])
                        delays = sorted_df.delay[1]:sorted_df.delay[end]
                        tot = sum(sorted_df.frequenza_delay)
                        # Preallocate array frequencies of every delay value
                        frequencies = Float64[]
                        sizehint!(frequencies, length(delays) )
                        # Compute frequencies
                        for delay in delays
                            idxs = findall(x -> x == delay, sorted_df.delay)
                            !isnothing(idxs) ? push!(frequencies, sum(sorted_df.frequenza_delay[idxs] ./ tot) ) : push!(frequencies, 0 )
                        end

                        # Compute quantiles
                        quantiles = [quantile(dataframe.delay, q ) for q in (0.05, 0.25, 0.5, 0.75, 0.95)]

                        # Compute best initial parameters values for all those distributions whose relations moments-parameters are invertible, otherwise use Distributions.jl's initialization.
                        for distribution_type in distributions_types
                            initial_parameters_values = Float64[]
                            upper_bounds = upper_lower_bounds[distribution_type][2]
                            lower_bounds = upper_lower_bounds[distribution_type][1]
                            println("distribution_type = $distribution_type, upper_bounds = $upper_bounds, lower_bounds = $lower_bounds ")
                            num_params = length(params(distribution_type()))
                            if haskey(distributions_parameters_formula, distribution_type)
                                initial_parameters_values = float.([formula(dataframe.delay) for formula in values(distributions_parameters_formula[distribution_type])])
                                println("distribution_type = $distribution_type\t initial_parameters_values = $initial_parameters_values\t dataframe.delay = $(dataframe.delay) ")
                            else
                                initial_parameters_values = float.(params(distribution_type()))
                            end

                            # Fit distribution
                            try
                                if loss == :pdf
                                    push!(fitted_distributions,  DistributionsUtils.fit_distribution_optim( distribution_type, Dict((Distributions.pdf, (float(delay_value),)) => freq for (delay_value, freq) in zip(delays, frequencies) ), initial_parameters_values, (lower_bounds, upper_bounds), optim_algorithm , Optim.Options( time_limit=time_limit) ) ) # 1000 sec on synthetic single-core
                                elseif loss == :quantile
                                    push!(fitted_distributions,  DistributionsUtils.fit_distribution_optim( distribution_type, Dict((Distributions.quantile, (q,)) => delay_value for (q, delay_value) in zip((0.05, 0.25, 0.5, 0.75, 0.95), quantiles ) ), initial_parameters_values, (lower_bounds, upper_bounds), optim_algorithm , Optim.Options( time_limit=time_limit) ) ) #iterations=100, # 900 sec on synthetic single-core
                                elseif loss == :both
                                    push!(fitted_distributions,  DistributionsUtils.fit_distribution_optim( distribution_type, merge(Dict((Distributions.pdf, (float(delay_value),)) => freq for (delay_value, freq) in zip(delays, frequencies) ), Dict((Distributions.quantile, (q,)) => delay_value for (q, delay_value) in zip((0.05, 0.25, 0.5, 0.75, 0.95), quantiles ) )), initial_parameters_values, (lower_bounds, upper_bounds), optim_algorithm , Optim.Options( time_limit=time_limit) ) ) # 1100 sec on synthetic single-core
                                end
                                    
                                println("distribution = ", distribution_type, " outcome = success")
                            catch e
                                println("distribution = ", distribution_type, " outcome = $e, params = $initial_parameters_values ")
                                #println(e)
                                continue
                            end
                        end

                        # Construct output dictionary
                        if haskey(name_distributions_dct, delay_name ) && haskey(name_distributions_dct[delay_name], T ) && haskey(name_distributions_dct[delay_name][T], age_class) 

                            push!(name_distributions_dct[delay_name][T][age_class] , status => fitted_distributions )

                        elseif haskey(name_distributions_dct, delay_name ) && haskey(name_distributions_dct[delay_name], T )

                            push!(name_distributions_dct[delay_name][T] , age_class => Dict(status => fitted_distributions ))

                        elseif haskey(name_distributions_dct, delay_name )

                            push!(name_distributions_dct[delay_name] , T => OrderedDict(age_class => Dict(status => fitted_distributions )))

                        else
                            push!(name_distributions_dct , delay_name => OrderedDict( T => OrderedDict(age_class => Dict(status => fitted_distributions ))))
                        end

                    end
                    
                end
            end
        end
    end

    # Get empirical frequencies distributions
    delays_T_ageclass_status_freq_dct = deepcopy(delays_T_ageclass_status_dct)
    if get_frequencies
        for delay_name in keys(delays_T_ageclass_status_freq_dct)
            for T in keys(delays_T_ageclass_status_freq_dct[delay_name])
                for age_class in keys(delays_T_ageclass_status_freq_dct[delay_name][T])
                    for dataframe in values(delays_T_ageclass_status_freq_dct[delay_name][T][age_class])
                        for data_inizio_dataframe in groupby(dataframe, [:data_inizio])
                            data_inizio_dataframe.binned_frequenza_delay = data_inizio_dataframe.frequenza_delay ./ sum(data_inizio_dataframe.frequenza_delay)
                        end
                        dataframe.frequenza_delay = dataframe.frequenza_delay ./ sum(dataframe.frequenza_delay)
                    end
                end
            end
        end
    end

    # Apply privacy policy
    if privacy_policy
        for T_ageclass_status_dataframe_dct in values(delays_T_ageclass_status_dct)
            for age_class_status_dataframe_dct in values(T_ageclass_status_dataframe_dct)
                for status_dataframe_dct in values(age_class_status_dataframe_dct)
                    for dataframe in values(status_dataframe_dct)
                        apply_privacy_policy!(dataframe[!,"frequenza_delay"])
                    end
                end
            end
        end 
    end


    # Return dictionary of time delays 
    if get_frequencies && !isempty(distributions_types)
        return delays_T_ageclass_status_dct, delays_T_ageclass_status_freq_dct, name_distributions_dct
    elseif get_frequencies && isempty(distributions_types)
        return delays_T_ageclass_status_dct, delays_T_ageclass_status_freq_dct
    else 
        return delays_T_ageclass_status_dct
    end
end

### TIME DELAYS SAVING ###

"""
    save_delays_as_csv(delays::Dict{String, OrderedDict{Int64, OrderedDict{Int64, Dict{String,DataFrame}}}}, folder::String)

Save all the dataframes contained inside the output of `get_delays` (here `delays`) as .csv files inside `folder`. The naming convention of the resulting saved files is the one described in the manual.
"""
function save_delays_as_csv(delays::Dict{String, OrderedDict{Int64, OrderedDict{Int64, Dict{String,DataFrame}}}}, folder::String;extra_identifier = "")

    for delay_name in keys(delays)
        for T in keys(delays[delay_name])
            for age_class in keys(delays[delay_name][T])
                for status in keys(delays[delay_name][T][age_class])
                    df_name = "Distribuzione_$(delay_name)_$(age_class)_$(status)_$(T)"*extra_identifier*".csv"
                    CSV.write(joinpath(folder,df_name), delays[delay_name][T][age_class][status])
                end
            end
        end
    end
end


"""
    parse_saved_dict(saved_dict::String)

Parse the estimated distributions from `get_delays` variable saved as a string to make it compatible with metaprogramming's `eval`. To be used as `txt_parse_function` argument to `load_julia_variable`.
"""
function parse_saved_dict(saved_dict::String)
    output = deepcopy(saved_dict)
    for replacement in ("α="=> "", "θ=" => "", "r=" => "", "p=" => "", "μ=" =>"", "σ=" => "")
        output = replace(output,replacement)
    end
    return output
end