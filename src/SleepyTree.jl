module SleepyTreeModule

import Base: zero, one
import Base: +, -, *, ^

#constructor
export SleepyTree
#parameters 
export setvariables
#arithmetic
export zero, one


include("constructor.jl")
include("auxiliary.jl")
include("parameters.jl")
include("arithmetic.jl")
include("printing.jl")

end
