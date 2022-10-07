@testset "Sum" verbose=true begin
    @testset "SleepyTree + SleepyTree" begin
        @testset "nvars=1, grad=1" begin
            x, = setvariables(1,1,Int)
            @test string(x+x) == "2$(var(1,1))" broken=true
            @test reduce(+, [x for i in 1:10]) == x*10 broken=true
            @test string(2x+3x) == "5$(var(1,1))" broken=true
        end
        @testset "nvars=2, grad=1" begin
            x,y = setvariables(2,1,Int)
            @test string(x+y) == "$(var(1,1))+$(var(2,1))" broken=true
        end
        @testset "nvars=1, grad=2" begin
            x, = setvariables(2,1,Int)
            @test string(x+x) == "2$(var(2,1))" broken=true
        end
        @testset "nvars=3, grad=4" begin 
            x,y,z = setvariables(3,4,Int)
            @test string(x+y+z) == "$(var(1,1))+$(var(2,1))+$(var(3,1))"
            @test string(y+z) == "$(var(2,1))+$(var(3,1))"
            @test string(z+y) == "$(var(2,1))+$(var(3,1))"
        end
    end
    @testset "SleepyTree + Number" begin
        @testset "nvars=1, grad=1" begin
            x, = setvariables(1,1,Int)
            @test string(x+1) == "1+$(var(1,1))" 
            @test string(reduce(+, [1 for i in 1:10], init=x)) == "10+$(var(1,1))"
        end
        @testset "nvars=2, grad=1" begin
            x,y = setvariables(2,1,Int)
            @test string(y+1) == "1+$(var(2,1))"
            @test string(x+y+1) == "1+$(var(1,1))+$(var(2,1))" broken=true
        end
        @testset "nvars=3, grad=4" begin 
            x,y,z = setvariables(3,4,Int)
            @test string(z+1) == "1+$(var(3,1))"
        end
        @testset "commutativity" begin
            x,y,z = setvariables(3,4,Int)
            @test string(10+y) == string(y+10)
        end
    end
end

@testset "Product" verbose=true begin
    @testset "SleepyTree * SleepyTree" begin
        @testset "nvars=1, grad=2" begin 
            x, = setvariables(1,2,Int)
            @test string(x*x) == "$(var(1,2))"
        end
        @testset "nvars=2, grad=4" begin 
            x,y = setvariables(2,4,Int)
            @test string(y*y) == "$(var(2,2))" 
            @test string(x*y) == "$(var(1,1))$(var(2,1))"
            @test string(x*y*x*y) == "$(var(1,2))$(var(2,2))"
            @test string(reduce(*, [x for i in 1:4])) == string(x^4)
        end
    end
    @testset "SleepyTree * Number" begin
        @testset "nvars=1, grad=1" begin 
            x, = setvariables(1,1,Int)
            @test string(x*4) == "4$(var(1,1))" broken=true
        end
        @testset "nvars=2, grad=4" begin 
            x,y = setvariables(2,4,Int)
            @test string(x*y*4) == "4$(var(1,1))$(var(2,1))"
        end
    end
end

@testset "Arithmetic" begin
    @testset "Product and Sum" begin
        x,y,z = setvariables(3,6,Int)
        @test string((x+1)*x*y) == "$(var(1,1))$(var(2,1))+$(var(1,2))$(var(2,1))" 
        @test string((x+2)*x*y*2) == "4$(var(1,1))$(var(2,1))+2$(var(1,2))$(var(2,1))" 
        @test string((x+1)*(y+1)*y*y*y) == "$(var(2,3))+$(var(1,1))$(var(2,3))+$(var(2,4))+$(var(1,1))$(var(2,4))"
    end
end