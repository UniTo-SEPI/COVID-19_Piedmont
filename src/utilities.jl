#########################
####### IMPORT ##########
#########################

import Base: length, <, >, isless, ==, isnan

#########################
######### TEST ##########
#########################

function process(path::String)
    println(path)                   # Display the string representing the relevant path
    df = CSV.read(path, DataFrame)  # Import the .csv file in path and store it in a DataFrame object
    return df                       # Output the dataframe
end

#########################
######## GENERAL ########
#########################

findparam(vec::Vector{T}) where {T} = t

"""
    remove_MVP(x,is_MVP::F) where {F <: Function}

Remove all MVP values from x (which is assumed to be iterable).
"""
remove_MVP(x,is_MVP::F) where {F <: Function} = [el for el in x if !is_MVP(el)]

"""
    check_maximum(x; MVP, is_MVP::F) where {F <: Function}

Return the maximum of `x`, if its length is greater than 0 once MVPs have been removed, otherwise return MVP.
"""
function check_maximum(x; MVP, is_MVP::F) where {F <: Function}
    x_no_MVP = remove_MVP(x,is_MVP)
    return length(x_no_MVP) > 0 ? maximum(x_no_MVP) : MVP
end

"""
    check_minimum(x::Vector{Date}; MVP, is_MVP::F) where {F <: Function}

Return the minimum of `x`, if its length is greater than 0 once MVPs have been removed, otherwise return MVP.
"""
function check_minimum(x::Vector{Date}; MVP, is_MVP::F) where {F <: Function}
    x_no_MVP = remove_MVP(x,is_MVP)
    return length(x_no_MVP) > 0 ? minimum(x_no_MVP) : MVP
end

"""
    check_max(x...;MVP, is_MVP::F) where {F <: Function}

Return the maximum of `x`, if its length is greater than 0 once MVPs have been removed, otherwise return MVP.
"""
function check_max(x...;MVP, is_MVP::F) where {F <: Function}
    x_no_MVP = remove_MVP(x,is_MVP)
    return length(x_no_MVP) > 0 ? maximum(x_no_MVP) : MVP

end

"""
    check_min(x...; MVP, is_MVP::F) where {F <: Function}

Return the minimum of `x`, if its length is greater than 0 once MVPs have been removed, otherwise return MVP.
"""
function check_min(x...;MVP, is_MVP)
    x_no_MVP = remove_MVP(x,is_MVP)
    return length(x_no_MVP) > 0 ? minimum(x_no_MVP) : MVP
end

#########################
#### PRE-PROCESSING #####
#########################

# Define the length of a missing element to be zero
Base.length(a::Missing) = 0

Base.isnan(s::String) = false
Base.isnan(d::Date) = false
Base.isnan(m::Missing) = false
Base.isnan(::Vector{String}) = false

Base.:(==)(a::OrderedDict{String,DataFrame}, b::OrderedDict{String,DataFrame}) = all(keys(a) .== keys(b)) && all([isequal(a_df, b_df) for (a_df, b_df) in zip(values(a),values(b))])

######## REPARTO #######       

"""
    mutable struct Reparto
    
# ENGLISH
Length of stay in an hospital ward (of type ordinary, intensive or rehabilitative) bounded by an admission and discharge date.

# ITALIAN 
Periodo di residenza in un reparto ospedaliero (di `tipo` ordinario, intensivo o riabilitativo) delimitato dagli eventi notevoli `data_ammissione` e data_dimissione`.

# FIELDS
- `tipo::Symbol`: type of ward (one of `:ordinario`, `:intensivo`, `:riabilitativo`);
- `data_ammissione::Date`: date of ward-specific admission;
- `data_dimissione::Date`: date of ward-specific discharge.
"""
mutable struct Reparto
    tipo::Symbol           
    data_ammissione::Date  
    data_dimissione::Date   
end

"""
    Reparto(; tipo::Symbol, data_ammissione::Date, data_dimissione::Date)

Outer constructor for Reparto checking that `tipo` is one of one of `:ordinario`, `:intensivo`, `:riabilitativo`.
"""
function Reparto(; tipo::Symbol, data_ammissione::Date, data_dimissione::Date)
    if tipo ∉ (:ordinario, :intensivo, :riabilitativo)
        error("`tipo` must be one of (:ordinario, :intensivo, :riabilitativo)")
    end
    return Reparto(tipo, data_ammissione, data_dimissione)
end

# Extend base operators to compare Repartos with dates
Base.:<(r::Reparto, d::Date) = r.data_ammissione < d && r.data_dimissione < d
Base.:<(d::Date, r::Reparto) = Base.:<(r::Reparto, d::Date)

