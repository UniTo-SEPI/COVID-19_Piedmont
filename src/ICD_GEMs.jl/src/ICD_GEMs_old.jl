module ICD_GEMs

# Write your package code here.

export  get_GEM_dataframe_from_cdc_gem_txt, get_GEM_dict_from_GEM_dataframe, get_GEM_dict_from_cdc_gem_txt,
        GEM,
        get_oom, truncate_code, get_code_range, execute_applied_mapping


using DataFrames, DataStructures
using Combinatorics
using ProgressMeter

"""
    struct GEM

Represents a GEM table.

#FIELDS
- `data::DataFrame`: the actual GEM data, as outputted by `get_gem_dataframe_from_cdc_gem_txt`;
- `direction::String`: either 'I9_I10' or 'I10_I9'.
"""
struct GEM{T <: Union{DataFrame,OrderedDict{String, OrderedDict{String, Any}}}}
    data::T
    direction::String

    # Inner constructor overload
    function GEM(data::T, direction::String) where T <: Union{DataFrame,OrderedDict{String, OrderedDict{String, Any}} }
        # Check that `direction` is either "I9_I10" or "I10_I9"
        if !(cmp(direction,"I9_I10")==0 || cmp(direction,"I10_I9")==0)
            error("`direction` may only be one of ('I9_I10', 'I10_I9')")
        end
        # Check that the data is in the format outputted by `get_gem_dataframe_from_cdc_gem_txt`
        if T == DataFrame
            if !isempty(setdiff(names(data), ("source_code", "target_code", "Approximate", "No_Map", "Combination", "Scenario", "Choice_List")))
                error("The data is not in the format outputted by `get_gem_dataframe_from_cdc_gem_txt`")
            end
        elseif T == OrderedDict{String, OrderedDict{String, Any}}
            println(unique(vcat(keys.(values(data)))))
            if !isempty(setdiff(unique(vcat(keys.(values(data)))),( "Approximate", "No_Map", "Combination", "Scenario", "Choice_List")) )
            end
        end

        return new{T}(data, direction)
    end

end


"""
    get_gem_dataframe_from_cdc_gem_txt(path_to_txt::String, direction::String)

Get a `GEM` object from a .txt file as downloaded from https://www.cdc.gov/nchs/icd/icd10cm.htm
"""
function get_GEM_dataframe_from_cdc_gem_txt(path_to_txt::String, direction::String)

    # Check that `direction` is either "I9_I10" or "I10_I9"
    if !(cmp(direction,"I9_I10")==0 || cmp(direction,"I10_I9")==0)
        error("`direction` may only be one of ('I9_I10', 'I10_I9')")
    end

    # Preallocate data dataframe
    output_df = DataFrame(source_code  = String[], target_code = String[], Approximate = Bool[], No_Map = Bool[], Combination = Bool[], Scenario = Int64[], Choice_List = Int64[] )

    # Read txt and add every line as a row to `output`
    open(path_to_txt) do f
        for line in eachline(f)
            line_split = filter(x -> cmp(x,"") != 0, split(line, " "))
            flags_split = split(line_split[3], "")
            push!(output_df, (line_split[1], line_split[2], parse(Bool,flags_split[1]),parse(Bool,flags_split[2]), parse(Bool,flags_split[3]), parse(Int64,flags_split[4]), parse(Int64,flags_split[5])) )
        end
    end

    return GEM(output_df, direction)

end

"""
    get_gem_dict_from_GEM(GEM::GEM)

Return an OrderedDict representing the GEM.
"""
function get_GEM_dict_from_GEM_dataframe(GEM_dataframe::GEM{DataFrame})
    # Preallocate output
    output = OrderedDict{String, OrderedDict{String, Any}}()

    # Fill output Dict
    gem_dataframe_gby_source_code = groupby(GEM_dataframe.data, :source_code)
    @showprogress 1 for (source_code_gkey, source_code_group) in zip(keys(gem_dataframe_gby_source_code), gem_dataframe_gby_source_code) 
        scenarios = OrderedDict{Int64, Vector{Tuple{Vararg{String}}}}()

        source_code_group_gby_scenario = groupby(source_code_group, :Scenario)
        for (scenario_gkey,scenario_group) in zip(keys(source_code_group_gby_scenario), source_code_group_gby_scenario)
            scenario_group_gby_choice = groupby(scenario_group, :Choice_List)
            choices = vec(collect(Iterators.product([choice_group.target_code for choice_group in scenario_group_gby_choice]...)))
            push!(scenarios, scenario_gkey.Scenario => choices)
        end

        push!(output, source_code_gkey.source_code => OrderedDict("Approximate" => source_code_group.Approximate[1], "No_Map" =>source_code_group.No_Map[1], "Combination" => source_code_group.Combination[1], "Scenarios" => scenarios ))
        
    end
    
    return GEM(output, GEM_dataframe.direction)

