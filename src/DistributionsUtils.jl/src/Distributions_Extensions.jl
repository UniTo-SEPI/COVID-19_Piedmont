# an obsolete script. Its functionalities are already offered by Bijectors.jl, so we swithced to it.
# We anyway decided to keep it, as it contains maybe useful insights for future work.

# BASE EXTENSIONS #

"""
    length(::InterpKDE)

Returns 0 by default.
"""
# Base.length(::InterpKDE) = 0 
"""
    Base.length(::Symbol)

Returns 0 by default.
"""
# Base.length(::Symbol)    = 0 
     
# DISTRIBUTIONS.JL EXTENSIONS #

# useful links
# Integration with QuadGK :https://juliamath.github.io/QuadGK.jl/latest/
# Example on the discourse : https://discourse.julialang.org/t/help-with-creating-a-custom-distribution/13229

# struct that manages the distribution of the inverse of a random variable, even when this is not analitically defined. useful if we want to perform ABC calibration with literature informed priors ( remember that  due to the broader intervals that priors of not inverted parameters imply, using recipricated parameters in the model is not recommended)
"""
    distribution_of_inverse{T}

Struct that manages the distribution of the inverse of a random variable, even when this is not analitically defined.
"""
mutable struct distribution_of_inverse{T} <: ContinuousUnivariateDistribution
    "The distribution this struct represents the inverse of"
    distrib::T
    #param::Symbol
end


# struct that wraps an InterpKDE of KernelDensity.jl into a UnivariateDistribution form Distributions.jl
"""
    distribution_from_InterpKDE <: ContinuousUnivariateDistribution

Struct that wraps an InterpKDE of KernelDensity.jl into a UnivariateDistribution form Distributions.jl
"""
mutable struct distribution_from_InterpKDE <: ContinuousUnivariateDistribution
    "The InterpKDE from KernelDensity.jl"
    ik::InterpKDE
    "The InterpKDE mean, precomputed for better performance"
    mean::Float64
    "The InterpKDE var, precomputed for better performance"
    var::Float64
    "The InterpKDE kurtosis, precomputed for better performance"
    kurtosis::Float64
    #param::Symbol
    
    function distribution_from_InterpKDE(ik::InterpKDE) #, param::Symbol
        mean = quadgk(y -> y * pdf(ik, y), -Inf, Inf)[1]
        var =  quadgk(y -> ((y-mean)^2) * pdf(ik, y), -Inf , Inf )[1]
        kurtosis = quadgk(y -> ((y-mean)^4) * pdf(ik, y), -Inf , Inf )[1] / (var^2)
        return new(ik, mean, var, kurtosis) #param
    end

end


# A struct that ecapsulates an array of distributions
struct array_of_distributions <: ContinuousUnivariateDistribution
    distributions::Array{Distribution{Univariate,Continuous},1}
end


# a struct that tricks julia into thinking that a float is a distribution 
# mutable struct point_distribution <: ContinuousUnivariateDistribution
#     point::Float64
# end
mutable struct point_distribution{T} <: ContinuousUnivariateDistribution
    point::T
end


#= # a struct that wraps the BallTreeDensities to later define a rand(::kde_prior) which is turing compatible
mutable struct kde_prior <: ContinuousUnivariateDistribution
    prior::BallTreeDensity
end =#




# Here follows the implementatio of all methods required by Distributions.jl . See https://juliastats.org/Distributions.jl/stable/extends/



# minimum
minimum(d::distribution_from_InterpKDE) = -Inf
minimum(d::point_distribution) = d.point
# minimum(d::kde_prior) = -Inf


# maximum
maximum(d::distribution_from_InterpKDE) = Inf
maximum(d::point_distribution) = d.point
# maximum(d::kde_prior) = Inf




# pdf 
pdf(d::distribution_of_inverse, x::Float64)  = pdf(d.distrib, 1/x) * (1/(x^2))
pdf(d::distribution_from_InterpKDE, x::Real) = pdf(d.ik,x)



# logpdf
logpdf(d::distribution_from_InterpKDE, x::Real) = log(pdf(d.ik,x))
logpdf(d::array_of_distributions, x::Real) = [log(pdf(dist,x)) for dist in  d.distributions]
# logpdf(d::kde_prior,  x) = log(d.prior([x])[1])


# rand ( extraction)
rand(d::distribution_of_inverse; eps = 10^-4, iterations = 200, decr = 10.0) = quantile(d, Base.rand(Uniform(0.0 , 1.0)); eps = eps, iterations = iterations, decr= decr)
rand(d::distribution_from_InterpKDE; eps = 10^-4, iterations = 200, decr = 10.0) = quantile(d, Base.rand(Uniform(0.0 , 1.0) ); eps = eps, iterations = iterations, decr= decr)
rand(d::array_of_distributions) = rand.([dist for dist in d.distributions])
#rand(d::ordered_multivariate)  =  [couple[2] for couple in sort(collect(zip(d.order, vcat(rand.([distribution for distribution in d.distributions])...))); by=first)] 
rand(d::point_distribution) = d.point
# rand(d::kde_prior) = rand(d.prior)[1]


# cdf
cdf(d::distribution_of_inverse, x::Real)     =  quadgk(y -> pdf(d, y), -Inf, x)[1]
cdf(d::distribution_from_InterpKDE, x::Real) = quadgk(y -> pdf(d, y), minimum(d), x)[1] #( println("Parameter: ", d.param," integrating from ", minimum(d)," to $x") ; quadgk(y -> pdf(d, y), minimum(d), x)[1])



