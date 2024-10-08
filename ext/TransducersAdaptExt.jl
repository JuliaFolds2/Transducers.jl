module TransducersAdaptExt

if isdefined(Base,:get_extension)
    import Transducers
    import Adapt
else
    import ..Transducers
    import ..Adapt
end

Adapt.adapt_structure(to, rf::R) where {R <: Transducers.Reduction} =
    Transducers.Reduction(Adapt.adapt(to, Transducers.xform(rf)), Adapt.adapt(to, Transducers.inner(rf)))

Adapt.adapt_structure(to, xf::Transducers.Map) = Transducers.Map(Adapt.adapt(to, xf.f))

Adapt.adapt_structure(to, xf::Transducers.MapSplat) = Transducers.MapSplat(Adapt.adapt(to, xf.f))

Adapt.adapt_structure(to, xf::Transducers.Filter) = Transducers.Filter(Adapt.adapt(to, xf.pred))

Adapt.adapt_structure(to, xf::Transducers.GetIndex{inbounds}) where {inbounds} =
    Transducers.GetIndex{inbounds}(Adapt.adapt(to, xf.array))

Adapt.adapt_structure(to, xf::Transducers.SetIndex{inbounds}) where {inbounds} =
    Transducers.SetIndex{inbounds}(Adapt.adapt(to, xf.array))

Adapt.adapt_structure(to, xf::Transducers.ReducePartitionBy) = Transducers.ReducePartitionBy(
    Adapt.adapt(to, xf.f),
    Adapt.adapt(to, xf.rf),
    Adapt.adapt(to, xf.init),
)
end #module



