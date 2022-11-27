# Summary Statistics distribution parameter inference (estimation)

# see https://blogs.sas.com/content/iml/2018/03/07/fit-distribution-matching-quantile.html

"""
    loss_closure_distribution_fitting(distribution::UnionAll ,objectives::Dict{ <: Tuple{Function,Tuple{Vararg{Float64}}}, Float64 }, method::Symbol)

Return the L2 loss function for summary statistics distribution parameters estimation. 

The loss performs an L2-sum over all the constraint specified.
"""
function loss_closure_distribution_fitting(distribution::Type{<:Distribution{Univariate}} ,objectives::Dict{ <: Tuple{Function,Tuple{Vararg{Float64}}}, Float64 }, method::Symbol)
    
    return function loss_distribution(theta::Vector{Float64})

        objectives_values = Float64[]

        
        for (objective, args) in keys(objectives)
            try
                push!(objectives_values,  objective(distribution(theta...), args...) )
            catch e
                push!(objectives_values,  Inf )
            end
        end


        if method == :optim
            return sum(abs2, objectives_values .- collect(values(objectives)))
        end

    end



end


"""
    fit_distribution_optim( distribution::Type{<:Distribution{Univariate}}, objectives::Dict{ <: Tuple{Function,Tuple{Vararg{Float64}}}, Float64 }, initial_parameters_values::Vector{Float64}, bounds::Tuple{Vector{Float64},Vector{Float64}},  optim_algorithm::OA, optim_options::Optim.Options   ) where {OA <: Optim.AbstractOptimizer}

Fit `distribution` to the constraints `objectives`. 

This method is analogous to `fit_distributions`, except it works for one distribution at a time.

See also [`fit_distributions`](@ref) to see a description of all the arguments.
"""
function fit_distribution_optim( distribution::Type{<:Distribution{Univariate}}, objectives::Dict{ <: Tuple{Function,Tuple{Vararg{Float64}}}, Float64 }, initial_parameters_values::Vector{Float64}, bounds::Tuple{Vector{Float64},Vector{Float64}},  optim_algorithm::OA, optim_options::Optim.Options   ) where {OA <: Optim.AbstractOptimizer}

    loss::Function = loss_closure_distribution_fitting(distribution, objectives, :optim)

    result_Optim = @time Optim.optimize(loss, bounds[1], bounds[2], initial_parameters_values, Optim.Fminbox(optim_algorithm),  optim_options)

    return (distribution(result_Optim.minimizer...), result_Optim.minimum)

end


"""
    fit_distributions(distributions::Tuple{Vararg{UnionAll,N}}, objectives::Dict{ <: Tuple{Function,Tuple{Vararg{Float64}}}, Float64 }, initial_parameters_valuess::Tuple{Vararg{Vector{Float64},N}}, boundss::Tuple{Vararg{Tuple{Vector{Float64},Vector{Float64}},N}}; optim_algorithm::OA = BFGS(), optim_options::Optim.Options =  Optim.Options( iterations=100, time_limit=100), return_best::Bool = true, trace::Bool = true ) where {N, OA <: Optim.AbstractOptimizer}

Fit all distributions contained in `distributions` to the constraints `objectives`. A constraint is specified as a key-value pair of `objectives`, where the key is a 2-tuple where the first element is a function that takes a Distribution{Univariate} as the first argument, and optionally extra arguments following the first. The second element of the 2-tuple is a Tuple{Vararg{Float64}}, that will be passed as args... to the function after the distribution. The values of the `objectives` Dict are the target values for  each objective (as specified by the corresponding key). Initial parameters values are specified via `initial_parameters_values` (one vector per distribution), and their bounds via `bounds`, one tuple of 2 vectors per distribution, where first vector is the vector of lower bounds, the second is the vector of upper bounds. `optim_algorithm` specifies the algorithm to use, `optim_options` must be of type Optim.Options. If `return_best` is true, then only the best fitted distribution is returned, otherwise an array of 2-tuple is returned, where the first element of each 2-tuple is a fitted distribution, and the second is its final L2 loss. `trace` (true/false) controls whether to print calibration info or not. 

"""
function fit_distributions(distributions::Tuple{Vararg{UnionAll,N}}, objectives::Dict{ <: Tuple{Function,Tuple{Vararg{Float64}}}, Float64 }, initial_parameters_valuess::Tuple{Vararg{Vector{Float64},N}}, boundss::Tuple{Vararg{Tuple{Vector{Float64},Vector{Float64}},N}}; optim_algorithm::OA = BFGS(), optim_options::Optim.Options =  Optim.Options( iterations=100, time_limit=100), return_best::Bool = true, trace::Bool = true ) where {N, OA <: Optim.AbstractOptimizer}

    results = Tuple{<:Distribution{Univariate},Float64}[]

    for (distribution,initial_parameters_values,bounds) in zip(distributions,initial_parameters_valuess,boundss)
        push!(results, fit_distribution_optim(distribution, objectives, initial_parameters_values, bounds, optim_algorithm, optim_options ))
    end

    if trace
        println("\n\nfit_distributions results:")
        for result in results
            println("Fitted ", result[1], "\t with loss = ", result[2])
        end
    end

    if return_best
        return sort(results; by = x -> x[2] )[1][1]
    else
        return results
    end


end