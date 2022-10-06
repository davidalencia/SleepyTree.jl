import Base:Exception

@testset "Priniting" verbose=true begin
    @testset "nvars" begin
        @testset "nvars=0" begin
            # @test_throws Exception setvariables(0,1, Float64) 
        end
        @testset "nvars=1" begin
            @testset "Float64" begin
                x, = setvariables(1,1, Float64)
                @test string(x) == "x₁" broken=true
                @test string(2x) == "2.0x₁" broken=true
                @test string(2.1x) == "2.1x₁" broken=true
            end
            @testset "Int" begin
                x, = setvariables(1,1, Int)
                @test string(x) == "x₁" broken=true
                @test string(2x) == "2x₁" broken=true
                @test string(2.1x) == "2.1x₁" broken=true
            end
        end
        @testset "nvars=2" begin
            @testset "Float64" begin
                x,y = setvariables(2,1, Float64)
                @test string(x) == "x₁" broken=true
                @test string(y) == "x₂" broken=true
                @test string(2y) == "2.0x₂" broken=true
            end
            @testset "Int" begin
                x,y = setvariables(2,1, Int)
                @test string(x) == "x₁" broken=true
                @test string(y) == "x₂" broken=true
                @test string(2y) == "2x₂" broken=true
            end
        end
    end
    @testset "grad" begin
        @testset "grad=0" begin
            # @test_throws Exception setvariables(1,0, Float64) 
        end
        @testset "grad=2" begin
            @testset "nvars=1" begin
                x = setvariables(1,2, Int)
                @test string(x*x) == "x₁²"  broken=true
            end
            @testset "nvars=2" begin
                x,y = setvariables(2,2, Int)
                @test string(y*x) == "x₁x₂" broken=true
            end
        end
        @testset "grad=4" begin
            @testset "nvars=2" begin
                x,y = setvariables(2,4, Int)
                @test string(y*y*x*x) == "x₁²x₂²" 
                @test string(y^4) == "x₂⁴"
            end
            @testset "nvars=3" begin
                x,y,z = setvariables(3,4, Int)
                @test string(x*y*z*z) == "x₁x₂x₃²" broken=true 
            end
        end
    end
end


