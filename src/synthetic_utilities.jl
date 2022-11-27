##########################
### SYNTHETIC UTILITIES ##
##########################

"""
    load_csv(path::String)

Load .csv file at `path` and return it as a DataFrame.
"""
load_csv(path::String) = CSV.read(path, DataFrame)

"""
    rand_days(d::Distribution)

Round a sample from `d` to an Int64 and return it as a number of Day(s).
"""
rand_days(d::Distribution) = Day(round(Int64, rand(d)))

"""
    remove_MVP(x,is_MVP::F) where {F <: Function}

Remove all MVP values from x (which is assumed to be iterable).
"""
remove_MVP(x, is_MVP::F) where {F<:Function} = [el for el in x if !is_MVP(el)]

"""
    check_max(x...;MVP, is_MVP::F) where {F <: Function}

Return the maximum of `x`, if its length is greater than 0 once MVPs have been removed, otherwise return MVP.
"""
function check_max(x...; MVP, is_MVP::F) where {F<:Function}
    x_no_MVP = remove_MVP(x, is_MVP)
    return length(x_no_MVP) > 0 ? maximum(x_no_MVP) : MVP
end

### PARAMETER AGGREGATION ###

"""
Function that turns an N-stratified dataset in a n-stratified one.
Usage: 
- `column_aggregations` is the array of aggregations of the dataframe column to desired age classes
- `column_population_aggregations` is the array of aggregations of the `population` to the desired age classes, but limited by the dataframe column aggregation
- `population_aggregations` is the array of aggregations of the aggregated `population` w.r.t `column_population_aggregations` to match the desired age classes
Use something like `column_aggregations` = [1:2, 3:4, 5:6] for pure aggregations, or `column_aggregations` = [1:2, 3:4, 5, 5 , 6:7] to have both aggregations and disaggregations (same goes for `column_population_aggregations` and `population_aggregations`).
"""
function from_N_to_n(column::String, column_aggregations, population::Array{Int64}, population_aggregations; path="", df=DataFrame(), column_population_aggregations=[])

    if path != ""
        dataframe = CSV.read(path, DataFrame)
    elseif df != DataFrame()
        dataframe = df
    else
        error("Please specify the `df` argument or the `path` argument")
    end

    if length(column_population_aggregations) > 0
        aggregated_population = [sum(population[agg]) for agg in column_population_aggregations]
    else
        aggregated_population = population
    end

    parameters::Array{Float64,1} = dataframe[!, column]
    aggregated_parameters = Array{Float64,1}(undef, length(column_aggregations))
    for (i, (col_agg, pop_agg)) in enumerate(zip(column_aggregations, population_aggregations))
        aggregated_parameters[i] = sum(parameters[col_agg] .* aggregated_population[pop_agg]) / sum(aggregated_population[pop_agg])
    end
    return aggregated_parameters

end

### PROCESS SYNTHETIC DATASET ###