# sampler
sampler(d::distribution_from_InterpKDE) = d



# compute quantile in a numerical approximation, with convergence guarantee
function quantile(d::distribution_of_inverse, q::Real; eps = 10^-4, iterations = 200, decr = 10.0)

    # start from mean
    x = d.mean
    # heuristically set initial step size
    cdf_value = cdf(d,x)
    incr = 0.5 #(1.0 / d.kurtosis) *abs(q - cdf_value) 
    
    # print quantile search parameters
    println( d.param," x = $x", " incr  = $incr", " var(d) = ", var(d), " cdf_value = $cdf_value")
    
    diff = q - cdf_value
    i = 0
    approximation_history = []
    while(abs(diff) >= eps && i < iterations)
        if diff > 0
            x += incr
            diff =  q - cdf(d,x)
            i+= 1
            #println(diff," ", incr)
            push!(approximation_history, Dict("diff" => diff, "incr" => incr, "x" => x))
            
            if diff < 0
                incr = incr/decr
            end
#             else
#                 if length()
#                     incr *= abs(1.0/(abs(diff) - abs(approximation_history[end-1]["diff"]) ))
#             end
        else
            x -= incr
            diff =  q - cdf(d,x)
            i+= 1
            push!(approximation_history, Dict("diff" => diff, "incr" => incr, "x" => x))
            if diff > 0 
                incr = incr/decr
            end
#             else
#                 incr *= abs(1.0/(diff - approximation_history[end-1]["diff"] ))
#             end
            
        end
    end
    if i == iterations
        println("Inverse " * String(d.param) *" $q quantile estimation did not converge. Please refer to the last part of the approximation_history below to increase the number of iterations or the initial step size. Returning best value")
        last_part = [hist for hist in approximation_history if hist["diff"] == sort(approximation_history, by = y -> abs(y["diff"]))[1]["diff"] ]
        ret = sort(last_part, by = y -> y["incr"])[1]["x"]
        #println("last part of approximation_history: \n", last_part, "\n","returning ", ret)
        return ret
    else
        #println("Inverse " *  String(d.param) * " $q quantile estimation converged. Returning ",x )
        return x
    end
    
    
end


function quantile(d::distribution_from_InterpKDE, q::Real; eps = 10^-4, iterations = 200, decr = 10.0)

    # start from mean
    x = d.mean
    # heuristically set initial step size
    cdf_value = cdf(d,x)
    incr = 0.05 #(1.0 / d.kurtosis) *abs(q - cdf_value) 
    
    # print quantile search parameters
    #println( d.param," x = $x", " incr  = $incr", " var(d) = ", d.var, " cdf_value = $cdf_value", " kurtosis = ",  d.kurtosis )
    
    diff = q - cdf_value
    i = 0
    approximation_history = []
    while(abs(diff) >= eps && i < iterations)
        if diff > 0
            x += incr
            diff =  q - cdf(d,x)
            i+= 1
            #println(diff," ", incr)
            push!(approximation_history, Dict("diff" => diff, "incr" => incr, "x" => x))
            
            if diff < 0
                incr = incr/decr
            end
#             else
#                 if length()
#                     incr *= abs(1.0/(abs(diff) - abs(approximation_history[end-1]["diff"]) ))
#             end
        else
            x -= incr
            diff =  q - cdf(d,x)
            i+= 1
            push!(approximation_history, Dict("diff" => diff, "incr" => incr, "x" => x))
            if diff > 0 
                incr = incr/decr
            end
#             else
#                 incr *= abs(1.0/(diff - approximation_history[end-1]["diff"] ))
#             end
            
        end
    end
    if i == iterations
        println("Inverse " * String(d.param) *" $q quantile estimation did not converge. Please refer to the last part of the approximation_history below to increase the number of iterations or the initial step size. Returning best value")
        last_part = [hist for hist in approximation_history if hist["diff"] == sort(approximation_history, by = y -> abs(y["diff"]))[1]["diff"] ]
        ret = sort(last_part, by = y -> y["incr"])[1]["x"]
        #println("last part of approximation_history: \n", last_part, "\n","returning ", ret)
        #println( d.param," x = $x", " incr  = $incr", " var(d) = ", d.var, " cdf_value = $cdf_value", " kurtosis = ",  d.kurtosis )
        return ret
    else
        #println("Inverse " *  String(d.param) * " $q quantile estimation converged. Returning ",x )
        return x
    end
    
    
end


quantile(d::point_distribution, x::Float64)  = d.point

# evaluate mean of distribution_of_inverse
function mean(d::distribution_of_inverse)
    try
        return quadgk(x -> pdf(d, x)*x, -Inf, Inf)
    catch e
        return quadgk(x -> pdf(d, x)*x,  0.0 + eps(Float64), Inf)
    end
end

mean(d::point_distribution) = d.point


# evaluate variance of distribution

# insupport
insupport(d::distribution_from_InterpKDE, x::Real)  = minimum(d) <=  x <= maximum(d)

# cf ( charateristic function : https://en.wikipedia.org/wiki/Characteristic_function_(probability_theory))
cf(d::ContinuousUnivariateDistribution, t::Real) = quadgk(x -> exp(im*t*x)*pdf(d,x), minimum(d), maximum(d))[1]

# KernelDensity.jl EXTENSIONS #

kernel_dist(::Type{Truncated{Normal{Float64},Continuous,Float64}}, w::Real ) = (s = w/std(truncated(Normal(0.0,1.0), 0.0, Inf)) ; truncated(Normal(0.0, s), 0.0, Inf))
