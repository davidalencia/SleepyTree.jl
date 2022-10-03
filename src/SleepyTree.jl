module SleepyTreeModule

import Base: zero, one
import Base: +, -, *, ^, ==
import Base: eltype

#constructor
export SleepyTree
#parameters 
export setvariables, eltype 
#arithmetic
export zero, one


include("constructor.jl")
include("auxiliary.jl")
include("parameters.jl")
include("arithmetic.jl")
include("comparator.jl")
include("utils.jl")
include("printing.jl")

end
