module ComradeDynesty

using Comrade
using Dynesty

using AbstractMCMC
using Reexport
using Random

function __init__()
    return @warn "ComradeDynesty is deprecated. Dynesty.jl is now an extension."
end


end
