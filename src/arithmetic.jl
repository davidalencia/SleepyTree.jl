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