
const subscript_digits = [c for c in "₀₁₂₃₄₅₆₇₈₉"]
const superscript_digits = [c for c in "⁰¹²³⁴⁵⁶⁷⁸⁹"]
nothing

function subscriptify(n::Int)
    dig = reverse(digits(n))
    join([subscript_digits[i+1] for i in dig])
end

function superscriptify(n::Int)
    dig = reverse(digits(n))
    super = join([superscript_digits[i+1] for i in dig])
    super=="¹" ? "" : super
end

function _coors2vars(coors, n)
    ix = 1
    vars = ntuple(n->zero(Int), Val(n))
    for i in coors
        if i==1
            vars = (vars[1:ix-1]..., vars[ix]+1, vars[ix+1:n]...)
        else
            ix = ix+ i -1
            vars = (vars[1:ix-1]..., vars[ix]+1, vars[ix+1:n]...)
        end
    end
    return vars
end

"""
    coors2str(coors::Tuple, n::Int)

Dadas coordenadas del árbol y el número de variables regresa su forma como monomio
```julia
coors2str((1,1,2), 3) #"x₁²x₂¹"
```
"""
function coors2str(coors, n)
    vars = _coors2vars(coors, n)
    s = ""
    for (i, x) in enumerate(vars)
        if(x!=0)
            s *= "x"*subscriptify(i)*superscriptify(x)
        end
    end
    s
end

"""
Returns the coefficent (abs if needed) of a monomial and if it is negative.
"""
function printmono(n::Number)
    return "($n)", false
end
function printmono(n::Real)
    isnegative = n<0
    if (isone(abs(n)))
        return "", isnegative
    else
        return string(abs(n)), isnegative
    end
end

Base.show(io::IO, p::SleepyTree{vars, g, leafs, it}) where {vars, g, leafs, it}  = begin 
    hasp=false
    _, noncnt... = it 
    v = _coors2value(leafs, (), 0, 1)
    if(!iszero(v))
        print(io, v)
        hasp=true
    end
    for grados in noncnt
        for index in grados
            v = _coors2value(leafs, index, length(index), 1)
            if(!iszero(v)) 
                coeff, isnegative = printmono(v)
                print(io, ifelse(isnegative, "-", ifelse(hasp, "+", "")))
                print(io, coeff)
                print(io, coors2str(index, vars))
                hasp=true
            end
        end
    end
end

