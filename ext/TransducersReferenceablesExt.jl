module TransducersReferenceablesExt

using Transducers
using Referenceables

@inline Transducers.executor_type(x::Referenceables.Referenceable) = Transducers.executor_type(parent(x))

end #module
