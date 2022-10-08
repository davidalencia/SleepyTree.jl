function setvariables(vars, grad, typ)
    leafs = tupleTree(vars, typ, grad)
    it = ix(vars, grad)
    Tuple(SleepyTree{vars, grad, setindexsleepytree(leafs, one(typ), (i,), 1, 1, vars, 0), deepcopy(it)}() for i in 1:vars)
end
#const x,y,z= setvariables(3, 4, Int)