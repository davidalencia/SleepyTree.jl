

function ==(::SleepyTree{vars, g, leafs1, it}, ::SleepyTree{vars, g, leafs2, it}) where {vars, g, leafs1, leafs2, it}
    return  leafs1 == leafs2    
end

