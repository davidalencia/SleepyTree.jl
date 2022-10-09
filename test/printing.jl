import Base:Exception

@testset "Priniting" verbose=true begin
    @testset "nvars" begin
        @testset "nvars=0" begin
            # @test_throws Exception setvariables(0,1, Float64) 
        end
        @testset "nvars=1" begin
            @testset "Float64" begin
                x, = setvariables(1,1, Float64)
                @test string(x) == "x₁"
                @test string(2x) == "2.0x₁"
                @test string(2.1x) == "2.1x₁" 
            end
            @testset "Int" begin
                x, = setvariables(1,1, Int)
                @test string(x) == "x₁"
                @test string(2x) == "2x₁"
                @test string(2.1x) == "2.1x₁" 
            end
        end
        @testset "nvars=2" begin
            @testset "Float64" begin
                x,y = setvariables(2,1, Float64)
                @test string(x) == "x₁"
                @test string(y) == "x₂"
                @test string(2y) == "2.0x₂" 
            end
            @testset "Int" begin
                x,y = setvariables(2,1, Int)
                @test string(x) == "x₁"
                @test string(y) == "x₂"
                @test string(2y) == "2x₂" 
                @test string(x-y) == "$(var(1,1))-$(var(2,1))" broken=true
            end
        end
    end
    @testset "grad" begin
        @testset "grad=0" begin
            # @test_throws Exception setvariables(1,0, Float64) # change to consturctor tests
        end
        @testset "grad=2" begin
            @testset "nvars=1" begin
                x, = setvariables(1,2, Int)
                @test string(x*x) == "x₁²"
            end
            @testset "nvars=2" begin
                x,y = setvariables(2,2, Int)
                @test string(y*x) == "x₁x₂"
            end
        end
        @testset "grad=6" begin
            @testset "nvars=2" begin
                x,y = setvariables(2,6, Int)
                @test string(y*y*x*x) == "x₁²x₂²" 
                @test string(y^2*x^4) == "x₁⁴x₂²" 
                @test string(y^4) == "x₂⁴"
            end
            @testset "nvars=3" begin
                x,y,z = setvariables(3,6, Int)
                @test string(x*y*z*z) == "x₁x₂x₃²"
                @test string(z^6) == "x₃⁶"
            end
        end
    end
end


