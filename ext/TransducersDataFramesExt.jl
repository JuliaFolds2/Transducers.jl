module TransducersDataFramesExt

using Transducers
using DataFrames

Transducers.asfoldable(df::DataFrames.AbstractDataFrame) = eachrow(df)

end #module
