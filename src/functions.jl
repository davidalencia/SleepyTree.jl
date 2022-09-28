struct SleepyTree{
    vars, #::Int
    grad, #::Int #el grado es muy importante que sea en tiempo de compilación
    leafs, #::Tuple
    it #::Tuple # el iterador tambien parece serlo
    }end

@generated function _zeroleafs(leafs, vars, it::NTuple{len, T})  where {len, T}
    exs = Array{Expr}(undef, len)
    for i in 1:len
        exs[i] = :(leafs = setindexsleepytree(leafs, 0, it[$i], length(it[$i]), 1, vars, 0))
    end
    
    return Expr(:block, exs...) 
end 

@generated function zeroleafs(leafs, vars, ::Val{g}, it) where{g}
    exs = Array{Expr}(undef, g+1)
    exs[1] = :(z = deepcopy(leafs))
    for i in 1:g
        exs[i+1] = :(z = _zeroleafs(z, vars, it[$i]))
    end
    
    return Expr(:block, exs...) 
end

"""
     _coors2value(node::Tuple, coors::Tuple, coors_len::Int, ix::Int)
Regresa el valor de las coordenadas en el árbol de tuplas.

Ejemplo
```
#_coors2value(tupleTree(3, Int, 3), (1,), 1, 1)
#_coors2value(setindexsleepytree(getleafs(x), 1, (), 0, 1, 3, 0), (), 0, 1)
```
"""
function _coors2value(node::Tuple, coors::Tuple, coors_len::Int, ix::Int)
    if(coors_len < ix)
        return node[1]
    end
   return _coors2value(node[2][coors[ix]], coors, coors_len, ix+1)
end

"""
    fusioncoors(coors1::NTuple, coors2::NTuple, offset1=0, offset2=0)

Dadas dos tupla  de coordenadas regres la fusion de las coordenadas.

Ejemplo
```
fusioncoors((3,1,2), (2,2,2))  # (1,1,2,1,1,1,1,1)
```
"""
function fusioncoors(
        coors1::NTuple{len1, Int}, coors2::NTuple{len2, Int}, 
        offset1=0, offset2=0) where {len1, len2}
    if len1 == 0 && len2 == 0
        return ()
    elseif len1 == 0
        return (coors2[1]-offset2,coors2[2:len2]...) # finish coors2
    elseif len2 == 0
        return (coors1[1]-offset1,coors1[2:len1]...)# finish coors1
    elseif coors1[1]-offset1 == coors2[1]-offset2
        return (coors1[1]-offset1, 1, fusioncoors(coors1[2:len1], coors2[2:len2], 0, 0)...)
    elseif coors1[1]-offset1 < coors2[1]-offset2
        return (coors1[1]-offset1, fusioncoors(coors1[2:len1], coors2, 0, coors1[1]-1+offset2)...)
    else # coors1[ix1] >= coors2[ix2]
        return (coors2[1]-offset2, fusioncoors(coors1, coors2[2:len2], coors2[1]-1+offset1, 0)...)
    end
end

function setindexsleepytree(node::Tuple, val, coors::Tuple, coors_len::Int, ix::Int, vars::Int, offset::Int)
    if(coors_len < ix)
        if length(node)>1
            return @inbounds (val, node[2])
        else
            return (val,)
        end
    end
    leafs = (node[2][1:coors[ix]-1]...,
            setindexsleepytree(node[2][coors[ix]], val, coors, coors_len, ix+1, vars, offset+1-coors[ix]),
            node[2][coors[ix]+1:vars+offset]...)
   return @inbounds (node[1], leafs)
        
end
#setindexsleepytree(leafs, 1, (i,), 1, 1, vars, 0)
#setindexsleepytree(getleafs(x), 1, (), 0, 1, 3, 0)

function setindexsleepytree(node::Tuple, val, coors::Tuple, coors_len::Int, ix::Int, vars::Int, offset::Int, op::Function) 
    if(coors_len < ix)
        if length(node)>1
            return @inbounds (op(node[1], val), node[2])
        else     
            return (op(node[1], val),)
        end
    end
    leafs = (node[2][1:coors[ix]-1]...,
            setindexsleepytree(node[2][coors[ix]], val, coors, coors_len, ix+1, vars, offset+1-coors[ix], op),
            node[2][coors[ix]+1:vars+offset]...)
   return @inbounds (node[1], leafs)
        
