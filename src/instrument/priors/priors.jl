export ObservedSitesPrior, InstrumentPrior

abstract type AbstractSitePrior <: Distributions.ContinuousMultivariateDistribution end

abstract type AbstractInstrumentPrior <: Distributions.ContinuousMultivariateDistribution end

include("segmentation.jl")
include("independent.jl")
include("refant.jl")
include("instrument.jl")

struct SitesPrior{T, D, A, R}
    timecorr::T
    default_dist::D
    override_dist::A
    refant::R
end

function SitesPrior(corr, dist; refant=NoReference(), kwargs...)
    return SitesPrior(corr, dist, kwargs, refant)
end


struct ObservedSitesPrior{D, S}
    dists::D
    sitemap::S
end

function build_sitemap(segmentation, array)
    sts = sites(array)
    ts  = timestamps(segmentation, array)
    fs  = unique(array[:F])

    T  = array[:T]
    bl = array[:baseline]
    F  = array[:F]

    times = eltype(T)[]
    freqs = eltype(F)[]
    slist = Symbol[]

    # This is frequency, time, station ordering
    for f in fs, t in ts, s in sts
        if any(i->((T[i]∈t)&&s∈bl[i]&&f==F[i]), eachindex(T))
            push!(times, t.t0)
            push!(slist, s)
            push!(freqs, f)
        end
    end
    return SiteLookup(slist, times, freqs), ts
end

function ObservedSitePrior(d::SitesPrior, array::EHTArrayConfiguration)
    smap, ts, fs = build_sitemap(d.timecorr, array)
    site_dists = site_tuple(array, d.default_dist; d.override_dist...)
    dists = build_dist(site_dists, smap, d.refants)
    return ObservedSitesPrior(dists, sitemap)
end

function get_site_inds(timesfreqs, time, freq)

    return findall((t, f)->(t==time)&&(f==freq), timesfreqs)
end

function build_dist(dists::NamedTuple, smap::SiteLookup, refant)
    ts = smap.times
    ss = smap.sites
    fs = smap.frequencies

    tuni = unique(ts)
    funi = unique(fs)
    timefreq = StructArray((ts, fs))

    refantinds = build_refant(timefreq, refant)

    for i in eachindex(ts, ss, fs)

    end
    refants =
    map(ts) do t
        inds = findall(==(t), times(smap))
        sts = unique(@view(sites(sites(smap))[inds]))

    end
end

function timestamps(::ScanSeg, array)
    st     = array.scans
    scanid = 1:length(st)
    mjd    = array.mjd

    # Shift the central time to the middle of the scan
    dt = (st.stop .- st.start)
    t0 = st.start .+ dt./2
    return IntegrationTime.(5.0, scanid, t0, dt)
end

getscan(scans, t) = findfirst(i->scans.start[i]≤t<scans.stop[i], 1:length(scans))

function timestamps(::IntegSeg, array)
    ts = unique(array[:T])
    st     = array.scans
    scanids = getscan.(Ref(st), ts)
    mjd    = array.mjd

    # TODO build in the dt into the data format
    dt = minimum(diff(ts))
    return IntegrationTime.(mjd, scanids, ts, dt)
end

function timestamps(::TrackSeg, array)
    st     = array.scans
    mjd    = array.mjd

    tstart, tend = extrema(array[:T])
    dt = tend - tstart

    # TODO build in the dt into the data format
    return IntegrationTime(mjd, 1:length(st), t, dt)
end