end

function get_GEM_dict_from_cdc_gem_txt(path_to_txt::String, direction::String)
    GEM_dataframe = get_GEM_dataframe_from_cdc_gem_txt(path_to_txt, direction)
    
    return get_GEM_dict_from_GEM_dataframe(GEM_dataframe)

end


get_oom(x::Union{Float64,Int64}) = floor(log(10,x))

"""
    truncate_code(code::String, n_digits::Union{Int64,Nothing}) 

Tuncate code after n digits, and treat digits beyond the third as decimals. Convert to Float64 before returning.
"""
function truncate_code(code::String, n_digits::Union{Int64,Nothing})
    #if !occursin("V",code) &&!occursin("v",code) && !occursin("E",code) && !occursin("NoDx",code)
    truncated_code = !isnothing(n_digits) ? code[1:n_digits] : code
    return truncated_code[1:3]*"."*truncated_code[4:end] #parse(Float64,truncated_code[1:3]*"."*truncated_code[4:end])
    # else
    #     #truncated_code = !isnothing(n_digits) ? code[1:n_digits] : code
    #     return Inf
    # end
end

function get_code_range(code_range::String)
    endpoints = split(code_range, "-") 
    letter = endpoints[1][1]
    print("endpoints = $endpoints")
    numeric_portion_start = length(endpoints[1][4:end]) > 0 ? parse(Float64, endpoints[1][2:3]*"."*endpoints[1][4:end]) : parse(Int64, endpoints[1][2:3])
    numeric_portion_end = length(endpoints[2][4:end]) > 0 ? parse(Float64, endpoints[2][2:3]*"."*endpoints[2][4:end]) : parse(Int64, endpoints[2][2:3])
    step = length(endpoints[2][4:end]) == 0 ? 1 : round(10.0^(-length(endpoints[2][4:end])), digits =  length(endpoints[2][4:end]))

    numeric_codes = numeric_portion_start:step:numeric_portion_end
#=     codes = String[]
    for numeric_code in numeric_codes
        if get_oom(numeric_code) > 
    end =#
    codes = [get_oom(numeric_code) > 0 ? replace(letter*string(numeric_code), "."=> "") : replace(letter*"0"*string(numeric_code), "."=> "") for numeric_code in numeric_codes]
    println("codes = $codes, step = $step")
    return codes
end

function execute_applied_mapping(GEM::GEM{OrderedDict{String, OrderedDict{String, Any}}}, source_codes::Vector{String}) #, applied_mapping::String
    returned_codes = String[]#Float64[]
    for source_code in source_codes
        if occursin("-", source_code)
            println("source_code = $source_code")
            individual_source_codes = get_code_range(source_code)
            returned_codes_dict = OrderedDict(key => val for (key,val) in collect(GEM.data) if any(startswith.(Ref(key),individual_source_codes)))
            #if cmp(applied_mapping, "all") == 0
            #returned_codes = collect(Iterators.flatten(vcat(vcat(vcat([collect(values(dct["Scenarios"])...) for dct in values(returned_codes_dict)]...)...)...)))
            # println(collect(  Iterators.flatten(Iterators.flatten(Iterators.flatten(vcat([values(dct["Scenarios"]) for dct in values(returned_codes_dict)]...)))) ))
            push!(returned_codes, unique(truncate_code.( collect( Iterators.flatten(Iterators.flatten(Iterators.flatten(vcat([values(dct["Scenarios"]) for dct in values(returned_codes_dict)]...)))) ) ,Ref(nothing)))... )
            #end
            #println("returned_codes = $returned_codes")
        else
            returned_codes_dict = OrderedDict(key => val for (key,val) in collect(GEM.data) if startswith(key,source_code))
            #if cmp(applied_mapping, "all") == 0
            push!(returned_codes, unique(truncate_code.( collect( Iterators.flatten(Iterators.flatten(Iterators.flatten(vcat([values(dct["Scenarios"]) for dct in values(returned_codes_dict)]...)))) ) ,Ref(nothing)))... )
            #end
            #println("returned_codes = $returned_codes")
        end

    end

    return returned_codes
end









end