end
#setindexsleepytree(getleafs(x), 4, (1,), 1, 1, 3, 0, +)

setindex(leafs::Tuple, val, coors::Tuple, vars::Int) = 
    setindexsleepytree(leafs, val, coors, length(coors), 1, vars, 0)
setindex(leafs::Tuple, val, coors::Tuple, vars::Int, op::Function) = 
    setindexsleepytree(leafs, val, coors, length(coors), 1, vars, 0, op)
setindex(t::SleepyTree{vars, grad, leafs, it}, val, coors::Tuple
    ) where {vars, grad, leafs, it} = 
    setindexsleepytree(leafs, val, coors, length(coors), 1, vars, 0)
setindex(t::SleepyTree{vars, grad, leafs, it}, val, coors::Tuple, op::Function
    ) where {vars, grad, leafs, it} = 
    setindexsleepytree(leafs, val, coors, length(coors), 1, vars, 0, op)

function tupleTreeAux(nvars, typ, grad, ix)
    if grad == ix
        return  Tuple(zero(typ) for _ in 1:nvars)
    end
    return (zero(typ), Tuple(tupleTreeAux(nvars-i, typ, grad, ix+1) for i in 0:(nvars-1))) #"g($ix,$nvars)"
end

"""
    tupleTree(nvars, typ, grad)

Regresa la forma de tupla de un SleepyTree con un número de variables igual a nvars,
de tipo typ y grado grad.

```julia
tupleTree(3, Int, 6)
```
"""
function tupleTree(nvars, typ, grad)
    (zero(typ), Tuple(tupleTreeAux(nvars-i, typ, grad, 1) for i in 0:(nvars)-1))
end

function setvariables(vars, grad, typ)
    leafs = tupleTree(vars, Int, grad)
    it = ix(vars, grad)
    Tuple(SleepyTree{vars, grad, setindexsleepytree(leafs, 1, (i,), 1, 1, vars, 0), deepcopy(it)}() for i in 1:vars)
end
#const x,y,z= setvariables(3, 4, Int)

"""
    zero(x)
"""
@generated function zero(::SleepyTree{vars, g, leafs, it}) where {vars, g, leafs, it}
    quote 
        m = zeroleafs(leafs, vars, Val(g), it)
        SleepyTree{ vars, g, m, it}()
    end
end

"""
    one(x)
"""
@generated function one(::SleepyTree{vars, g, leafs, it}) where {vars, g, leafs, it}
    quote 
        m = zeroleafs(leafs, vars, Val(g), it)
        m = setindex(m, 1, (), vars)
        SleepyTree{ vars, g, m, it}()
    end
end

function +(t1::SleepyTree{vars, g, leafs, it}, x ) where {vars, g, leafs, it}
    tt = setindexsleepytree(leafs, x+_coors2value(leafs, (), 0, 1), (), 0, 1, vars, 0)
    SleepyTree{ vars, g, tt, it}()
end

@generated function _sum(t1::Tuple, t2::Tuple, leafssum::Tuple , vars::Int ,it::NTuple{len, T}) where {len, T}
    exs = Array{Expr}(undef, len*3+1)
    exs[1] = :(s = deepcopy(leafssum))
    for i in 1:len
        exs[(i-1)*3+2] = :(x = _coors2value(t1, it[$i], length(it[$i]), 1))
        exs[(i-1)*3+3] = :(y =  _coors2value(t2, it[$i], length(it[$i]), 1))
        exs[(i-1)*3+4] = :(s = setindexsleepytree(s, x+y, it[$i], length(it[$i]), 1, vars, 0))
    end
   return Expr(:block, exs...)
end
#_sum(getleafs(x), getleafs(y), getleafs(y), 3, ((1,), (2,), (3,)))

@generated function _sumgrads(leafs1, leafs2, vars, ::Val{g}, it) where{g}
    exs = Array{Expr}(undef, g+1)
    exs[1] = :(s = deepcopy(leafs1))
    for i in 1:g
        exs[i+1] = :(s = _sum(s, leafs2, s, vars, it[$i]))
    end
    
   return Expr(:block, exs...) 
