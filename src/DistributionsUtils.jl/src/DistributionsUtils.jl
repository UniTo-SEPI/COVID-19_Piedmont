module DistributionsUtils

# Write your package code here.

export distribution_from_InterpKDE, minimum, maximum , pdf, logpdf, cdf, mgf, cf, quantile, rand,  mean, var, skewness, kurtosis, entropy, insupport,

       get_oom, get_α_β_from_γ_μ_beta_distribution, fit_all_distributions_jl_distributions, get_best_fitted_distribution, 

       fit_distributions
        

using Distributions
import Distributions: sampler, minimum, maximum , pdf, logpdf, cdf, mgf, cf, quantile, rand,  mean, var, skewness, kurtosis, entropy, insupport

using Optim

using KernelDensity
import KernelDensity:kernel_dist





include("./distribution_from_InterpKDE.jl")
include("./mle_distributions_fitting.jl")
include("./ssi_distributions_fitting.jl")

end
