eltype(::SleepyTree{v, g, leafs, it}) where {v, g, leafs, it} = typeof(leafs[1])

getleafs(::SleepyTree{v, g, leafs, it}) where {v, g, leafs, it} = leafs