Base.:<=(r::Reparto, d::Date) = r.data_ammissione < d && r.data_dimissione == d
Base.:<=(d::Date, r::Reparto) = Base.:<(r::Reparto, d::Date)

Base.:>(r::Reparto, d::Date) = r.data_ammissione > d && r.data_dimissione > d
Base.:>(d::Date, r::Reparto) = Base.:>(r::Reparto, d::Date)

Base.isless(r1::Reparto, r2::Reparto) = r1.data_dimissione < r2.data_ammissione

Base.:(==)(a::Reparto, b::Reparto) = a.tipo == b.tipo && a.data_ammissione == b.data_ammissione && a.data_dimissione == b.data_dimissione

######## RICOVERO ######        

"""
    struct Ricovero

# ENGLISH 
Sequence of lengths of stay in hospital wards visited by a patient. 

# ITALIAN 
Successione di periodi di residenza in reparti ospedalieri visitati da un paziente.

# FIELDS
- `reparti::Vector{Reparto}`: a vector of Repartos.
"""
struct Ricovero
    reparti::Vector{Reparto}
end

function Base.:(==)(a::Ricovero, b::Ricovero) 
    return all(a.reparti .== b.reparti) # isempty(setdiff(a.reparti, b.reparti))
end

function Base.:(==)(a::Vector{Ricovero}, b::Vector{Ricovero}) 
    return all(a .== b) #isempty(setdiff(a.reparti, b.reparti))
end

#########################
# DATA SAVING & LOADING #
#########################

"""
    load_sas7bdat(path::String) 

Load .sas7bsat file at `path` and return it as a `DataFrame`.
"""
load_sas7bdat(path::String) = DataFrame(readsas(path))


"""
    save_julia_variable(julia_variable, folder::String, name::String)

Save a variable `julia_variable` inside `folder` threefold: once using JLD2, once using Serialization.serialize and the last time writing the variable in a file as a string.
"""
function save_julia_variable(julia_variable, folder::String, name::String)

    dataset_name = Symbol(name)
    @eval jldsave(joinpath($folder,$name*".jld2"); $dataset_name = $julia_variable)

    Serialization.serialize(joinpath(folder,name*".jls"), julia_variable)

    open(joinpath(folder,name*".txt"), "w") do file
        write(file, string(julia_variable))
    end

end

"""
    load_julia_variable(folder::String)

Load the julia variable saved by `save_julia_variable` in two formats: . Return the saved dictionary if all three saved formats agree, otherwise returns all three formats.
"""
function load_julia_variable(folder::String; txt_parse_function::F = nothing) where {F <: Union{Function,Nothing}}
    files = readdir(folder; join  = true)
    splitted_paths = split.(files, Ref(Base.Filesystem.path_separator)) #"/"
    name = split(splitted_paths[end][end], ".")[1]
    loaded_jld2 = load(joinpath(folder, name*".jld2"), name)
    loaded_jls = Serialization.deserialize(joinpath(folder, name*".jls"))
    loaded_txt = nothing
    if !isnothing(txt_parse_function)
        loaded_txt = eval(Meta.parse(txt_parse_function(open(joinpath(folder, name*".txt"), "r") do file
        read(file, String)
        end)))
    end

    try
        if !isnothing(txt_parse_function)
            @assert isequal(loaded_jld2, loaded_jls) && isequal(loaded_jls,loaded_txt) #  == loaded_txt
            return loaded_jld2
        else @assert loaded_jld2 == loaded_jls # isequal(loaded_jld2, loaded_jls) #
            return loaded_jld2
        end
    catch
        println("Not all loaded files are equal, please check.")
        return loaded_jld2,loaded_jls, loaded_txt
    end
end

function read_csv_execute_columns(path_to_csv::String)
    dataframe = CSV.read(path_to_csv, DataFrame)
    for col in names(dataframe)
        println("col, $(typeof(col))")
    end

    @showprogress 1 for col_name in names(dataframe)
        #for i in eachindex(dataframe[!, col_name])
        #try
        # no_missing_values = [el for el in dataframe[!,col_name] if cmp("missing", string(el)) != 0]
        # println(col_name, "\t",no_missing_values[1:2], "\t", typeof(no_missing_values[1:2]), "\t" , typeof(Array(dataframe[!,col_name])))
        if typeof(Array(dataframe[!,col_name])) ∉ (Vector{Union{Missing, Date}}, Vector{Date})
            dataframe[!, col_name] .= eval.(Meta.parse.(string.(dataframe[!, col_name])))
        end
        # catch e
        #     println("Caught exception in `read_csv_execute_columns`: $e\n with $(dataframe[i, col_name]) \n Continuing...")
        # end
        #end
    end
    return dataframe
end