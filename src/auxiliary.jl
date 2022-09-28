

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


function vary(t, index, max, vars,grad)
    p = ()
    for j in 1:max
        p = (p..., (t[1:index-1]..., j, t[index+1:grad]...))
    end  
    return p
end

function _ix(t, index, grad, offset, vars)
    if grad==0
        return ((),)
    end
    if(index==grad)
        return  vary(t, index, vars-offset, vars,grad)
    end
    p = ()
    for i in 1:vars
        p = (p..., _ix(t, index+1, grad, offset+i-1, vars)...)
        t = (t[1:index-1]..., t[index]+1, t[index+1:grad]...)
       
    end
    return p
end
#_ix((1,1), 1, 2, 0, 4)

function ix(vars, grad)
    Tuple(_ix(Tuple(1 for j in 1:i), 1, i, 0, vars) for i in 0:grad)
end
#ix(4, 2)