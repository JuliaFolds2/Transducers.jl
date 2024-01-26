module TransducersLazyArraysExt

if isdefined(Base, :get_extension)
    using Transducers: Transducers, @return_if_reduced, @next, @simd_if, complete, foldlargs, foldl_nocomplete
    using Transducers.Accessors: @set
    using LazyArrays
else
    using ..Transducers: Transducers, @return_if_reduced, @next, @simd_if, complete, foldlargs, foldl_nocomplete
    using ..Transducers.Accessors: @set
    using ..LazyArrays
end

@inline function _foldl_lazy_cat_vectors(rf, acc, vectors)
    isempty(vectors) && return complete(rf, acc)
    result = @return_if_reduced foldlargs(acc, vectors...) do acc, arr
        foldl_nocomplete(rf, acc, arr)
    end
    return complete(rf, result)
end

"""
    _foldl_lazy_hcat(rf, acc, coll::LazyArrays.Hcat)
"""
@inline _foldl_lazy_hcat(rf, acc, coll::AbstractMatrix) =
    _foldl_lazy_cat_vectors(rf, acc, coll.args)
# Hcat currently always is an `AbstractMatrix`

"""
    _foldl_lazy_vcat(rf, acc, coll::LazyArrays.Vcat)
"""
@inline function _foldl_lazy_vcat(rf, acc, coll)
    isempty(coll.args) && return complete(rf, acc)
    coll isa AbstractVector && return _foldl_lazy_cat_vectors(rf, acc, coll.args)
    coll :: AbstractMatrix
    for j in axes(coll, 2)
        vectors = view.(coll.args, Ref(:), j)
        acc = @return_if_reduced _foldl_lazy_cat_vectors(rf, acc, vectors)
    end
    return complete(rf, acc)
end

Transducers.__foldl__(rf, acc, coll::LazyArrays.Hcat) = _foldl_lazy_hcat(rf, acc, coll)
Transducers.__foldl__(rf, acc, coll::LazyArrays.Vcat) = _foldl_lazy_vcat(rf, acc, coll)

# Vcat currently always is an `AbstractVector` or `AbstractMatrix`

# TODO: write reduce for Vcat/Hcat which can be done in the "natural" order

end
