include("../src/SleepyTree.jl")
using .SleepyTreeModule
using Test

import .SleepyTreeModule: getleafs,subscriptify, superscriptify

function var(sub, sup) 
    supers = sup==1 ? "" : superscriptify(sup)
    subs = subscriptify(sub)
    "x"*subs*supers
end

include("printing.jl")
include("arithmetic.jl")
