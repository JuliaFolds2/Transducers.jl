module TransducersReferenceablesExt

if isdefined(Base, :get_extension)
    using Transducers
    using Referenceables
else
    using ..Transducers
    using ..Referenceables
end

@inline Transducers.executor_type(x::Referenceables.Referenceable) = Transducers.executor_type(parent(x))

end #module
