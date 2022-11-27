#############################
######## ENVIRONMENT ########
#############################

using Pkg                                                                    # Import package manager
Pkg.activate(replace(Base.source_path(), "synthetic_time_delays.jl" => ""))  # Activate Julia environment
Pkg.instantiate()                                                            # Instantiate the Julia environment 

#############################
######### PACKAGES ##########
#############################

using Distributions, Statistics, Random, DistributionsUtils # Probability distributions
using HTTP, CSV                                             # Data loading and saving 
using DataFrames                                            # Data wrangling 
using Plots                                                 # Data visualization

#############################
###### PRE-PROCESSING #######
#############################

# Path to empirical time delays distributions from Zardini et al. (2021) 
const pietro_root_path = "/Users/pietro/GitHub/ComputationalEpidemiologyProject"
const claudio_root_path = "E:\\GitHub\\ComputationalEpidemiologyProject"
const root_path = pietro_root_path

# Load empirical time delays distributions from Zardini et al. (2021) 
const zardini_empirical_distributions_df = CSV.read(joinpath(root_path, "Data/Parameters/Delays/Empirical_Delay_Distributions_Zardini.csv"), DataFrame)

# Associations between time delay and number of patients used to evaluate its empirical distribution. 
## Taken from table S4 of https://ars.els-cdn.com/content/image/1-s2.0-S1755436521000748-mmc1.pdf
const populations = Dict("T_IS_P" => 363 + 264,
                         "T_IS_AO" => 137 + 126,
                         "T_IS_AI" => 5 + 7,
                         "T_IS_D" => 16 + 19,
                         "T_AO_AI" => 5 + 7,
                         "T_AO_FP" => 137 + 126,
                         "T_AI_DI" => 5 + 7
                        )

#############################
### DISTRIBUTION FITTING ####
#############################

# Fit negative binomials to empirical distributions
optimkdes = []
for delay_name in names(zardini_empirical_distributions_df)[2:end]
    # Get observations
    observations = zardini_empirical_distributions_df[:, delay_name]
    # Fit Distributions.jl's (continuous) NegativBinomial by matching its pdf values to observations
    kde = fit_distributions((NegativeBinomial,), Dict((Distributions.pdf, (float(i),)) => observations[i] for i in 1:length(observations)), ([0.5, 0.5],), (([0.0, 0.0], [100.0, 100.0]),); return_best=true)
    # Push estimated distribution to array
    push!(optimkdes, kde)
end

#############################
#### DATA VISUALIZATION #####
#############################

# Plot Empirical vs Estimaed distributions
plts = []

## Set plot colors
bars_color = palette(:tab20)[2]
line_color = palette(:tab20)[7]

for (kde, delay_name) in zip(optimkdes, names(zardini_empirical_distributions_df)[2:end])
    # Get observations
    observations = zardini_empirical_distributions_df[:, delay_name] .* populations[delay_name]
    # Get plot title
    delay_name_splits = split(delay_name, "_")
    title = "Time delay distribution from $(delay_name_splits[2]) to $(delay_name_splits[3])"
    # Plot empirical distribution and set overall plot parameters
    p = bar(zardini_empirical_distributions_df.Time, observations ./ populations[delay_name], title=title, xlabel="Time (Days)", ylabel="Frequency", label="Empirical", color=bars_color, size=(1000, 900), legendfontsize=30) #observations ./ populations[delay_name]
    # Plot estimated distribution evaluating its pdf
    plot!(zardini_empirical_distributions_df.Time, Distributions.pdf.(Ref(kde), zardini_empirical_distributions_df.Time), lw=5, label="Estimated", color=line_color)
    # Push plot to array
    push!(plts, p)
end

# Plot all empirical vs estimated subplots in a grid plot (one will be ignored)
const grid_plot = plot(plts[1:6]..., layout=(3, 2), size=(1000, 900), dpi=300)

# Save plot
savefig(grid_plot, "./Slides/Data_Modelling/images/4-time_delays/synthetic_input/priors/priors.png")