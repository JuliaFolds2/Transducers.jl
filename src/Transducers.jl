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

end # module
