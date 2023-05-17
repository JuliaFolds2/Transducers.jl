module TransducersDataFramesExt

if isdefined(Base, :get_extension)
    using Transducers
    using DataFrames
else
    using ..Transducers
    using ..DataFrames
end

Transducers.asfoldable(df::DataFrames.AbstractDataFrame) = DataFrames.eachrow(df)
# We can't use `Compat.eachrow` here.  See:
# https://github.com/JuliaData/DataFrames.jl/pull/2067

end #module
