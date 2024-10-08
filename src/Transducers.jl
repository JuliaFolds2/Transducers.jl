module Transducers

export AdHocFoldable,
    Broadcasting,
    Cat,
    Completing,
    Consecutive,
    CopyInit,
    Count,
    Dedupe,
    DistributedEx,
    Drop,
    DropLast,
    DropWhile,
    Empty,
    Enumerate,
    Filter,
    FlagFirst,
    GroupBy,
    Init,
    Interpose,
    Iterated,
    KeepSomething,
    Map,
    MapCat,
    MapSplat,
    NondeterministicThreading,
    NotA,
    OfType,
    OnInit,
    Partition,
    PartitionBy,
    PreferParallel,
    ProductRF,
    ReduceIf,
    ReducePartitionBy,
    Reduced,
    Replace,
    Scan,
    ScanEmit,
    SequentialEx,
    SplitBy,
    TCat,
    Take,
    TakeLast,
    TakeNth,
    TakeWhile,
    TeeRF,
    ThreadedEx,
    Transducer,
    Unique,
    Zip,
    append!!,
    channel_unordered,
    compose,
    dcollect,
    dcopy,
    dtransduce,
    eduction,
    foldxd,
    foldxl,
    foldxt,
    ifunreduced,
    opcompose,
    push!!,
    reduced,
    reducingfunction,
    right,
    setinput,
    tcollect,
    tcopy,
    transduce,
    unreduced,
    whencombine,
    whencomplete,
    wheninit,
    whenstart,
    withprogress

using Base.Broadcast: Broadcasted
using Base: tail

import Accessors
import Tables
using ArgCheck
using BangBang.Experimental: modify!!, mergewith!!
using BangBang.NoBang: SingletonVector, SingletonDict
using BangBang:
    @!, BangBang, Empty, append!!, collector, empty!!, finish!, push!!, setindex!!, union!!
using Baselet
using CompositionsBase: compose, opcompose
using DefineSingletons: @def_singleton
using Distributed: @everywhere, Distributed
using InitialValues:
    GenericInitialValue,
    InitialValue,
    InitialValues,
    SpecificInitialValue,
    asmonoid,
    hasinitialvalue
using Logging: @logmsg, LogLevel
using MicroCollections: UndefVector, UndefArray
using Requires
using Accessors: @optic, @set, set, setproperties
using SplittablesBase: SplittablesBase, amount, halve
import ConstructionBase

using CompositionsBase: ⨟
export ⨟

using Base.Threads: @spawn

function nonsticky!(task)
    task.sticky = false
    return task
end

splat(f) = @static isdefined(Base, :Splat) ?  Base.Splat(f) : Base.splat(f)

const AbstractArrayOrBroadcasted = Union{AbstractArray, Broadcasted}

include("AutoObjectsReStacker.jl")
using .AutoObjectsReStacker: restack

include("showutils.jl")
include("basics.jl")
include("core.jl")
include("library.jl")
include("teezip.jl")
include("groupby.jl")
include("broadcasting.jl")
include("consecutive.jl")
include("partitionby.jl")
include("splitby.jl")
include("combinators.jl")
include("simd.jl")
include("executors.jl")
include("processes.jl")
include("threading_utils.jl")
include("nondeterministic_threading.jl")
include("dreduce.jl")
include("unordered.jl")
include("air.jl")
include("lister.jl")
include("show.jl")
include("comprehensions.jl")
include("progress.jl")
include("reduce.jl")

#used by TransducersOnlineStatsBaseExt, but exported directly in tests
const OSNonZeroNObsError = ArgumentError(
    "An `OnlineStat` with one or more observations cannot be used with " *
    "`foldxt` and `foldxd`.",
)

if !isdefined(Base,:get_extension)
    using Requires
    import Adapt
    include("../ext/TransducersAdaptExt.jl")
    function __init__()
        @require BlockArrays="8e7c35d0-a365-5155-bbbb-fb81a777f24e" include("../ext/TransducersBlockArraysExt.jl")
        @require LazyArrays="5078a376-72f3-5289-bfd5-ec5146d43c02" include("../ext/TransducersLazyArraysExt.jl")
        @require DataFrames="a93c6f00-e57d-5684-b7b6-d8193f3e46c0" include("../ext/TransducersDataFramesExt.jl")
        @require OnlineStatsBase="925886fa-5bf2-5e8e-b522-a9147a512338" include("../ext/TransducersOnlineStatsBaseExt.jl")
        @require Referenceables="42d2dcc6-99eb-4e98-b66c-637b7d73030e" include("../ext/TransducersReferenceablesExt.jl")
    end
end

end # module