"""
    get_synthetic_dataset(confirmed_incidences_by_age::DataFrame; λ_SP_prior::Distribution, λ_TH_prior::Distribution, λ_H_priors::Vector{<:Distribution}, λ_ICU_priors::Vector{<:Distribution}, λ_R_prior::Distribution, λ_Q_prior::Distribution,  symptomatic_fraction::Vector{Float64}, quarantena_precauzionale_fraction::Float64 = 0.3, hospitalization_rate::Vector{Float64}, ICU_rate::Vector{Float64}, infection_fatality_ratio::Vector{Float64}, age_classes_string_integer_dct::Dict{String,Int64}, MVP, is_MVP::F   ) where { F <: Function}

For every count in `confirmed_incidences_by_age` produce a line of a dataset equivalent to `line_list_ricoveri_quarantene_fp_is_lim` from main.jl that has positivity date equal to the date of the count, and all the other dates are sampled using the transitions and delays distributions given as inputs.
"""
function get_synthetic_dataset(confirmed_incidences_by_age::DataFrame; λ_SP_prior::Distribution, λ_TH_prior::Distribution, λ_H_priors::Vector{<:Distribution}, λ_ICU_priors::Vector{<:Distribution}, λ_R_prior::Distribution, λ_Q_prior::Distribution, symptomatic_fraction::Vector{Float64}, quarantena_precauzionale_fraction::Float64=0.3, hospitalization_rate::Vector{Float64}, ICU_rate::Vector{Float64}, rehabilitative_rate::Float64=0.8, infection_fatality_ratio::Vector{Float64}, age_classes_string_integer_dct::Dict{String,Int64}, MVP, is_MVP::F) where {F<:Function}

    # Pre-allocate output
    synthetic_dataset = DataFrame(ID=Int64[], classe_eta=Int64[], data_IS=Union{Date,Missing}[], data_P=Date[], data_IQP=Union{Date,Missing}[], data_FQP=Union{Date,Missing}[], data_IQO=Union{Date,Missing}[], data_FQO=Union{Date,Missing}[], data_AO=Union{Date,Missing}[], data_DO=Union{Date,Missing}[], data_AI=Union{Date,Missing}[], data_DI=Union{Date,Missing}[], data_AR=Union{Date,Missing}[], data_DR=Union{Date,Missing}[], data_G=Union{Date,Missing}[], data_D=Union{Date,Missing}[])

    # Initialize ID counter and set upper bounds for events dates.
    ID = 1
    limit_IS = Date("2020-12-24")
    limit_FQO = Date("2020-12-25")
    limit_AO = Date("2020-12-26")
    limit_DO = Date("2020-12-27")
    limit_AI = Date("2020-12-28")
    limit_DI = Date("2020-12-29")
    limit_AR = Date("2020-12-30")
    limit_DR = Date("2020-12-31")

    # Loop over columns (age_classes)
    for (i, age_class) in enumerate(names(confirmed_incidences_by_age)[2:end])
        # Loop over rows of the individual age classes in which `confirmed_incidences_by_age` is separable
        for date_counts in eachrow(piedmont_confirmed_aggregated_df[!, ["date", age_class]])
            # Loop over each case
            for j in 1:date_counts[age_class]
                # Pre-allocate events dates
                data_P = date_counts.date
                data_IS = MVP
                data_IQP = MVP
                data_FQP = MVP
                data_IQO = MVP
                data_FQO = MVP
                data_AO = MVP
                data_DO = MVP
                data_AI = MVP
                data_DI = MVP
                data_AR = MVP
                data_DR = MVP
                data_G = MVP
                data_D = MVP

                # Assign each date with probability given by the transitions and values given by samples from the delay distributions
                # IS
                if rand() < symptomatic_fraction[i]
                    data_IS = min(data_P + rand_days(λ_SP_prior), limit_IS)
                end
                # QP
                if rand() < quarantena_precauzionale_fraction
                    data_IQP = data_P + rand_days(λ_P_IQP_prior)
                    data_FQP = data_IQP + Day(round(Int64, Dates.value(data_P - data_IQP) * rand()))
                end
                # H
                if rand() < hospitalization_rate[i]
                    data_AO = min(max(data_IS + rand_days(λ_TH_prior), data_P), limit_AO)
                    data_DO = min(data_AO + rand_days(λ_H_priors[i]), limit_DO)
                end

                # ICU
                if rand() < ICU_rate[i]
                    # println("ICU")
                    data_AI = !is_MVP(data_DO) ? data_DO : min(max(data_IS + rand_days(λ_TH_prior), data_P), limit_AI)
                    data_DI = min(data_AI + rand_days(λ_ICU_priors[i]), limit_DI)

                    if rand() < rehabilitative_rate
                        data_AR = data_DI
                        data_DR = min(data_AR + rand_days(λ_R_prior), limit_DR)
                    end
                end

                # QO
                if is_MVP(data_AO) && is_MVP(data_AI)
                    data_IQO = data_P
                    data_FQO = min(data_IQO + rand_days(λ_Q_prior), limit_FQO)
                elseif !is_MVP(data_AO) && data_AO > data_P
                    data_IQO = data_P
                    data_FQO = data_AO
                elseif !is_MVP(data_AI) && data_AI > data_P
                    data_IQO = data_P
                    data_FQO = data_AI
                end

                # G or D
                last_date = check_max(data_FQO, data_DO, data_DI, data_DR; MVP=MVP, is_MVP=is_MVP)
                if rand() < infection_fatality_ratio[i]
                    data_D = last_date
                else
                    data_G = last_date
                end
                push!(synthetic_dataset, (ID, age_classes_string_integer_dct[age_class], data_IS, data_P, data_IQP, data_FQP, data_IQO, data_FQO, data_AO, data_DO, data_AI, data_DI, data_AR, data_DR, data_G, data_D))
                ID += 1
            end
        end
    end
    # Return 
    return synthetic_dataset
end