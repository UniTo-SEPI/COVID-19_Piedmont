# struct that wraps an InterpKDE of KernelDensity.jl into a UnivariateDistribution form Distributions.jl
"""
    distribution_from_InterpKDE <: ContinuousUnivariateDistribution

Struct that wraps an InterpKDE of KernelDensity.jl into a UnivariateDistribution form Distributions.jl

# Fields

- `minimum`: The minimum value of the empirical distribution's support.
- `maximum`: The maximum value of the empirical distribution's support.
- `ik`: The InterpKDE from KernelDensity.jl.
- `mean`: The InterpKDE mean, precomputed for better performance.
- `var`: The InterpKDE var, precomputed for better performance.
- `skewness`: The InterpKDE skewness, precomputed for better performance.
- `kurtosis`: The InterpKDE kurtosis, precomputed for better performance.
- `entropy`: The InterpKDE entropy, precomputed for better performance.
"""
mutable struct distribution_from_InterpKDE <: ContinuousUnivariateDistribution
    "The minimum value of the empirical distribution's support"
    minimum::Float64
    "The maximum value of the empirical distribution's support"
    maximum::Float64
    "The InterpKDE from KernelDensity.jl"
    ik::InterpKDE
    "The InterpKDE mean, precomputed for better performance"
    mean::Float64
    "The InterpKDE var, precomputed for better performance"
    var::Float64
    "The InterpKDE skewness, precomputed for better performance"
    skewness::Float64
    "The InterpKDE kurtosis, precomputed for better performance"
    kurtosis::Float64
    "The InterpKDE entropy, precomputed for better performance"
    entropy::Float64
end

"""
distribution_from_InterpKDE(ik::InterpKDE; minimum::Float64 = -Inf, maximum::Float64 = Inf )

Outer constructor for distribution_from_InterpKDE. It precomputes the mean, var, skewness, kurtosis and entropy of ik using QuadGK. 
"""
function distribution_from_InterpKDE(ik::InterpKDE; minimum::Float64 = -Inf, maximum::Float64 = Inf )
    mean::Float64 = quadgk(y -> y * pdf(ik, y),minimum, maximum)[1]
    var::Float64 =  quadgk(y -> ((y-mean)^2) * pdf(ik, y),minimum, maximum )[1]
    skewness::Float64 = quadgk(y -> ((y - mean)^3)*pdf(ik,y), minimum, maximum)[1]/ (var)^(3/2)
    kurtosis::Float64 = quadgk(y -> ((y-mean)^4) * pdf(ik, y), minimum, maximum )[1] / (var^2)
    entropy::Float64 = quadgk(y -> -pdf(ik,y)*logpdf(ik,y), minimum, maximum)[1]
    return new(minimum, maximum, ik, mean, var, skewness, kurtosis, entropy) #param
end


# minimum
minimum(d::distribution_from_InterpKDE) = d.minimum

# maximum
maximum(d::distribution_from_InterpKDE) = d.maximum

mean(d::distribution_from_InterpKDE) = d.mean
var(d::distribution_from_InterpKDE) = d.var
skewness(d::distribution_from_InterpKDE) = d.skewness

entropy(d::distribution_from_InterpKDE) = d.entropy


pdf(d::distribution_from_InterpKDE, x::Real) = pdf(d.ik,x)

# logpdf
logpdf(d::distribution_from_InterpKDE, x::Real) = log(pdf(d.ik,x))

cdf(d::distribution_from_InterpKDE, x::Real) = quadgk(y -> pdf(d, y), d.minimum, x)[1] 
quantile(d::distribution_from_InterpKDE, q::Real)  = find_zero(y -> cdf(d,y) - q )

rand(d::distribution_from_InterpKDE) = quantile(d, Base.rand(Uniform(0.0 , 1.0)))

# insupport
insupport(d::distribution_from_InterpKDE, x::Real)  = d.minimum <=  x <= d.maximum

mgf(d::distribution_from_InterpKDE, t::Float64) = quadgk( y -> exp(t*y) * pdf(d,y) , d.minimum, d.maximum)[1]

# cf ( charateristic function : https://en.wikipedia.org/wiki/Characteristic_function_(probability_theory))
cf(d::distribution_from_InterpKDE, t::Real) = quadgk(x -> exp(im*t*x)*pdf(d,x), d.minimum, d.maximum)[1]

# KernelDensity.jl EXTENSIONS #

kernel_dist(::Type{Truncated{Normal{Float64},Continuous,Float64}}, w::Real ) = (s = w/std(truncated(Normal(0.0,1.0), 0.0, Inf)) ; truncated(Normal(0.0, s), 0.0, Inf))