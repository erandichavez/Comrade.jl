export modelimage

"""
    $(TYPEDEF)

Container for non-analytic model that contains a image cache which will hold the image,
a Fourier transform cache, which usually an instance of a <: FourierCache.

# Note

This is an internal implementation detail that shouldn't usually be called directly.
Instead the user should use the exported function `modelimage`, for example

```julia
using Comrade
m = ExtendedRing(20.0, 5.0)

# This creates an version where the image is dynamically specified according to the
# radial extent of the image
mimg = modelimage(m) # you can also optionally pass the number of pixels nx and ny

# Or you can create an IntensityMap
img = intensitymap(m, 100.0, 100.0, 512, 512)
mimg = modelimage(m, img)

# Or precompute a cache
cache = create_cache(FFTAlg(), img)
mimg = modelimage(m, cache)
```
"""
struct ModelImage{M,I,C} <: AbstractModelImage{M}
    model::M
    image::I
    cache::C
end
@inline visanalytic(::Type{<:ModelImage{M}}) where {M} = visanalytic(M)
@inline imanalytic(::Type{<:ModelImage{M}}) where {M} = imanalytic(M)
@inline isprimitive(::Type{<:ModelImage{M}}) where {M} = isprimitive(M)

function Base.show(io::IO, mi::ModelImage)
   #io = IOContext(io, :compact=>true)
   #s = summary(mi)
   ci = first(split(summary(mi.cache), "{"))
   println(io, "ModelImage")
   println(io, "\tmodel: ", summary(mi.model))
   println(io, "\timage: ", summary(mi.image))
   println(io, "\tcache: ", ci)
end

model(m::AbstractModelImage) = m.model
flux(mimg::ModelImage) = flux(mimg.image)

# function intensitymap(mimg::ModelImage)
#     intensitymap!(mimg.image, mimg.model)
#     mimg.image
# end

radialextent(m::ModelImage) = hypot(fov(m.image)...)

#@inline visibility_point(m::AbstractModelImage, u, v) = visibility_point(model(m), u, v)

@inline intensity_point(m::AbstractModelImage, x, y) = intensity_point(model(m), x, y)



include(joinpath(@__DIR__, "cache.jl"))


"""
    modelimage(model::AbstractIntensityMap, image::AbstractIntensityMap, alg=FFTAlg(), executor=SequentialEx())

Construct a `ModelImage` from a `model`, `image` and the optionally
specified visibility algorithm `alg` and `executor` which uses Folds.jl
parallelism formalism.

# Notes
For analytic models this is a no-op and returns the model.
For non-analytic models this creates a `ModelImage` object which uses `alg` to compute
the non-analytic Fourier transform.
"""
@inline function modelimage(model::M, image::ComradeBase.AbstractIntensityMap, alg::FourierTransform=FFTAlg(), executor=SequentialEx()) where {M}
    return modelimage(visanalytic(M), model, image, alg, executor)
end

@inline function modelimage(::IsAnalytic, model, args...; kwargs...)
    return model
end

function _modelimage(model, image, alg, executor)
    intensitymap!(image, model, executor)
    cache = create_cache(alg, image)
    return ModelImage(model, image, cache)
end

@inline function modelimage(::NotAnalytic, model,
                            image::ComradeBase.AbstractIntensityMap,
                            alg::FourierTransform=FFTAlg(),
                            executor=SequentialEx())
    _modelimage(model, image, alg, executor)
end

"""
    modelimage(model, cache::AbstractCache, executor=SequentialEx())

Construct a `ModelImage` from the `model` and using a precompute Fourier transform `cache`.
You can optionally specify the executor which will compute the internal image buffer using
the `executor`.

# Example

```julia-repl
julia> m = ExtendedRing(10.0)
julia> cache = create_cache(DFTAlg(), IntensityMap(zeros(128, 128), 50.0, 50.0)) # used threads to make the image
julia> mimg = modelimage(m, cache, ThreadedEx())
```

# Notes
For analytic models this is a no-op and returns the model.

"""
@inline function modelimage(model::M, cache::AbstractCache, executor=SequentialEx()) where {M}
    return modelimage(visanalytic(M), model, cache, executor)
end


@inline function modelimage(::NotAnalytic, model, cache::AbstractCache, executor=SequentialEx())
    img = cache.img
    intensitymap!(img, model)
    newcache = update_cache(cache, img)
    return ModelImage(model, img, newcache)
end

"""
    modelimage(img::IntensityMap, alg=NFFTAlg())

Create a model image directly using an image, i.e. treating it as the model. You
can optionally specify the Fourier transform algorithm using `alg`

# Notes
For analytic models this is a no-op and returns the model.

"""
@inline function modelimage(img::IntensityMap, alg=NFFTAlg())
    cache = create_cache(alg, img)
    return ModelImage(img, img, cache)
end

"""
    modelimage(img::IntensityMap, cache::AbstractCache)

Create a model image directly using an image, i.e. treating it as the model. Additionally
reuse a previously compute image `cache`. This can be used when directly modeling an
image of a fixed size and number of pixels.

# Notes
For analytic models this is a no-op and returns the model.

"""
@inline function modelimage(img::IntensityMap, cache::AbstractCache)
    newcache = update_cache(cache, img)
    return ModelImage(img, img, newcache)
end

"""
    modelimage(m;
               fovx=2*radialextent(m),
               fovy=2*radialextent(m),
               nx=512,
               ny=512,
               pulse=ComradeBase.DeltaPulse(),
               alg=FFTAlg(),
               executor=SequentialEx()
                )

Construct a `ModelImage` where just the model `m` is specified.

If `fovx` or `fovy` aren't given `modelimage` will *guess* a reasonable field of view based
on the `radialextent` function. `nx` and `ny` are the number of pixels in the x and y
direction. The `pulse` is the pulse used for the image and `alg`

# Notes
For analytic models this is a no-op and returns the model.

"""
function modelimage(m::M;
                    fovx=2*radialextent(m),
                    fovy=2*radialextent(m),
                    nx=512,
                    ny=512,
                    pulse=ComradeBase.DeltaPulse(),
                    alg=FFTAlg(),
                    executor=SequentialEx()) where {M}
    if visanalytic(M) == IsAnalytic()
        return m
    else
        T = typeof(intensity_point(m, 0.0, 0.0))
        img = IntensityMap(zeros(T,ny,nx), fovx, fovy, pulse)
        modelimage(m, img, alg, executor)
    end
end
