
const subscript_digits = [c for c in "₀₁₂₃₄₅₆₇₈₉"]
const superscript_digits = [c for c in "⁰¹²³⁴⁵⁶⁷⁸⁹"]
nothing

function subscriptify(n::Int)
    dig = reverse(digits(n))
    join([subscript_digits[i+1] for i in dig])
end

function superscriptify(n::Int)
    dig = reverse(digits(n))
    join([superscript_digits[i+1] for i in dig])
end

function _coors2vars(coors, n)
    ix = 1
    offset = 0
    vars = ntuple(n->zero(Int), Val(n)) # cambiar por ntuple
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

Base.show(io::IO, p::SleepyTree{vars, g, leafs, it}) where {vars, g, leafs, it}  = begin 
    hasp = false
    for grados in it
        for index in grados
            v = _coors2value(leafs, index, length(index), 1)
            if !iszero(v)
                if(hasp)
                    print(io, "+")
                end
                if isone(v) && index!=()
                    print(io, coors2str(index, vars))
                else
                    print(io, v,coors2str(index, vars))
                end
                hasp=true
            end
        end
    end
end

