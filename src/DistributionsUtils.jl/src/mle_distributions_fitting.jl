"""
    function get_oom(value::Float64)

Returns the order of magnitude of `value`.
"""
function get_oom(value::Union{Int64,Float64})
    return floor(Int64,log(value,10))
end

"""
    get_α_β_from_γ_μ_beta_distribution(γ::Float64, μ::Float64)

Returns the (α,β) parameters for the Beta distribution, given the γ and μ parameters. See https://view.officeapps.live.com/op/view.aspx?src=https%3A%2F%2Foup.silverchair-cdn.com%2Foup%2Fbackfile%2FContent_public%2FJournal%2Fcid%2F73%2F3%2F10.1093_cid_ciab100%2F1%2Fciab100_suppl_supplementary_materials.docx%3FExpires%3D1635989042%26Signature%3Ds5H6V3-CYwwP6SUOVzL4mAdv-w8fNF3G0Nef3y2Mn9A7RO580EV6RjE7OBP353cjAMH3z83OubH2BTOXfdtKDSi0i651TvhjIg3-hvQ5qU~9QYHdZizU5~o4hEV3MBcau4LyOpe9B-e7cTMvQjhRSoZfZgvFeFLZLz6DeaZVi3hGO8N5Lm6C3exJtbYv8AspvZb2s-REWultwmBTFOFVJnpgVixiGteIS0iBvdsQqL1XZjLJrdHDAGGy4GHTd9oWfgEW7yJklvcqdxYj4TY7Gt-2qCFo6pljnTYtJvvaodq47zoMU7pUZ7xK-10vVqsYgQ3-sqTEVUhzZwkyO5Oh6A__%26Key-Pair-Id%3DAPKAIE5G5CRDK6RD3PGA&wdOrigin=BROWSELINK.
"""
function get_α_β_from_γ_μ_beta_distribution(γ::Float64, μ::Float64)
    # Evaluate variance
    θ::Float64 = γ/(1-γ)

    # Evaluate shape parameters
    α::Float64    = μ/θ
    β::Float64    = (1-μ)/θ
    
    return (α,β)

end



"""
    fit_all_distributions_jl_distributions(sample::Union{Vector{Float64},Vector{Int64}};distributions_type = Distribution{Univariate,Continuous}, plot_fitted_distributions = false,   histogram_kwargs::NamedTuple = (;), pdf_plot_kwargs::NamedTuple = (;) )

Returns a couple (fitted_distributions,loglikelihoods) that contain respectively all the fitted distributions from Distributions.jl that are subtypes of `distributions_type`  (as indexed by the titles of the plots) and their log likelihoods. The fittings outcomes are plotted if `plot_fitted_distributions` is true, and in that case `histogram_kwargs` and `pdf_plot_kwargs` are respectively passed to the Plots.histogram! function that plots the `sample` and to the StatsPlots.plot function that plots the fitted distribution.
"""
function fit_all_distributions_jl_distributions(sample::Union{Vector{Float64},Vector{Int64}};distributions_type = Distribution{Univariate,Continuous}, plot_fitted_distributions = false,   histogram_kwargs::NamedTuple = (;), pdf_plot_kwargs::NamedTuple = (;) )
    fitted_distributions = Any[]
    for distribution_type in InteractiveUtils.subtypes(distributions_type)
        try
            push!(fitted_distributions,Distributions.fit(distribution_type,sample) )
        catch e
            continue
        end
    end
    
    if plot_fitted_distributions
        for (i,fitted_distribution) in enumerate(fitted_distributions)
            try
                plt = histogram(sample, normalize = :pdf, title = string(i), label = "sample"; histogram_kwargs...);
                plot!(fitted_distribution, label = string(typeof(fitted_distribution)); pdf_plot_kwargs...)
                display(plt)
            catch e
                continue
            end
        end
    end

    loglikelihoods = loglikelihood.(fitted_distributions, Ref(sample))

    return (fitted_distributions,loglikelihoods)
end

"""
    get_best_fitted_distribution(distributions,sample; truncate::Union{Nothing,Tuple{Float64,Float64}} = nothing, plot_best = false, histogram_kwargs::NamedTuple = (;), pdf_plot_kwargs::NamedTuple = (;))

Returns the distribution that achieves maximum loglikelihood among `sample`. The returned best distribution is Distributions.Truncated between `truncated`[1] and `truncated`[2] if `truncated` is not nothing. After possible truncation, the best candidate is plot together with `sample` if `plot_best` is true, and in that case `histogram_kwargs` and `pdf_plot_kwargs` are respectively passed to the Plots.histogram! function that plots the `sample` and to the StatsPlots.plot function that plots the fitted distribution.
"""
function get_best_fitted_distribution(distributions,sample; truncate::Union{Nothing,Tuple{Float64,Float64}} = nothing, plot_best = false, histogram_kwargs::NamedTuple = (;), pdf_plot_kwargs::NamedTuple = (;))
    loglikelihoods = [loglikelihood(distribution, sample) for distribution in  distributions  ] 

    best_candidate  = distributions[argmax(loglikelihoods)]

    if !isnothing(truncate)
        best_candidate = Truncated(best_candidate,truncate... )
    end

    if plot_best
        interval = minimum(sample):10.0^(get_oom(maximum(sample) - minimum(sample))-1):maximum(sample)
        hist = histogram(sample,  normalize = :pdf , label = "sample"; histogram_kwargs... )
        plot!(interval, pdf.(best_candidate, interval), label = string(typeof(best_candidate)); pdf_plot_kwargs... )
        display(hist)
    end

    return best_candidate

end