@testset "FqPolyRepFieldElem.conformance_tests" begin
  ConformanceTests.test_Field_interface_recursive(Native.finite_field(ZZ(7), 5, "z")[1])
end

@testset "FqPolyRepFieldElem.constructors" begin
  R, x = Native.finite_field(ZZ(7), 5, "x")

  @test elem_type(R) == FqPolyRepFieldElem
  @test elem_type(FqPolyRepField) == FqPolyRepFieldElem
  @test parent_type(FqPolyRepFieldElem) == FqPolyRepField

  Sy, y = polynomial_ring(residue_ring(ZZ, 36893488147419103363)[1], "y")
  Syy, yy = polynomial_ring(Native.GF(ZZ(36893488147419103363)), "y")

  T, z = Native.finite_field(y^2 + 1, "z")
  T2, z2 = Native.finite_field(yy^2 + 1, "z")

  # check that one can leave out the name for the generator, or specify it as a symbol
  @test Native.finite_field(ZZ(7), 5)[1] isa FqPolyRepField
  @test Native.finite_field(ZZ(7), 5, :x)[1] isa FqPolyRepField
  @test Native.finite_field(y^2 + 1)[1] isa FqPolyRepField
  @test Native.finite_field(y^2 + 1, :x)[1] isa FqPolyRepField

  @test isa(R, FqPolyRepField)
  @test isa(T, FqPolyRepField)
  @test isa(T2, FqPolyRepField)

  @test characteristic(R) == ZZRingElem(7)
  @test characteristic(T) == ZZRingElem(36893488147419103363)
  @test characteristic(T2) == ZZRingElem(36893488147419103363)


  @test isa(3x^4 + 2x^3 + 4x^2 + x + 1, FqPolyRepFieldElem)
  @test isa(z^2 + z + 1, FqPolyRepFieldElem)
  @test isa(z2^2 + z2 + 1, FqPolyRepFieldElem)

  a = R()

  @test isa(a, FqPolyRepFieldElem)

  b = R(4)
  c = R(ZZRingElem(7))

  @test isa(b, FqPolyRepFieldElem)

  @test isa(c, FqPolyRepFieldElem)

  d = R(c)

  @test isa(d, FqPolyRepFieldElem)

  e = R(Native.GF(ZZ(7))(1))
  @test isa(e, FqPolyRepFieldElem)
  @test isone(e)

  @test isa(R(QQ(1)), FqPolyRepFieldElem)

  # check for primality
  T3, z3 = Native.finite_field(yy^2 + 1, "z", check=false)
  @test isa(T2, FqPolyRepField)
  Syyy, yyy = polynomial_ring(residue_ring(ZZ, ZZ(4))[1], "y")
  @test yyy isa ZZModPolyRingElem
  @test_throws DomainError Native.finite_field(yyy^2+1, "z")
end

@testset "FqPolyRepFieldElem.printing" begin
  R, x = Native.finite_field(ZZRingElem(7), 5, "x")

  a = 3x^4 + 2x^3 + 4x^2 + x + 1

  @test sprint(show, "text/plain", a) == "3*x^4 + 2*x^3 + 4*x^2 + x + 1"
end

@testset "FqPolyRepFieldElem.manipulation" begin
  R, x = Native.finite_field(ZZRingElem(7), 5, "x")

  @test iszero(zero(R))

  @test isone(one(R))

  @test is_gen(gen(R))

  @test characteristic(R) == 7

  @test order(R) == ZZRingElem(7)^5

  @test degree(R) == 5

  @test is_unit(x + 1)

  @test deepcopy(x + 1) == x + 1

  @test coeff(2x + 1, 1) == 2

  @test_throws DomainError coeff(2x + 1, -1)

  @test isa(modulus(R), FpPolyRingElem)

  @test defining_polynomial(R) isa FpPolyRingElem
  kt, t = Native.GF(ZZ(7))["t"]
  @test parent(defining_polynomial(kt, R)) === kt
end

@testset "FqPolyRepFieldElem.unary_ops" begin
  R, x = Native.finite_field(ZZRingElem(7), 5, "x")

  a = x^4 + 3x^2 + 6x + 1

  @test -a == 6*x^4+4*x^2+x+6
end

@testset "FqPolyRepFieldElem.binary_ops" begin
  R, x = Native.finite_field(ZZRingElem(7), 5, "x")

  a = x^4 + 3x^2 + 6x + 1
  b = 3x^4 + 2x^2 + x + 1

  @test a + b == 4*x^4+5*x^2+2

  @test a - b == 5*x^4+x^2+5*x

  @test a*b == 3*x^3+2
end

