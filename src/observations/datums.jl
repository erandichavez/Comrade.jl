export measurement, error, baseline

"""
    AbstractVisibilityDatum
An abstract type for all VLBI data types. See [`Comrade.EHTComplexVisibilityDatum`](@ref) for an example.
"""
abstract type AbstractVisibilityDatum{T} end
baseline(p::AbstractVisibilityDatum) = getfield(p, :baseline)
measurement(p::AbstractVisibilityDatum) = getfield(p, :measurement)
error(p::AbstractVisibilityDatum) = getfield(p, :error)

# function Base.propertynames(p::AbstractVisibilityDatum)
#     return (propertynames(baseline(p))..., :measurement, :error)
# end
# function Base.getproperty(p::AbstractVisibilityDatum, s::Symbol)
#     s == :measurement && return measurement(p)
#     s == :error       && return error(p)
#     return getproperty(baseline(p), s)
# end

build_datum(F::Type{<:AbstractVisibilityDatum}, m, e, b) = F(m, e, b)


abstract type ClosureProducts{T} <: AbstractVisibilityDatum{T} end

abstract type AbstractBaselineDatum end

"""
    $(TYPEDEF)

A Datum for a single coherency matrix

# Fields
$(FIELDS)

"""
Base.@kwdef struct EHTCoherencyDatum{S, B<:AbstractBaselineDatum, M<:SMatrix{2,2,Complex{S}}, E<:SMatrix{2,2,S}} <: Comrade.AbstractVisibilityDatum{S}
    """
    coherency matrix, with entries in Jy
    """
    measurement::M
    """
    visibility uncertainty matrix, with entries in Jy
    """
    error::E
    """
    baseline information
    """
    baseline::B
end


"""
    $(TYPEDEF)

A struct holding the information for a single measured complex visibility.

# FIELDS
$(FIELDS)

"""
Base.@kwdef struct EHTComplexVisibilityDatum{S<:Number, B<:AbstractBaselineDatum} <: AbstractVisibilityDatum{S}
    """
    Complex Vis. measurement (Jy)
    """
    measurement::Complex{S}
    """
    error of the complex vis (Jy)
    """
    error::S
    """
    baseline information
    """
    baseline::B
end



"""
    $(TYPEDEF)

A struct holding the information for a single measured visibility amplitude.

# FIELDS
$(FIELDS)

"""
Base.@kwdef struct EHTVisibilityAmplitudeDatum{S<:Number, B<:AbstractBaselineDatum} <: AbstractVisibilityDatum{S}
    """
    amplitude (Jy)
    """
    measurement::S
    """
    error of the visibility amplitude (Jy)
    """
    error::S
    """
    baseline information
    """
    baseline::B
end

"""
    $(TYPEDEF)

A Datum for a single closure phase.

# Fields
$(FIELDS)

"""
Base.@kwdef struct EHTClosurePhaseDatum{S<:Number, B<:AbstractBaselineDatum} <: ClosureProducts{S}
    """
    closure phase (rad)
    """
    measurement::S
    """
    error of the closure phase assuming the high-snr limit
    """
    error::S
    """
    baselines for the closure phase
    """
    baseline::NTuple{3, B}
end

"""
    triangle(b::EHTClosurePhaseDatum)

Returns the sites used in the closure phase triangle.
"""
triangle(b::EHTClosurePhaseDatum) = map(x->first(getproperty(x, :baseline)), baseline(b))



"""
    $(TYPEDEF)

A Datum for a single log closure amplitude.

# $(FIELDS)

"""
Base.@kwdef struct EHTLogClosureAmplitudeDatum{S<:Number, B<:AbstractBaselineDatum} <: ClosureProducts{S}
    """
    log-closure amplitude
    """
    measurement::S
    """
    log-closure amplitude error in the high-snr limit
    """
    error::S
    """
    baselines for the closure phase
    """
    baseline::NTuple{4, B}
end