"""
    InstrumentParamPrior(dist0::NamedTuple, dist_transition::NamedTuple, jcache::SegmentedJonesCache)

Constructs a calibration prior in two steps. The first two arguments have to be a named tuple
of distributions, where each name corresponds to a site. The first argument is gain prior
for the first time stamp. The second argument is the segmented gain prior for each subsequent
time stamp. For instance, if we have
```julia
dist0 = (AA = Normal(0.0, 1.0), )
distt = (AA = Normal(0.0, 0.1), )
```
then the gain prior for first time stamp that AA obserserves will be `Normal(0.0, 1.0)`.
The next time stamp gain is the construted from
```
g2 = g1 + ϵ1
```
where `ϵ1 ~ Normal(0.0, 0.1) = distt.AA`, and `g1` is the gain from the first time stamp.
In other words `distt` is the uncorrelated transition probability when moving from timestamp
i to timestamp i+1. For the typical pre-calibrated dataset the gain prior on `distt` can be
tighter than the prior on `dist0`.
"""
function InstrumentParamPrior(dist0::NamedTuple, distt::NamedTuple, jcache::SiteLookup)
    sites = Tuple(unique(jcache.schema.sites))
    gstat = jcache.schema.sites
    @argcheck issubset(Set(gstat), Set(keys(dist0)))
    @argcheck issubset(Set(gstat), Set(keys(distt)))

    times = jcache.schema.times
    sites = jcache.schema.sites
    stimes = NamedTuple{sites}(map(x->times[findall(==(x), sites)], sites))
    cdist = map(zip(jcache.schema.sites, jcache.schema.times)) do (g, t)
        ((t > first(getproperty(stimes, g))) && jcache.seg[g] isa ScanSeg{true} ) && return getproperty(distt, g)
        return getproperty(dist0, g)
    end

    gprior = Dists.product_distribution(cdist)
    return InstrumentParamPrior{typeof(gprior), typeof(jcache)}(gprior, jcache)
end


function make_gdist(dists, gstat, jcache)
    gg = map(p->getproperty(dists, p), gstat)
    return Dists.product_distribution(gg)
end

# function make_reference_gdist(dists, gstat, jcache, refprior)
#     list = _makelist(dists, gstat, jcache, refprior)
#     return Dists.product_distribution(list)
# end


# function _makelist(dists, gstat, jcache, refprior)
#     sites = collect(Set(gstat))
#     idx = 1
#     times = jcache.schema.times
#     scantimes = unique(jcache.schema.times)
#     list = map(enumerate(scantimes)) do (i,t)
#         # Select the reference sites (we cycle through)
#         inds = findall(==(t), times)
#         ref, idxnew = _selectref(gstat[inds], sites, idx)
#         idx = idxnew
#         return gainlist_scan(gstat[inds], ref, dists, refprior)
#     end
#     return reduce(vcat, list)
# end

# function gainlist_scan(sites, ref, dists, refprior)
#     return map(sites) do s
#         if s == ref
#             return refprior
#         else
#             return getproperty(dists, s)
#         end
#     end
# end

# function _selectref(sites, sites, idx)
#     if sites[idx] ∈ sites
#         return sites[idx], max((idx + 1)%(length(sites)+1), 1)
#     else
#         for i in (idx+1):(length(sites)+idx)
#             idxnew = max(i%(length(sites)+1), 1)
#             if sites[idxnew] ∈ sites
#                 return sites[idxnew], max((idxnew+1)%(length(sites)+1), 1)
#             end
#         end
#         throw(AssertionError("No sites found"))
#     end
# end

#HypercubeTransform.bijector(d::InstrumentParamPrior) = HypercubeTransform.asflat(d.dist)
HypercubeTransform.asflat(d::InstrumentPrior) = asflat(d.dists)
HypercubeTransform.ascube(d::InstrumentPrior) = ascube(d.dists)

Distributions.sampler(d::ObservedSitesPrior, InstrumentPrior) = Distributions.sampler(d.dists)
Base.length(d::ObservedSitesPrior, InstrumentPrior) = length(d.dists)
Base.eltype(d::ObservedSitesPrior, InstrumentPrior) = eltype(d.dists)

function Distributions._rand!(rng::AbstractRNG, d::ObservedSitesPrior, InstrumentPrior, x::AbstractVector)
    Distributions._rand!(rng, d.dists, x)
end

function Distributions._logpdf(d::ObservedSitesPrior, InstrumentPrior, x::AbstractArray)
    return Distributions._logpdf(d.dists, x)
end


Statistics.mean(d::ObservedSitesPrior, InstrumentPrior) = mean(d.dists)
Statistics.var(d::ObservedSitesPrior, InstrumentPrior) = var(d.dists)
Statistics.cov(d::ObservedSitesPrior, InstrumentPrior) = cov(d.dists)