@testset "FqPolyRepFieldElem.adhoc_binary" begin
  R, x = Native.finite_field(ZZRingElem(7), 5, "x")

  a = x^4 + 3x^2 + 6x + 1

  @test 3a == 3*x^4+2*x^2+4*x+3

  @test a*3 == 3*x^4+2*x^2+4*x+3

  @test a*ZZRingElem(5) == 5*x^4+x^2+2*x+5

  @test ZZRingElem(5)*a == 5*x^4+x^2+2*x+5

  F7 = Native.GF(ZZ(7))
  @test F7(5) + a == x^4 + 3x^2 + 6x + 6
  @test a + F7(5) == x^4 + 3x^2 + 6x + 6
  @test F7(5) * a == 5*x^4+x^2+2*x+5
  @test a * F7(5) == 5*x^4+x^2+2*x+5

  @test 12345678901234567890123*a == 3*x^4+2*x^2+4*x+3

  @test a*12345678901234567890123 == 3*x^4+2*x^2+4*x+3
end

@testset "FqPolyRepFieldElem.powering" begin
  R, x = Native.finite_field(ZZRingElem(7), 5, "x")

  a = x^4 + 3x^2 + 6x + 1

  @test a^3 == x^4+6*x^3+5*x^2+5*x+6

  @test a^ZZRingElem(-5) == x^4+4*x^3+6*x^2+6*x+2
end

@testset "FqPolyRepFieldElem.comparison" begin
  R, x = Native.finite_field(ZZRingElem(7), 5, "x")

  a = x^4 + 3x^2 + 6x + 1
  b = 3x^4 + 2x^2 + 2

  @test b != a
  @test R(3) == R(3)
  @test isequal(R(3), R(3))
end

@testset "FqPolyRepFieldElem.inversion" begin
  R, x = Native.finite_field(ZZRingElem(7), 5, "x")

  a = x^4 + 3x^2 + 6x + 1

  b = inv(a)

  @test b == x^4+5*x^3+4*x^2+5*x

  @test b == a^-1
end

@testset "FqPolyRepFieldElem.exact_division" begin
  R, x = Native.finite_field(ZZRingElem(7), 5, "x")

  a = x^4 + 3x^2 + 6x + 1
  b = 3x^4 + 2x^2 + 2

  @test divexact(a, b) == 3*x^4+2*x^3+2*x^2+5*x

  @test b//a == 4*x^2+6*x+5
end

@testset "FqPolyRepFieldElem.gcd" begin
  R, x = Native.finite_field(ZZRingElem(7), 5, "x")

  a = x^4 + 3x^2 + 6x + 1
  b = 3x^4 + 2x^2 + x + 1

  @test gcd(a, b) == 1

  @test gcd(R(0), R(0)) == 0
end

@testset "FqPolyRepFieldElem.special_functions" begin
  R, x = Native.finite_field(ZZRingElem(7), 5, "x")

  a = x^4 + 3x^2 + 6x + 1

  @test tr(a) == 1

  @test norm(a) == 4

  @test frobenius(a) == x^4+2*x^3+3*x^2+5*x+1

  @test frobenius(a, 3) == 3*x^4+3*x^3+3*x^2+x+4

  @test pth_root(a) == 4*x^4+3*x^3+4*x^2+5*x+2

  @test is_square(a^2)

  @test sqrt(a^2)^2 == a^2

  @test is_square_with_sqrt(a^2)[1]

  @test is_square_with_sqrt(a^2)[2]^2 == a^2

  @test !is_square(x*a^2)

  @test_throws ErrorException sqrt(x*a^2)

  @test !is_square_with_sqrt(x*a^2)[1]
end

@testset "FqPolyRepFieldElem.rand" begin
  R, x = Native.finite_field(ZZRingElem(17), 3, "x")

  test_rand(R)
end

@testset "FqPolyRepFieldElem.iteration" begin
  for n = [2, 3, 5, 13, 31]
    R, _ = Native.finite_field(ZZRingElem(n), 1, "x")
    elts = ConformanceTests.test_iterate(R)
    @test elts == R.(0:n-1)
    R, _ = Native.finite_field(ZZRingElem(n), rand(2:9), "x")
    ConformanceTests.test_iterate(R)
  end
end

@testset "FqPolyRepFieldElem.lift" begin
  R, x = Native.finite_field(ZZ(23), 2, "x")
  f = 8x + 9
  S, y = polynomial_ring(Native.GF(ZZ(23)), "y")
  @test lift(S, f) == 8y + 9
end

@testset "FqPolyRepField.overload" begin
  R, x = Native.finite_field(ZZ(19), 3, "x")
  @test R([1, 0, 1]) == x^2 + 1
end

@testset "Nemo.jl#1493" begin
  @test_throws DomainError Native.GF(ZZ(4), 2)
  @test_throws DomainError Native.finite_field(ZZ(6), 2, "x")
end

@testset "FqPolyRepFieldElem.minpoly" begin
  F, a = Native.finite_field(ZZ(7), 5, "a")

  f = minpoly(a)
  @test is_zero(f(a))
  @test degree(f) == degree(F)
  @test is_monic(f)

  f = charpoly(a)
  @test is_zero(f(a))
  @test degree(f) == degree(F)
  @test is_monic(f)

  g = minpoly(F(3))
  @test is_zero(g(F(3)))
  @test degree(g) == 1
  @test is_monic(g)

  g = charpoly(F(3))
  @test is_zero(g(F(3)))
  @test degree(g) == degree(F)
  @test is_monic(g)
end
