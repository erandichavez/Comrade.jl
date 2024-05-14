module ComradeOptimizationExt

using Comrade

using Optimization
using Distributions
using LinearAlgebra

"""
    SciMLBase.OptimizationFunction(post::Posterior, args...; kwargs...)

Constructs a `OptimizationFunction` from a `Comrade.TransformedPosterior` object.
Note that a user must **transform the posterior first**. This is so we know which
space is most amenable to optimization.
"""
function Optimization.OptimizationFunction(post::Comrade.TransformedVLBIPosterior, args...; kwargs...)
    ℓ(x,p) = -logdensityof(post, x)
    return SciMLBase.OptimizationFunction(ℓ, args...; kwargs...)
end

"""
    laplace(prob, opt, args...; kwargs...)

Compute the Laplace or Quadratic approximation to the prob or posterior.
The `args` and `kwargs` are passed the the SciMLBase.solve function.
This will return a `Distributions.MvNormal` object that approximates
the posterior in the transformed space.

Note the quadratic approximation is in the space of the transformed posterior
not the usual parameter space. This is better for constrained problems where
we may run up against a boundary.
"""
function comrade_laplace(prob::SciMLBase.OptimizationProblem, opt, args...; kwargs...)
    sol = solve(prob, opt, args...; kwargs...)
    f = Base.Fix2(prob.f, nothing)
    J = ForwardDiff.hessian(f, sol)
    @. J += 1e-5 # add offset to help with positive definitness
    h = J*sol
    return MvNormalCanon(h, Symmetric(J))
end

function comrade_opt(post::VLBIPosterior, opt, adtype=Optimization.NoAD(), args...; initial_params=nothing, kwargs...)
    if (adtype isa SciMLBase.NoAD)
        tpost = ascube(post)
    else
        tpost = asflat(post)
    end

    f = OptimizationFunction(tpost, adtype; kwargs...)

    if isnothing(initial_params)
        initial_params = prior_sample(tpost)
    end

    lb = nothing
    ub = nothing
    if tpost.transform isa HypercubeTransform.AbstractHypercubeTransform
        lb=fill(-5.0, dimension(tpost))
        ub = fill(5.0, dimension(tpost))
    end

    prob = OptimizationProblem(f, initial_params, nothing; lb, ub)
    sol = solve(prob, opt, args...; kwargs...)
    return transform(tpost, sol), sol
end

end
