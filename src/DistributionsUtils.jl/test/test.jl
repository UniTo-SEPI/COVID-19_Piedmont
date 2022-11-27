using Revise
using DistributionsUtils
using Distributions

#dst = distribution_fitting_optim(Gamma, Dict( (quantile, (0.25,)) => 6.0, (quantile, (0.5,)) => 11.0, (quantile, (0.75,)) => 19.0, (pdf, (5.0,) ) => 2.0 ),  [0.5, 0.5], ([0.0, 0.0], [100.0, 100.0]) )


dst = fit_distributions((Gamma, LogNormal, Weibull),Dict( (quantile, (0.25,)) => 6.0, (quantile, (0.5,)) => 11.0, (quantile, (0.75,)) => 19.0),  ([0.5, 0.5], [0.5, 0.5], [0.5, 0.5]), (([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0]), ([0.0, 0.0], [100.0, 100.0])  ); return_best = true)