end

function +(t1::SleepyTree{vars, g, leafs1, it}, 
    t2::SleepyTree{vars, g, leafs2, it}) where {vars, g, leafs1, leafs2, it}
tt = _sumgrads(leafs1, leafs2, vars, Val(g), it)
SleepyTree{ vars, g, tt, it}()
end

@generated function _mul(m::Tuple, vars::Int, leafs1::Tuple, coors1::NTuple{n1, T1},  y::Number) where {n1, T1}
    exs = Array{Expr}(undef, n1)
    exsix = 1
    for i in 1:n1
        exs[exsix] = quote
            x = _coors2value(leafs1, coors1[$i], length(coors1[$i]), 1) ## TODO: cambiar por método principal y no auxiliar
            m = setindex(m, x*y, coors1[$i], vars, +)
        end
        exsix += 1
    end
    return Expr(:block, exs...)
end

"""
    *(x,y)
Computes the multiplication between to sleepy trees.

"""
@generated function *(t1::SleepyTree{vars, g, leafs1, it}, y::Number) where {vars, g, leafs1, it}
    exs = Array{Expr}(undef, g+3)
    exs[1] = :(m = zeroleafs(leafs1, vars, Val(g), it))
    exprix = 2
    for i in 0:g
        exs[exprix] = :(m = _mul(m, $vars, leafs1, it[$i+1], y))
        exprix += 1
    end
    exs[exprix] = :(SleepyTree{ vars, g, m, it}())
    
    return Expr(:block, exs...)
end

"""
    m = zeroleafs(leafs1, vars, Val(g), it)
    m = _mul(m, 3, leafs1, it[0 + 1], leafs2, it[(4 - 0) + 1])
Computes the multipliacation between two homogeneal polynomial of two leafs of SleepyTrees
"""
@generated function _mul(m::Tuple, vars::Int, leafs1::Tuple, coors1::NTuple{n1, T1}, 
        leafs2::Tuple, coors2::NTuple{n2, T2}) where {n1, n2, T1, T2}
    exs = Array{Expr}(undef, n1*n2)
    exsix = 1
    for i in 1:n1
        for j in 1:n2
            exs[exsix] = quote
                x = _coors2value(leafs1, coors1[$i], length(coors1[$i]), 1) ## TODO: cambiar por método principal y no auxiliar
                y = _coors2value(leafs2, coors2[$j], length(coors2[$j]), 1)
                newcoors =  fusioncoors(coors1[$i], coors2[$j])
                m = setindex(m, x*y, fusioncoors(coors1[$i], coors2[$j]), vars, +)
            end
            exsix += 1
        end
    end
    return Expr(:block, exs...)
end

"""
    *(x,y)
Computes the multiplication between to sleepy trees.

"""
@generated function *(t1::SleepyTree{vars, g, leafs1, it}, 
        t2::SleepyTree{vars, g, leafs2, it}) where {vars, g, leafs1, leafs2, it}
    exs = Array{Expr}(undef, convert(Int, (g+1)*(g+2)/2+2))
    exs[1] = :(m = zeroleafs(leafs1, vars, Val(g), it))
    exprix = 2
    for i in 0:g
        for j in 0:i
            exs[exprix] = :(m = _mul(m, $vars, leafs1, it[$j+1], leafs2, it[$g-$i+1]))
            exprix += 1
        end
    end
    exs[exprix] = :(SleepyTree{ vars, g, m, it}())
    
    return Expr(:block, exs...)
end

function ^(
    x::SleepyTree{vars, g, leafs, it}, p::Integer) where { vars, g, leafs, it} 
    p == 1 && return deepcopy(x)
    p == 0 && return one(x)
    p == 2 && return x*x
    t = trailing_zeros(p) + 1
    p >>= t

    while (t -= 1) > 0
        x = x*x
    end

    y = x
    while p > 0
        t = trailing_zeros(p) + 1
        p >>= t
        while (t -= 1) ≥ 0
            x = x*x
        end
        y *= x
    end

    return y
end

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

